// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get home => 'Home';

  @override
  String get map => 'Map';

  @override
  String get settings => 'Settings';

  @override
  String get play => 'Play';

  @override
  String get screenshots => 'Screenshots';

  @override
  String get reinstall => 'Reinstall';

  @override
  String get autoConnect => 'Auto-Connect';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginInBrowser =>
      'Sign in with your Microsoft account and come back to this screen';

  @override
  String get loginOpenBrowser => 'Open again';

  @override
  String get loginCopyLink => 'Copy link';

  @override
  String get loginLinkCopied => 'Link copied';

  @override
  String get loginError => 'Couldn\'t sign in';

  @override
  String get loginErrorDesc =>
      'Something went wrong while signing in with Microsoft';

  @override
  String get loginRetry => 'Try again';

  @override
  String get loginBrowserDone =>
      'You can close this tab and go back to BC Launcher';

  @override
  String get logout => 'Logout';

  @override
  String get switchInstances => 'Switch server';

  @override
  String get mapError => 'Error on loading map';

  @override
  String get gameSettings => 'Game Settings';

  @override
  String get directory => 'Directory';

  @override
  String get directoryDesc => 'Path where your game files are located';

  @override
  String get open => 'Open';

  @override
  String get resolution => 'Resolution';

  @override
  String get resolutionDesc => 'Initial size for the game´s window';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get memoryAllocation => 'Memory Allocation';

  @override
  String get resetSettings => 'Reset settings';

  @override
  String get installing => 'Installing';

  @override
  String get syncing => 'Synchronizing';

  @override
  String get availableUpdate => 'Available update';

  @override
  String get updateQuestion =>
      'Do you want to install the newest app´s version?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get updatedNeeded => 'Updated needed';

  @override
  String get close => 'Close';

  @override
  String get downloading => 'Downloading';

  @override
  String get lastNews => 'Last news';

  @override
  String get userNotAuthorized => 'User not authorized';

  @override
  String get serverNotResponding => 'Server not responding';

  @override
  String get versionErrorDialogTitle => 'Incorrect version';

  @override
  String get versionErrorDialogDescription =>
      'Incorrect version of the instance detected. Do you want to reinstall';

  @override
  String get reinstallDialogTitle => 'Reinstall instance';

  @override
  String get reinstallDialogDescription => 'Do you want to reinstall';
}
