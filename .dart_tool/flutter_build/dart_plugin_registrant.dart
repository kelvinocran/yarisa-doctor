//
// Generated file. Do not edit.
// This file is generated from template in file `flutter_tools/lib/src/flutter_plugins.dart`.
//

// @dart = 3.5

import 'dart:io'; // flutter_ignore: dart_io_import.
import 'package:file_picker/file_picker.dart';
import 'package:google_sign_in_android/google_sign_in_android.dart';
import 'package:path_provider_android/path_provider_android.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher_android/url_launcher_android.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_sign_in_ios/google_sign_in_ios.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher_ios/url_launcher_ios.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider_linux/path_provider_linux.dart';
import 'package:url_launcher_linux/url_launcher_linux.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_sign_in_ios/google_sign_in_ios.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher_macos/url_launcher_macos.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:url_launcher_windows/url_launcher_windows.dart';

@pragma('vm:entry-point')
class _PluginRegistrant {

  @pragma('vm:entry-point')
  static void register() {
    if (Platform.isAndroid) {
      try {
        FilePickerIO.registerWith();
      } catch (err) {
        print(
          '`file_picker` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        GoogleSignInAndroid.registerWith();
      } catch (err) {
        print(
          '`google_sign_in_android` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        PathProviderAndroid.registerWith();
      } catch (err) {
        print(
          '`path_provider_android` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        SqflitePlugin.registerWith();
      } catch (err) {
        print(
          '`sqflite` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        UrlLauncherAndroid.registerWith();
      } catch (err) {
        print(
          '`url_launcher_android` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isIOS) {
      try {
        FilePickerIO.registerWith();
      } catch (err) {
        print(
          '`file_picker` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        GoogleSignInIOS.registerWith();
      } catch (err) {
        print(
          '`google_sign_in_ios` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        PathProviderFoundation.registerWith();
      } catch (err) {
        print(
          '`path_provider_foundation` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        SqflitePlugin.registerWith();
      } catch (err) {
        print(
          '`sqflite` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        UrlLauncherIOS.registerWith();
      } catch (err) {
        print(
          '`url_launcher_ios` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isLinux) {
      try {
        FilePickerLinux.registerWith();
      } catch (err) {
        print(
          '`file_picker` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        PathProviderLinux.registerWith();
      } catch (err) {
        print(
          '`path_provider_linux` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        UrlLauncherLinux.registerWith();
      } catch (err) {
        print(
          '`url_launcher_linux` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isMacOS) {
      try {
        FilePickerMacOS.registerWith();
      } catch (err) {
        print(
          '`file_picker` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        GoogleSignInIOS.registerWith();
      } catch (err) {
        print(
          '`google_sign_in_ios` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        PathProviderFoundation.registerWith();
      } catch (err) {
        print(
          '`path_provider_foundation` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        SqflitePlugin.registerWith();
      } catch (err) {
        print(
          '`sqflite` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        UrlLauncherMacOS.registerWith();
      } catch (err) {
        print(
          '`url_launcher_macos` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isWindows) {
      try {
        FilePickerWindows.registerWith();
      } catch (err) {
        print(
          '`file_picker` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        PathProviderWindows.registerWith();
      } catch (err) {
        print(
          '`path_provider_windows` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        UrlLauncherWindows.registerWith();
      } catch (err) {
        print(
          '`url_launcher_windows` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    }
  }
}
