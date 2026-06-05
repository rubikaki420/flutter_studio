// package com.vault.fide.app.fragments;

// import android.content.ComponentName;
// import android.content.Context;
// import android.content.Intent;
// import android.content.ServiceConnection;
// import android.graphics.Typeface;
// import android.os.Bundle;
// import android.os.IBinder;
// import android.view.LayoutInflater;
// import android.view.View;
// import android.view.ViewGroup;

// import androidx.annotation.NonNull;
// import androidx.annotation.Nullable;
// import androidx.fragment.app.Fragment;

// import com.vault.fide.app.TermuxService;
// import com.vault.fide.terminal.TerminalSession;
// import com.vault.fide.view.TerminalView;

// public class TerminalFragment extends Fragment {

    // private TerminalView terminalView;
    // private TermuxService termuxService;
    // private TerminalSession session;

    // private boolean isBound = false;

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

    // @Nullable
    // @Override
    // public View onCreateView(@NonNull LayoutInflater inflater,
            // @Nullable ViewGroup container,
            // @Nullable Bundle savedInstanceState) {

        // View root = inflater.inflate(R.layout.fragment_terminal, container, false);

        // terminalView = root.findViewById(R.id.terminal_view);

        // if (terminalView != null) {
            // terminalView.setTypeface(Typeface.MONOSPACE);
            // terminalView.setTextSize(14f);
            // terminalView.setFocusable(true);
            // terminalView.setFocusableInTouchMode(true);
        // }

        // return root;
    // }

    // @Override
    // public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        // super.onViewCreated(view, savedInstanceState);

        // Intent intent = new Intent(requireContext(), TermuxService.class);
        // requireContext().bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
    // }

    // private void createSession() {
        // if (termuxService == null) return;

        // String shell = "/system/bin/sh";

        // TerminalSession termuxSession = termuxService.createTermuxSession(
                // shell,
                // new String[]{},
                // null,
                // requireContext().getFilesDir().getAbsolutePath(),
                // false,
                // "Terminal"
        // );

        // if (termuxSession != null) {
            // session = termuxSession;
            // terminalView.attachSession(session);
        // }
    // }

    // @Override
    // public void onDestroyView() {
        // super.onDestroyView();

        // try {
            // if (isBound) {
                // requireContext().unbindService(serviceConnection);
                // isBound = false;
            // }
        // } catch (Exception ignored) {
        // }

        // terminalView = null;
        // session = null;
        // termuxService = null;
    // }
// }