package com.vault.fide;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.graphics.Typeface;
import android.os.IBinder;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewTreeObserver;
import android.view.inputmethod.InputMethodManager;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.vault.fide.app.TermuxService;
import com.vault.fide.shared.termux.shell.command.runner.terminal.TermuxSession;
import com.vault.fide.terminal.TerminalBuffer;
import com.vault.fide.terminal.TerminalSession;
import com.vault.fide.terminal.TerminalSessionClient;
import com.vault.fide.view.TerminalView;
import com.vault.fide.view.TerminalViewClient;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class TerminalPlatformView implements PlatformView, MethodChannel.MethodCallHandler {

    private final FrameLayout containerView;
    private final Context context;

    private TerminalView terminalView;
    private TermuxService termuxService;
    private TermuxSession session;

    private boolean isBound = false;
    private boolean isViewReady = false;
    private boolean isServiceReady = false;
    
    private volatile boolean disposed = false;

    private MethodChannel methodChannel;

    // Pattern monitoring
    private final List<String> watchPatterns = new ArrayList<>();
    private final Set<String> alreadyNotified = new HashSet<>();

    // Performance improvements
    private final ExecutorService patternMatcherExecutor = Executors.newSingleThreadExecutor();
    private final LimitedSizeQueue<String> recentLines = new LimitedSizeQueue<>(500);
    private int lastCheckedLineCount = 0;
    private String lastTranscriptSnapshot = "";

    public TerminalPlatformView(
            @NonNull Context context,
            int id,
            @Nullable Object args,
            BinaryMessenger messenger
    ) {
        this.context = context;
        containerView = new FrameLayout(context);

        methodChannel = new MethodChannel(
                messenger,
                "com.vault.fide/terminal_control_" + id
        );
        methodChannel.setMethodCallHandler(this);

        terminalView = new TerminalView(context, null);
        terminalView.setTerminalViewClient(terminalViewClient);
        terminalView.setTextSize(30);
        terminalView.setTypeface(Typeface.MONOSPACE);
        terminalView.setFocusable(true);
        terminalView.setFocusableInTouchMode(true);

        containerView.addView(
                terminalView,
                new FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT
                )
        );

        terminalView.getViewTreeObserver().addOnGlobalLayoutListener(
                new ViewTreeObserver.OnGlobalLayoutListener() {
                    @Override
                    public void onGlobalLayout() {
                        if (terminalView.getWidth() > 0 && terminalView.getHeight() > 0) {
                            terminalView.getViewTreeObserver()
                                    .removeOnGlobalLayoutListener(this);
                            isViewReady = true;
                            maybeCreateSession();
                        }
                    }
                }
        );

        Intent intent = new Intent(context, TermuxService.class);
        context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
    }

    private void maybeCreateSession() {
        if (isViewReady && isServiceReady) {
            createSession();
        }
    }

    private final TerminalViewClient terminalViewClient = new TerminalViewClient() {

        @Override
        public float onScale(float scale) {
            return Math.max(0.5f, Math.min(scale, 2.0f));
        }

        @Override
        public void onSingleTapUp(MotionEvent e) {
            if (session != null && session.getTerminalSession() != null) {
                InputMethodManager imm =
                        (InputMethodManager) context.getSystemService(Context.INPUT_METHOD_SERVICE);
                if (imm != null) {
                    imm.showSoftInput(terminalView, InputMethodManager.SHOW_IMPLICIT);
                }
            }
        }

        @Override
        public boolean shouldBackButtonBeMappedToEscape() {
            return false;
        }

        @Override
        public boolean shouldEnforceCharBasedInput() {
            return true;
        }

        @Override
        public boolean shouldUseCtrlSpaceWorkaround() {
            return false;
        }

        @Override
        public boolean isTerminalViewSelected() {
            return true;
        }

        @Override
        public void copyModeChanged(boolean copyMode) {}

        @Override
        public boolean onKeyDown(int keyCode, KeyEvent e, TerminalSession session) {
            return false;
        }

        @Override
        public boolean onKeyUp(int keyCode, KeyEvent e) {
            return false;
        }

        @Override
        public boolean onLongPress(MotionEvent event) {
            return true;
        }

        @Override
        public boolean readControlKey() {
            return false;
        }

        @Override
        public boolean readAltKey() {
            return false;
        }

        @Override
        public boolean readShiftKey() {
            return false;
        }

        @Override
        public boolean readFnKey() {
            return false;
        }

        @Override
        public boolean onCodePoint(int codePoint, boolean ctrlDown, TerminalSession session) {
            return false;
        }

        @Override
        public void onEmulatorSet() {
            if (terminalView != null) {
                terminalView.setTerminalCursorBlinkerRate(1000);
                terminalView.setTerminalCursorBlinkerState(true, true);
            }
        }

        @Override
        public void logError(String tag, String message) {}

        @Override
        public void logWarn(String tag, String message) {}

        @Override
        public void logInfo(String tag, String message) {}

        @Override
        public void logDebug(String tag, String message) {}

        @Override
        public void logVerbose(String tag, String message) {}

        @Override
        public void logStackTraceWithMessage(String tag, String message, Exception e) {
            e.printStackTrace();
        }

        @Override
        public void logStackTrace(String tag, Exception e) {
            if (e != null) e.printStackTrace();
        }
    };

    private final ServiceConnection serviceConnection = new ServiceConnection() {

        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            TermuxService.LocalBinder binder = (TermuxService.LocalBinder) service;
            termuxService = binder.service;
            isBound = true;
            isServiceReady = true;
            maybeCreateSession();
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            termuxService = null;
            isBound = false;
            isServiceReady = false;
        }
    };

    private void createSession() {
        if (termuxService == null || terminalView == null) return;

        File loginShell = new File("/data/data/com.vault.fide/files/usr/bin/login");
        File bashShell = new File("/data/data/com.vault.fide/files/usr/bin/bash");

        String shell;
        String[] shellArgs;

        if (loginShell.exists()) {
            shell = loginShell.getAbsolutePath();
            shellArgs = new String[]{"-l"};
        } else if (bashShell.exists()) {
            shell = bashShell.getAbsolutePath();
            shellArgs = new String[]{};
        } else {
            shell = "/system/bin/sh";
            shellArgs = new String[]{};
        }

        TermuxSession termuxSession = termuxService.createTermuxSession(
                shell,
                shellArgs,
                null,
                "/data/data/com.vault.fide/files/home",
                false,
                "Terminal"
        );

        if (termuxSession != null) {
            session = termuxSession;
            TerminalSession rawSession = session.getTerminalSession();
            if (rawSession != null) {
                attachSessionSafely(rawSession);
                setupTerminalOutputListener(rawSession);
            }
        }
    }

    private void attachSessionSafely(TerminalSession rawSession) {
        if (terminalView == null) return;

        if (terminalView.getWidth() > 0 && terminalView.getHeight() > 0) {
            try {
                terminalView.attachSession(rawSession);
                terminalView.requestFocus();
            } catch (Exception e) {
                e.printStackTrace();
            }
        } else {
            terminalView.postDelayed(() -> {
                if (terminalView != null) {
                    try {
                        terminalView.attachSession(rawSession);
                        terminalView.requestFocus();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }, 5000);
        }
    }

    private void setupTerminalOutputListener(TerminalSession rawSession) {
        rawSession.updateTerminalSessionClient(new TerminalSessionClient() {

            @Override
            public void onTextChanged(@NonNull TerminalSession changedSession) {
            if (disposed) return;
                if (changedSession.getEmulator() == null
                        || changedSession.getEmulator().getScreen() == null) return;

                TerminalBuffer buffer = changedSession.getEmulator().getScreen();

                // Get current full transcript (but we will extract only new parts)
                String currentTranscript = buffer.getTranscriptTextWithFullLinesJoined();
                if (currentTranscript == null) return;

                // --- Incremental scanning: only process what's new ---
                String newText;
                if (currentTranscript.length() > lastTranscriptSnapshot.length()) {
                    newText = currentTranscript.substring(lastTranscriptSnapshot.length());
                } else {
                    newText = currentTranscript;
                }
                lastTranscriptSnapshot = currentTranscript;

                if (newText.isEmpty()) return;

                // Optional: also keep rolling lines for future use (not strictly needed now)
                String[] newLines = newText.split("\n");
                for (String line : newLines) {
                    recentLines.add(line);
                }
                
                if (patternMatcherExecutor.isShutdown()
            || patternMatcherExecutor.isTerminated()) {
        return;
    }

                // --- Offload pattern matching to background thread ---
                patternMatcherExecutor.submit(() -> {
                    synchronized (watchPatterns) {
                        for (String pattern : watchPatterns) {
                            // Search only in the newly added text
                            if (newText.contains(pattern) && !alreadyNotified.contains(pattern)) {
                                alreadyNotified.add(pattern);
                                // Post back to main thread to invoke Flutter method
                                containerView.post(() -> notifyFlutterTextDetected(pattern));
                            }
                        }
                    }
                });
            }

            @Override
            public void onTitleChanged(@NonNull TerminalSession changedSession) {}

            @Override
            public void onSessionFinished(@NonNull TerminalSession finishedSession) {
                notifyFlutterSessionFinished();
            }

            @Override
            public void onCopyTextToClipboard(@NonNull TerminalSession session, String text) {}

            @Override
            public void onPasteTextFromClipboard(@Nullable TerminalSession session) {}

            @Override
            public void onBell(@NonNull TerminalSession session) {}

            @Override
            public void onColorsChanged(@NonNull TerminalSession session) {}

            @Override
            public void onTerminalCursorStateChange(boolean state) {}

            @Override
            public void setTerminalShellPid(@NonNull TerminalSession session, int pid) {}

            @Override
            public Integer getTerminalCursorStyle() {
                return 0;
            }

            @Override
            public void logError(String tag, String message) {}

            @Override
            public void logWarn(String tag, String message) {}

            @Override
            public void logInfo(String tag, String message) {}

            @Override
            public void logDebug(String tag, String message) {}

            @Override
            public void logVerbose(String tag, String message) {}

            @Override
            public void logStackTraceWithMessage(String tag, String message, Exception e) {}

            @Override
            public void logStackTrace(String tag, Exception e) {}
        });
    }

    private void notifyFlutterTextDetected(String detectedPattern) {
        if (methodChannel == null || containerView == null) return;

        containerView.post(() -> {
            if (methodChannel != null) {
                java.util.HashMap<String, Object> map = new java.util.HashMap<>();
                map.put("matchedText", detectedPattern);
                methodChannel.invokeMethod("onTerminalTextMatched", map);
            }
        });
    }

    private void notifyFlutterSessionFinished() {
        if (methodChannel == null || containerView == null) return;

        containerView.post(() -> {
            if (methodChannel != null) {
                methodChannel.invokeMethod("onSessionFinished", null);
            }
        });
    }

    @Override
    public void onMethodCall(
            @NonNull MethodCall call,
            @NonNull MethodChannel.Result result
    ) {
        switch (call.method) {

            case "sendCommand": {
                String command = call.argument("command");
                if (command != null
                        && session != null
                        && session.getTerminalSession() != null) {
                    TerminalSession rawSession = session.getTerminalSession();
                    byte[] data = (command + "\n").getBytes(StandardCharsets.UTF_8);
                    rawSession.write(data, 0, data.length);
                    result.success(true);
                } else {
                    result.error("UNAVAILABLE", "Terminal session is not ready", null);
                }
                break;
            }

            case "watchPattern": {
                String pattern = call.argument("pattern");
                if (pattern != null && !pattern.isEmpty()) {
                    synchronized (watchPatterns) {
                        if (!watchPatterns.contains(pattern)) {
                            watchPatterns.add(pattern);
                        }
                        alreadyNotified.remove(pattern);
                    }
                    result.success(true);
                } else {
                    result.error("INVALID", "Pattern cannot be null or empty", null);
                }
                break;
            }

            case "removePattern": {
                String pattern = call.argument("pattern");
                if (pattern != null) {
                    synchronized (watchPatterns) {
                        watchPatterns.remove(pattern);
                        alreadyNotified.remove(pattern);
                    }
                }
                result.success(true);
                break;
            }

            case "clearPatterns": {
                synchronized (watchPatterns) {
                    watchPatterns.clear();
                    alreadyNotified.clear();
                }
                result.success(true);
                break;
            }

            case "resetPattern": {
                String pattern = call.argument("pattern");
                if (pattern != null) {
                    synchronized (watchPatterns) {
                        alreadyNotified.remove(pattern);
                    }
                }
                result.success(true);
                break;
            }

            default:
                result.notImplemented();
        }
    }

    @Nullable
    @Override
    public View getView() {
        return containerView;
    }

    @Override
    public void dispose() {
        // Shut down background matcher thread
        disposed = true;
        patternMatcherExecutor.shutdownNow();

        if (methodChannel != null) {
            methodChannel.setMethodCallHandler(null);
            methodChannel = null;
        }

        synchronized (watchPatterns) {
            watchPatterns.clear();
            alreadyNotified.clear();
        }

        try {
            if (isBound) {
                context.unbindService(serviceConnection);
                isBound = false;
            }
        } catch (Exception ignored) {}

        terminalView = null;
        session = null;
        termuxService = null;
        isViewReady = false;
        isServiceReady = false;
        
    }

    /**
     * Simple fixed-size queue to keep only the most recent lines.
     * Prevents unbounded memory growth when scanning history.
     */
    private static class LimitedSizeQueue<E> extends ArrayList<E> {
        private final int maxSize;

        public LimitedSizeQueue(int maxSize) {
            this.maxSize = maxSize;
        }

        public boolean add(E e) {
            super.add(e);
            if (size() > maxSize) {
                removeRange(0, size() - maxSize);
            }
            return true;
        }
    }
}