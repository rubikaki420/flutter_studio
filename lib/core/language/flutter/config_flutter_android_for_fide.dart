import 'dart:io';

class ConfigFlutterAndroidForFide {
  static Future<void> startConfigaration({
    required String workspaceDirectory,
    required String androidSdkPath,
    required String flutterSdkPath,
    required String ndkVersion,
    required String buildToolsVersion,
    required String cmakeVersion,
  }) async {
    File localDotProperties = File(
      "$workspaceDirectory/android/local.properties",
    );
    File gradleDotProperties = File(
      "$workspaceDirectory/android/gradle.properties",
    );
    File gradlew = File("$workspaceDirectory/android/gradlew");

    File buildDotGradleKts = File(
      "$workspaceDirectory/android/app/build.gradle.kts",
    );
    File buildDotGradleGroovy = File(
      "$workspaceDirectory/android/app/build.gradle",
    );

    File? activeBuildGradle;
    bool isKotlinDsl = false;

    if (await buildDotGradleKts.exists()) {
      activeBuildGradle = buildDotGradleKts;
      isKotlinDsl = true;
    } else if (await buildDotGradleGroovy.exists()) {
      activeBuildGradle = buildDotGradleGroovy;
      isKotlinDsl = false;
    }
    
    await _backupFile(localDotProperties);
    await _backupFile(gradleDotProperties);
    
    if (activeBuildGradle != null) {
      await _backupFile(activeBuildGradle);
    }
    
    await _backupFile(gradlew);
    
    /*
    * local.properties
    */
    Map<String, String> localProps = {
      'sdk.dir': androidSdkPath,
      'flutter.sdk': flutterSdkPath,
      'ndk.dir': "$androidSdkPath/ndk/$ndkVersion",
      'cmake.dir': "$androidSdkPath/cmake/$cmakeVersion",
    };
    await _updatePropertiesFile(localDotProperties, localProps);

    /*
    * gradle.properties
    */
    Map<String, String> gradleProps = {
      'android.useAndroidX': 'true',
      'android.aapt2FromMavenOverride':
          "$androidSdkPath/build-tools/$buildToolsVersion/aapt2",
    };
    await _updatePropertiesFile(gradleDotProperties, gradleProps);

    /*
    * build.gradle / build.gradle.kts 
    */
    if (activeBuildGradle != null) {
      String content = await activeBuildGradle.readAsString();

      String buildToolsValue = '"$buildToolsVersion"';
      String ndkValue = '"$ndkVersion"';

      content = _updateGradleProperty(
        content: content,
        key: 'buildToolsVersion',
        value: buildToolsValue,
        isKotlinDsl: isKotlinDsl,
      );

      content = _updateGradleProperty(
        content: content,
        key: 'ndkVersion',
        value: ndkValue,
        isKotlinDsl: isKotlinDsl,
      );

      await activeBuildGradle.writeAsString(content);
    }

    /*
    * gradlew 
    */
    await gradlew.writeAsString(_getGradlewScriptContent());
    try {
      Process.runSync('chmod', ['+x', gradlew.path]);
    } catch (e) {
     //ignore: empty_catches
    }
  }

  static Future<void> _updatePropertiesFile(
    File file,
    Map<String, String> updates,
  ) async {
    List<String> lines = [];
    if (await file.exists()) {
      lines = await file.readAsLines();
    }

    updates.forEach((key, value) {
      bool found = false;
      RegExp propRegExp = RegExp(r'^\s*#?\s*' + RegExp.escape(key) + r'\s*=');

      for (int i = 0; i < lines.length; i++) {
        if (propRegExp.hasMatch(lines[i])) {
          lines[i] = "$key=$value";
          found = true;
          break;
        }
      }
      if (!found) {
        lines.add("$key=$value");
      }
    });

    await file.writeAsString('${lines.join("\n")}\n');
  }

  static String _updateGradleProperty({
    required String content,
    required String key,
    required String value,
    required bool isKotlinDsl,
  }) {
    final propertyRegExp = RegExp(
      r'^\s*(?:\/\/\s*)?' +
          RegExp.escape(key) +
          r'\s*(?:=)?\s*.*$',
      multiLine: true,
    );
  
    final correctLine =
        isKotlinDsl ? '    $key = $value' : '    $key $value';
  
    if (propertyRegExp.hasMatch(content)) {
      return content.replaceAll(propertyRegExp, correctLine);
    }
  
    final androidBlockRegExp = RegExp(
      r'^\s*android\s*\{',
      multiLine: true,
    );
  
    if (androidBlockRegExp.hasMatch(content)) {
      return content.replaceFirstMapped(
        androidBlockRegExp,
        (match) => '${match.group(0)}\n    $correctLine',
      );
    }
  
    return content;
  }
  
