package com.vault.fide;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInstaller;
import android.util.Log;
public class InstallationResultReceiver extends BroadcastReceiver {

    private static final String TAG = "InstallationResultReceiver";
    public static String pendingApkPath = null;

    @Override
    public void onReceive(Context context, Intent intent) {
        int status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, -1);
        
        if (status == PackageInstaller.STATUS_PENDING_USER_ACTION) {
            InstallationResultHandler.onResult(context, intent);
            return;
        }
        
        String packageName = InstallationResultHandler.onResult(context, intent);

        if (status == PackageInstaller.STATUS_SUCCESS 
                && packageName == null 
                && pendingApkPath != null) {
            android.content.pm.PackageInfo info = context.getPackageManager()
                    .getPackageArchiveInfo(pendingApkPath, 0);
            if (info != null) {
                packageName = info.packageName;
                Intent launchIntent = context.getPackageManager()
                        .getLaunchIntentForPackage(packageName);
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    context.startActivity(launchIntent);
                }
            }
        }
        
        // Success বা failure যাই হোক, path clear করো
        if (status != PackageInstaller.STATUS_PENDING_USER_ACTION) {
            pendingApkPath = null;
        }
    }
}