package com.vault.fide;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender;
import android.content.pm.PackageInstaller;
import android.content.pm.PackageInstaller.Session;
import android.net.Uri;
import android.text.TextUtils;
import android.util.Log;

import androidx.core.content.FileProvider;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Method;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
/**
 * ApkInstaller utility for install apk directly from IDE.
 *
 * Source:
 * [ApkInstaller.kt](https://github.com/AndroidCSOfficial/android-code-studio/blob/dev/core/common/src/main/java/com/tom/rv2ide/utils/ApkInstaller.kt)
 */
public final class ApkInstaller {

    private static final String TAG = "ApkInstaller";
    private static final boolean DEBUG_FALLBACK_INSTALLER = false;

    private ApkInstaller() {}

    public static void installApk(
            Context context,
            IntentSender sender,
            File apk,
            PackageInstaller.SessionCallback callback) {

        if (apk == null || !apk.exists() || !apk.isFile()
                || !apk.getName().toLowerCase().endsWith(".apk")) {
            Log.e(TAG, "Invalid APK: " + apk);
            return;
        }

        Log.i(TAG, "Installing APK: " + apk.getAbsolutePath());

        if (isMiui() || DEBUG_FALLBACK_INSTALLER) {
            Log.w(TAG, "Using Intent-based installer fallback");
            try {
                Intent intent = new Intent(Intent.ACTION_INSTALL_PACKAGE);
                String authority = context.getPackageName() + ".providers.fileprovider";
                Uri uri = FileProvider.getUriForFile(context, authority, apk);
                intent.setDataAndType(uri, "application/vnd.android.package-archive");
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION
                        | Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(intent);
            } catch (Exception e) {
                Log.e(TAG, "Failed to start installation intent", e);
            }
            return;
        }

        ExecutorService executor = Executors.newSingleThreadExecutor();
        executor.execute(() -> {
            Session session = null;
            try {
                PackageInstaller installer =
                        context.getPackageManager().getPackageInstaller();

                if (callback != null) {
                    installer.registerSessionCallback(callback);
                }

                PackageInstaller.SessionParams params = new PackageInstaller.SessionParams(
                        PackageInstaller.SessionParams.MODE_FULL_INSTALL);

                int sessionId = installer.createSession(params);
                session = installer.openSession(sessionId);
                addToSession(session, apk);
                session.commit(sender);
                Log.i(TAG, "Package install session started");

            } catch (Exception e) {
                if (session != null) {
                    try { session.abandon(); } catch (Exception ignored) {}
                }
                Log.e(TAG, "Package installation failed", e);
            } finally {
                if (session != null) {
                    try { session.close(); } catch (Exception ignored) {}
                }
            }
        });
        executor.shutdown();
    }

    private static void addToSession(Session session, File apk) throws IOException {
        long length = apk.length();
        if (length == 0L) {
            throw new RuntimeException("File is empty (has length 0)");
        }
        try (OutputStream out = session.openWrite(apk.getName(), 0, length);
             InputStream in = new FileInputStream(apk)) {
            byte[] buf = new byte[8 * 1024];
            int n;
            while ((n = in.read(buf)) >= 0) {
                out.write(buf, 0, n);
            }
            session.fsync(out);
        }
    }

    public static boolean isMiui() {
        return !TextUtils.isEmpty(getSystemProperty("ro.miui.ui.version.name"));
    }

    @SuppressLint("PrivateApi")
    public static String getSystemProperty(String key) {
        try {
            Class<?> clazz = Class.forName("android.os.SystemProperties");
            Method method = clazz.getDeclaredMethod("get", String.class);
            return (String) method.invoke(null, key);
        } catch (Exception e) {
            Log.w(TAG, "Unable to use SystemProperties.get", e);
            return null;
        }
    }
}