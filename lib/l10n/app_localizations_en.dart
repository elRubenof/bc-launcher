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
  String get settings => 'Settings';

  @override
  String get play => 'Play';

  @override
  String get screenshots => 'Screenshots';

  @override
  String get autoConnect => 'Auto-Connect';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginInBrowser =>
      'Sign in with your Microsoft account and come back to this screen';

  @override
  String get loginOpenBrowser => 'Open in browser';

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
  String get close => 'Close';

  @override
  String get launchError => 'Couldn\'t start the game';

  @override
  String get launchErrorDesc => 'Check your connection and try again';

  @override
  String get lastNews => 'Last news';

  @override
  String get missingClientId =>
      'Missing MS_CLIENT_ID: run or build with --dart-define-from-file=.env';

  @override
  String get noOrganizationsTitle => 'You don\'t have any organization yet';

  @override
  String get noOrganizationsDesc =>
      'Open your organization\'s link from its website and it will be added here.';

  @override
  String addOrganizationQuestion(String name) {
    return 'Add $name?';
  }

  @override
  String get addOrganizationDesc =>
      'You\'ll be able to see and play its instances from the launcher.';

  @override
  String get add => 'Add';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get connecting => 'Connecting…';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get organizationOfflineTitle => 'Couldn\'t connect';

  @override
  String get organizationOfflineDesc =>
      'The organization isn\'t responding. Check your internet connection and try again.';

  @override
  String organizationNoAccessTitle(String name) {
    return 'You don\'t have access to $name';
  }

  @override
  String get organizationNoAccessDesc =>
      'If you think you should, ask whoever runs the organization for access.';

  @override
  String organizationIncompatibleTitle(String name) {
    return '$name isn\'t compatible';
  }

  @override
  String get organizationIncompatibleDesc =>
      'This organization uses a server version your launcher doesn\'t support. Try updating the launcher or let the organization know.';

  @override
  String get launcherOutdatedTitle => 'Update BC Launcher';

  @override
  String launcherOutdatedDesc(String name, String required, String current) {
    return '$name needs launcher version $required or later. You have $current.';
  }

  @override
  String get downloadNewVersion => 'Download the new version';

  @override
  String get organizationSignInErrorTitle => 'Couldn\'t sign in';

  @override
  String get organizationSignInErrorDesc =>
      'Something went wrong signing in to the organization. Try again.';

  @override
  String get minecraftSessionRejectedTitle =>
      'Minecraft didn\'t accept your session';

  @override
  String get minecraftSessionRejectedDesc =>
      'Sign out and sign in again with your Microsoft account.';

  @override
  String get chooseInstance => 'Choose an instance';

  @override
  String get noInstancesTitle => 'There are no instances for you yet';

  @override
  String noInstancesDesc(String name) {
    return 'When $name gives you access to an instance, it will show up here.';
  }

  @override
  String get noDescription => 'No description';

  @override
  String lostAccessTitle(String name) {
    return 'You no longer have access to $name';
  }

  @override
  String get lostAccessDesc =>
      'If they give you access again, it will show up here by itself. If you don\'t need it, you can remove it.';

  @override
  String noLongerCompatibleTitle(String name) {
    return '$name is no longer compatible';
  }

  @override
  String organizationUnreachableTitle(String name) {
    return 'Couldn\'t connect to $name';
  }

  @override
  String get organizationUnreachableDesc =>
      'Check your internet connection and try again.';

  @override
  String get removeOrganization => 'Remove organization';

  @override
  String removeOrganizationQuestion(String name) {
    return 'Remove $name?';
  }

  @override
  String get removeOrganizationDesc =>
      'It will no longer show up in the launcher, and its instances will be deleted from this computer, including worlds and screenshots. To add it again you\'ll have to open its link.';

  @override
  String get remove => 'Remove';

  @override
  String get installed => 'Installed';

  @override
  String get notInstalled => 'Not installed';

  @override
  String get updateAvailable => 'Update available';

  @override
  String downloadingInstance(String name, int percent) {
    return 'Downloading $name · $percent%';
  }

  @override
  String installingInstance(String name, int percent) {
    return 'Installing $name · $percent%';
  }

  @override
  String updatingInstance(String name, int percent) {
    return 'Updating $name · $percent%';
  }

  @override
  String syncProgress(
    int files,
    int totalFiles,
    int megabytes,
    int totalMegabytes,
  ) {
    return '$files of $totalFiles files · $megabytes MB of $totalMegabytes MB';
  }

  @override
  String gameFiles(String version) {
    return 'Game files (Minecraft $version)';
  }

  @override
  String gameFilesWithLoader(String version, String loader) {
    return 'Game files (Minecraft $version and $loader)';
  }

  @override
  String downloadFailedTitle(String name) {
    return 'Couldn\'t download $name';
  }

  @override
  String updateFailedTitle(String name) {
    return 'Couldn\'t update $name';
  }

  @override
  String installFailedTitle(String name) {
    return 'Couldn\'t install $name';
  }

  @override
  String get downloadOfflineDesc =>
      'Check your internet connection and try again. What\'s already downloaded won\'t be downloaded again.';

  @override
  String get downloadFailedDesc =>
      'Something went wrong. Try again; what\'s already downloaded won\'t be downloaded again.';

  @override
  String loaderNotSupportedDesc(String name, String loader) {
    return '$name uses $loader, which this version of the launcher can\'t install yet.';
  }

  @override
  String get gameFilesFailedDesc =>
      'The game files (Minecraft, its loader and Java) couldn\'t be prepared. Try again later.';

  @override
  String get notEnoughSpaceTitle => 'Not enough space';

  @override
  String notEnoughSpaceDesc(String name, int needed, int available) {
    return '$name needs $needed MB and there are only $available MB free on the disk. Free up some space and try again.';
  }

  @override
  String instanceGoneTitle(String name) {
    return '$name is no longer available';
  }

  @override
  String get instanceGoneDesc =>
      'The organization may have removed it, or you no longer have access to it.';

  @override
  String get backToInstances => 'Back to the instances';
}
