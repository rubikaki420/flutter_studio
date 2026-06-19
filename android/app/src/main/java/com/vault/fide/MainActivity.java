package com.vault.fide;

import android.content.Intent;
import android.os.Bundle;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import com.vault.fide.app.LanguageInstaller;
import com.vault.fide.app.TermuxActivity;
import java.io.File;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.vault.fide/channel";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        flutterEngine
                .getPlatformViewsController()
                .getRegistry()
                .registerViewFactory(
                        "com.vault.fide/terminal_view",
                        new TerminalViewFactory(flutterEngine.getDartExecutor().getBinaryMessenger())
                );
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("openTermuxActivity")) {

                        Intent intent = new Intent(MainActivity.this, TermuxActivity.class);
                        startActivity(intent);

                        result.success("opened");
                    } else if (call.method.equals("openLanguageInstaller")) {

                        String command = call.argument("command");

                        Intent intent = new Intent(MainActivity.this, LanguageInstaller.class);

                        intent.setAction(LanguageInstaller.ACTION_EXECUTE);

                        intent.putExtra(LanguageInstaller.EXTRA_COMMAND, command);

                        startActivity(intent);

                        result.success("opened");
                    } else if ("installApk".equals(call.method)) {
                        String path = call.argument("path");
                        if (path == null) {
                            result.error("INVALID", "Path missing", null);
                            return;
                        }

                        InstallationResultReceiver.pendingApkPath = path;

                        File apkFile = new File(path);
                        ApkInstaller.installApk(
                                this,
                                InstallationResultHandler.createEditorActivitySender(this),
                                apkFile,
                                null
                        );
                        result.success(true);
                    } else {
                        result.notImplemented();
                    }
                });
    }
}
