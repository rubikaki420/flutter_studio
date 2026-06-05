package com.vault.fide.app;
import android.content.ComponentName;
import android.content.Intent;
import android.os.IBinder;
import com.vault.fide.terminal.TerminalSession;

public final class LanguageInstaller extends TermuxActivity {

  public static final String ACTION_EXECUTE = "com.vault.fide.ACTION_EXECUTE_COMMAND";
    public static final String EXTRA_COMMAND = "extra_command";
    private boolean intentHandled = false;
    @Override
    public void onServiceConnected(ComponentName componentName, IBinder service) {
        Intent intent = getIntent();
        super.onServiceConnected(componentName, service);
        handleIntent(intent);
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        intentHandled = false;
        handleIntent(intent);
        
    }

    private void handleIntent(Intent intent) {
        if (intentHandled) return;
        if (intent != null && ACTION_EXECUTE.equals(intent.getAction())) {
            String command = intent.getStringExtra(EXTRA_COMMAND);
            if (command != null && !command.isEmpty()) {
                intentHandled = true;
                executeInTerminal(command);
            }
        }
    }

    private void executeInTerminal(String command) {
        if (mTermuxService != null) {
            TerminalSession currentSession = getCurrentSession();
            
            if (currentSession != null) {
                currentSession.write(command + "\n");
            } else {
                mTermuxTerminalSessionActivityClient.addNewSession(false, null);
                
                mTerminalView.postDelayed(() -> {
                    TerminalSession newSession = getCurrentSession();
                    if (newSession != null) {
                        newSession.write(command + "\n");
                        
                    }
                }, 1000);
            }
        }
    }
}
