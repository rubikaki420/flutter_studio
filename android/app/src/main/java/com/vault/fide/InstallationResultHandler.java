package com.vault.fide;

import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender;
import android.content.pm.PackageInstaller;
import android.util.Log;
/**
 * InstallationResultHandler utility for handling installation results.
 *
 * Source:
 * [InstallationResultHandler.kt](https://github.com/AndroidCSOfficial/android-code-studio/blob/dev/core/app/src/main/java/com/tom/rv2ide/utils/InstallationResultHandler.kt)
 */
public final class InstallationResultHandler {

    private static final String TAG = "InstallationResultHandler";
    private static final int INSTALL_PACKAGE_REQ_CODE = 2304;
    private static final String INSTALL_PACKAGE_ACTION =
            "com.vault.fide.installer.INSTALL_PACKAGE";

    private InstallationResultHandler() {}

    public static IntentSender createEditorActivitySender(Context context) {
        Intent intent = new Intent(context, InstallationResultReceiver.class);
        intent.setAction(INSTALL_PACKAGE_ACTION);
        return PendingIntent.getBroadcast(
                context,
                INSTALL_PACKAGE_REQ_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_MUTABLE
        ).getIntentSender();
    }

    public static String onResult(Context context, Intent intent) {
        if (context == null || intent == null
                || !INSTALL_PACKAGE_ACTION.equals(intent.getAction())) {
            Log.w(TAG, "Invalid broadcast received. action=" +
                    (intent != null ? intent.getAction() : "null"));
            return null;
        }

        if (intent.getExtras() == null) {
            Log.w(TAG, "Invalid intent received in broadcast");
            return null;
        }

        String packageName = intent.getStringExtra(PackageInstaller.EXTRA_PACKAGE_NAME);
        int status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, -1);
        String message = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE);

        switch (status) {
            case PackageInstaller.STATUS_PENDING_USER_ACTION: {
                Object extra = intent.getExtras().get(Intent.EXTRA_INTENT);
                if (extra instanceof Intent) {
                    Intent confirmIntent = (Intent) extra;
                    if ((confirmIntent.getFlags() & Intent.FLAG_ACTIVITY_NEW_TASK)
                            != Intent.FLAG_ACTIVITY_NEW_TASK) {
                        confirmIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    }
                    context.startActivity(confirmIntent);
                }
                return null;
            }

            case PackageInstaller.STATUS_SUCCESS:
            Log.i(TAG, "Package installed successfully!");
            if (packageName != null) {
                Intent launchIntent = context.getPackageManager()
                        .getLaunchIntentForPackage(packageName);
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    context.startActivity(launchIntent);
                } else {
                    Log.w(TAG, "No launch intent found for: " + packageName);
                }
            }
            return packageName;

            case PackageInstaller.STATUS_FAILURE:
            case PackageInstaller.STATUS_FAILURE_ABORTED:
            case PackageInstaller.STATUS_FAILURE_BLOCKED:
            case PackageInstaller.STATUS_FAILURE_CONFLICT:
            case PackageInstaller.STATUS_FAILURE_INCOMPATIBLE:
            case PackageInstaller.STATUS_FAILURE_INVALID:
            case PackageInstaller.STATUS_FAILURE_STORAGE:
                Log.e(TAG, "Package installation failed. status=" + status
                        + " message=" + message);
                return null;

            default:
                Log.w(TAG, "Invalid status code received: " + status);
                return null;
        }
    }
}