  static Future<void> _backupFile(File file) async {
    if (!await file.exists()) return;
  
    final backupDir = Directory(
      '${file.parent.path}/.fide_backup',
    );
  
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
  
    final fileName = file.uri.pathSegments.last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
  
    // Create backup
    await file.copy(
      '${backupDir.path}/$fileName.$timestamp.bak',
    );
  
    // Keep only last 2 backups of this file
    final backups = await backupDir
        .list()
        .where((e) => e is File)
        .cast<File>()
        .where((f) => f.path.contains('$fileName.'))
        .toList();
  
    backups.sort(
      (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
    );
  
    if (backups.length > 2) {
      for (final oldBackup in backups.skip(2)) {
        await oldBackup.delete();
      }
    }
  }

  static String _getGradlewScriptContent() {
    return r'''#!/data/data/com.vault.fide/files/usr/bin/env bash
##############################################################################
##
##  Gradle start up script for UN*X
##
##############################################################################

# Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
DEFAULT_JVM_OPTS=""

APP_NAME="Gradle"
APP_BASE_NAME=`basename "$0"`

# Use the maximum available, or set MAX_FD != -1 to use that value.
MAX_FD="maximum"

warn ( ) {
    echo "$*"
}

die ( ) {
    echo
    echo "$*"
    echo
    exit 1
}

# OS specific support (must be 'true' or 'false').
cygwin=false
msys=false
darwin=false
case "`uname`" in
  CYGWIN* )
    cygwin=true
    ;;
  Darwin* )
    darwin=true
    ;;
  MINGW* )
    msys=true
    ;;
esac

# Attempt to set APP_HOME
# Resolve links: $0 may be a link
PRG="$0"
# Need this for relative symlinks.
while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`"/$link"
    fi
done
SAVED="`pwd`"
cd "`dirname \"$PRG\"`/" >/dev/null
APP_HOME="`pwd -P`"
cd "$SAVED" >/dev/null

CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar

# Determine the Java command to use to start the JVM.
if [ -n "$JAVA_HOME" ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
        # IBM's JDK on AIX uses strange locations for the executables
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
else
    JAVACMD="java"
    which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
fi

# Increase the maximum file descriptors if we can.
if [ "$cygwin" = "false" -a "$darwin" = "false" ] ; then
    MAX_FD_LIMIT=`ulimit -H -n`
    if [ $? -eq 0 ] ; then
        if [ "$MAX_FD" = "maximum" -o "$MAX_FD" = "max" ] ; then
            MAX_FD="$MAX_FD_LIMIT"
        fi
        ulimit -n $MAX_FD
        if [ $? -ne 0 ] ; then
            warn "Could not set maximum file descriptor limit: $MAX_FD"
        fi
    else
        warn "Could not query maximum file descriptor limit: $MAX_FD_LIMIT"
    fi
fi

# For Darwin, add options to specify how the application appears in the dock
if $darwin; then
    GRADLE_OPTS="$GRADLE_OPTS \"-Xdock:name=$APP_NAME\" \"-Xdock:icon=$APP_HOME/media/gradle.icns\""
fi

# For Cygwin, switch paths to Windows format before running java
if $cygwin ; then
    APP_HOME=`cygpath --path --mixed "$APP_HOME"`
    CLASSPATH=`cygpath --path --mixed "$CLASSPATH"`
    JAVACMD=`cygpath --unix "$JAVACMD"`

    # We build the pattern for arguments to be converted via cygpath
    ROOTDIRSRAW=`find -L / -maxdepth 1 -mindepth 1 -type d 2>/dev/null`
    SEP=""
    for dir in $ROOTDIRSRAW ; do
        ROOTDIRS="$ROOTDIRS$SEP$dir"
        SEP="|"
    done
    OURCYGPATTERN="(^($ROOTDIRS))"
    # Add a user-defined pattern to the cygpath arguments
    if [ "$GRADLE_CYGPATTERN" != "" ] ; then
        OURCYGPATTERN="$OURCYGPATTERN|($GRADLE_CYGPATTERN)"
    fi
    # Now convert the arguments - kludge to limit ourselves to /bin/sh
    i=0
    for arg in "$@" ; do
        CHECK=`echo "$arg"|egrep -c "$OURCYGPATTERN" -`
        CHECK2=`echo "$arg"|egrep -c "^-"`                               ### Determine if an option

        if [ $CHECK -ne 0 ] && [ $CHECK2 -eq 0 ] ; then                    ### Added a condition
            eval `echo args$i`=`cygpath --path --ignore --mixed "$arg"`
        else
            eval `echo args$i`="\"$arg\""
        fi
        i=$((i+1))
    done
    case $i in
        (0) set -- ;;
        (1) set -- "$args0" ;;
        (2) set -- "$args0" "$args1" ;;
        (3) set -- "$args0" "$args1" "$args2" ;;
        (4) set -- "$args0" "$args1" "$args2" "$args3" ;;
        (5) set -- "$args0" "$args1" "$args2" "$args3" "$args4" ;;
        (6) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" ;;
        (7) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" ;;
        (8) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" "$args7" ;;
        (9) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" "$args7" "$args8" ;;
    esac
fi

# Split up the JVM_OPTS And GRADLE_OPTS values into an array, following the shell quoting and substitution rules
function splitJvmOpts() {
    JVM_OPTS=("$@")
}
eval splitJvmOpts $DEFAULT_JVM_OPTS $JAVA_OPTS $GRADLE_OPTS
JVM_OPTS[${#JVM_OPTS[*]}]="-Dorg.gradle.appname=$APP_BASE_NAME"

exec "$JAVACMD" "${JVM_OPTS[@]}" -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
''';
  }
}
