package com.vault.fide.shared.termux.shell.command.environment;

import android.content.Context;
import android.content.pm.PackageInfo;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.vault.fide.shared.android.PackageUtils;
import com.vault.fide.shared.shell.command.environment.ShellEnvironmentUtils;
import com.vault.fide.shared.termux.TermuxConstants;
import com.vault.fide.shared.termux.TermuxUtils;

import java.util.HashMap;

/**
 * Environment for {@link TermuxConstants#TERMUX_API_PACKAGE_NAME} app.
 */
public class TermuxAPIShellEnvironment {

    /** Environment variable prefix for the Vault.Fide:API app. */
    public static final String TERMUX_API_APP_ENV_PREFIX = TermuxConstants.TERMUX_ENV_PREFIX_ROOT + "_API_APP__";

    /** Environment variable for the Vault.Fide:API app version. */
    public static final String ENV_TERMUX_API_APP__VERSION_NAME = TERMUX_API_APP_ENV_PREFIX + "VERSION_NAME";

    /** Get shell environment for Vault.Fide:API app. */
    @Nullable
    public static HashMap<String, String> getEnvironment(@NonNull Context currentPackageContext) {
        if (TermuxUtils.isTermuxAPIAppInstalled(currentPackageContext) != null) return null;

        String packageName = TermuxConstants.TERMUX_API_PACKAGE_NAME;
        PackageInfo packageInfo = PackageUtils.getPackageInfoForPackage(currentPackageContext, packageName);
        if (packageInfo == null) return null;

        HashMap<String, String> environment = new HashMap<>();

        ShellEnvironmentUtils.putToEnvIfSet(environment, ENV_TERMUX_API_APP__VERSION_NAME, PackageUtils.getVersionNameForPackage(packageInfo));

        return environment;
    }

}
