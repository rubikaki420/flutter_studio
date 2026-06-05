// package com.vault.fide.app.fragments;

// import android.content.ComponentName;
// import android.content.Context;
// import android.content.Intent;
// import android.content.ServiceConnection;
// import android.graphics.Typeface;
// import android.os.IBinder;
// import android.view.View;
// import android.widget.FrameLayout;

// import androidx.annotation.NonNull;
// import androidx.annotation.Nullable;

// import com.vault.fide.app.TermuxService;
// import com.vault.fide.terminal.TerminalSession;
// import com.vault.fide.view.TerminalView;

// import io.flutter.plugin.common.BinaryMessenger;
// import io.flutter.plugin.common.MethodCall;
// import io.flutter.plugin.common.MethodChannel;
// import io.flutter.plugin.platform.PlatformView;

// public class TerminalPlatformView implements PlatformView, MethodChannel.MethodCallHandler {
    // private final FrameLayout containerView;
    // private final Context context;
    // private TerminalView terminalView;
    // private TermuxService termuxService;
    // private TerminalSession session;
    // private boolean isBound = false;
    // private MethodChannel methodChannel;

    // private final ServiceConnection serviceConnection = new ServiceConnection() {
        // @Override
        // public void onServiceConnected(ComponentName name, IBinder service) {
            // TermuxService.LocalBinder binder = (TermuxService.LocalBinder) service;
            // termuxService = binder.getService();
            // isBound = true;
            // createSession();
        // }

        // @Override
        // public void onServiceDisconnected(ComponentName name) {
            // termuxService = null;
            // isBound = false;
        // }
    // };

    // public TerminalPlatformView(@NonNull Context context, int id, @Nullable Object args, BinaryMessenger messenger) {
        // this.context = context;
        // this.containerView = new FrameLayout(context);
        
        // // Flutter এর সাথে যোগাযোগের জন্য MethodChannel তৈরি
        // this.methodChannel = new MethodChannel(messenger, "com.vault.fide/terminal_control_" + id);
        // this.methodChannel.setMethodCallHandler(this);

        // // Native TerminalView তৈরি ও কনফিগারেশন
        // terminalView = new TerminalView(context, null);
        // terminalView.setTypeface(Typeface.MONOSPACE);
        // terminalView.setTextSize(14f);
        // terminalView.setFocusable(true);
        // terminalView.setFocusableInTouchMode(true);

        // containerView.addView(terminalView);

        // // Termux Service Bind করা
        // Intent intent = new Intent(context, TermuxService.class);
        // context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
    // }

    // private void createSession() {
        // if (termuxService == null || terminalView == null) return;

        // String shell = "/system/bin/sh";
        // TerminalSession termuxSession = termuxService.createTermuxSession(
                // shell,
                // new String[]{},
                // null,
                // context.getFilesDir().getAbsolutePath(),
                // false,
                // "Terminal"
        // );

        // if (termuxSession != null) {
            // session = termuxSession;
            // terminalView.attachSession(session);
        // }
    // }

    // @Override
    // public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        // if (call.method.equals("sendCommand")) {
            // String command = call.argument("command");
            // if (command != null && session != null) {
                // // সেশনে কমান্ড লিখে এন্টার (\n) দেওয়া হচ্ছে
                // session.write(command + "\n");
                // result.success(true);
            // } else {
                // result.error("UNAVAILABLE", "Terminal session is not ready", null);
            // }
        // } else {
            // result.notImplemented();
        // }
    // }

    // @Nullable
    // @Override
    // public View getView() {
        // return containerView;
    // }

    // @Override
    // public void dispose() {
        // if (methodChannel != null) {
            // methodChannel.setMethodCallHandler(null);
            // methodChannel = null;
        // }
        // try {
            // if (isBound) {
                // context.unbindService(serviceConnection);
                // isBound = false;
            // }
        // } catch (Exception ignored) {}
        
        // terminalView = null;
        // session = null;
        // termuxService = null;
    // }
// }