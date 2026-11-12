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
  String get webTabError => 'Couldn\'t load the page';

  @override
  String get gameSettings => 'Game settings';

  @override
  String get directory => 'Directory';

  @override
  String get open => 'Open';

  @override
  String get resolution => 'Resolution';

  @override
  String get resolutionDesc => 'Initial size of the game\'s window.';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get settingsInstanceGroup => 'This instance';

  @override
  String get settingsAllInstancesGroup => 'All instances';

  @override
  String get settingsSupportGroup => 'Support';

  @override
  String get fullscreenDesc => 'When it\'s on, the resolution isn\'t used.';

  @override
  String memoryRecommended(int gb) {
    return 'Recommended: $gb GB';
  }

  @override
  String get memoryAllocation => 'Memory allocation';

  @override
  String get resetSettings => 'Reset';

  @override
  String get openLastInstance => 'Open the last instance directly';

  @override
  String get openLastInstanceDesc =>
      'When you open the launcher you\'ll go into the last instance you used.';

  @override
  String get keepLauncherOpen => 'Keep the launcher open';

  @override
  String get keepLauncherOpenDesc =>
      'While you play, the launcher stays in view.';

  @override
  String get gameLogs => 'Game logs';

  @override
  String get gameLogsDesc =>
      'If something goes wrong, export them and send them to the organization.';

  @override
  String get openFolder => 'Open folder';

  @override
  String get export => 'Export';

  @override
  String get noLogsTitle => 'No logs yet';

  @override
  String get noLogsDesc => 'Come back after your first game.';

  @override
  String get close => 'Close';

  @override
  String get launchError => 'Couldn\'t start the game';

  @override
  String get launchErrorDesc => 'Check your connection and try again.';

  @override
  String get playing => 'Playing';

  @override
  String get gameCrashedTitle => 'The game closed because of an error';

  @override
  String gameCrashedDesc(String name) {
    return '$name closed unexpectedly. If it happens again, export the game\'s log and send it to the organization.';
  }

  @override
  String get exportLog => 'Export';

  @override
  String get openLogsFolder => 'Open logs folder';

  @override
  String logsFileName(String instance, String date) {
    return '$instance-logs-$date';
  }

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
  String launcherOutdatedDesc(String name, String required) {
    return '$name needs launcher version $required or later.';
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
      'It will no longer show up, and its instances will be deleted, including worlds and screenshots.';

  @override
  String get remove => 'Remove';

  @override
  String get installed => 'Installed';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get showInFinder => 'Show in Finder';

  @override
  String get openInExplorer => 'Open in Explorer';

  @override
  String get deleteFromComputer => 'Delete from this computer';

  @override
  String get deleteInstance => 'Delete instance';

  @override
  String deleteInstanceQuestion(String name) {
    return 'Delete $name from this computer?';
  }

  @override
  String get deleteInstanceDesc =>
      'Its worlds, screenshots and game settings will be deleted.';

  @override
  String get delete => 'Delete';

  @override
  String deletingInstance(String name) {
    return 'Deleting $name…';
  }

  @override
  String get deletingInstanceDesc => 'It may take a few seconds';

  @override
  String deleteFailedTitle(String name) {
    return 'Couldn\'t delete $name';
  }

  @override
  String get deleteFailedDesc =>
      'Close the game and any program using its folder, then try again.';

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
  String get loadingSigningIn => 'Signing in…';

  @override
  String loadingChecking(String name) {
    return 'Checking $name…';
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
  String get downloadFailedDesc => 'Something went wrong. Try again.';

  @override
  String loaderNotSupportedDesc(String name, String loader, String minecraft) {
    return '$name uses $loader for Minecraft $minecraft, which this launcher can\'t install.';
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

  @override
  String get latestNews => 'Latest news';

  @override
  String get pinnedNews => 'PINNED';

  @override
  String get readMore => 'Read more';

  @override
  String get readLess => 'Read less';

  @override
  String get newsError => 'Couldn\'t load the news';

  @override
  String get discord => 'Discord';

  @override
  String get website => 'Website';

  @override
  String organizationNotResponding(String name) {
    return '$name isn\'t responding';
  }

  @override
  String get playInstalledDesc =>
      'You can play what you already have installed, only local mode. The other instances will show up when it\'s server respondes.';

  @override
  String get playingInstalledDesc =>
      'You\'re playing what\'s installed. It may not be up to date.';

  @override
  String get noInternetTitle => 'No internet connection';

  @override
  String get singlePlayerOnlyDesc =>
      'You can play single player. You won\'t be able to join servers.';

  @override
  String get useAnotherAccount => 'Use another account';

  @override
  String get accountChildTitle => 'Your account needs permission';

  @override
  String get accountChildDesc =>
      'It\'s a child account. An adult in your family has to allow you to play online in the Xbox family settings.';

  @override
  String get accountNoXboxTitle => 'Your account has no Xbox profile';

  @override
  String get accountNoXboxDesc =>
      'Create one for free on xbox.com with this account and try again.';

  @override
  String get accountCountryTitle =>
      'Xbox Live isn\'t available in your country';

  @override
  String get accountCountryDesc =>
      'Minecraft can\'t be played with this account from your country.';

  @override
  String get accountAdultTitle => 'You need to verify your age';

  @override
  String get accountAdultDesc =>
      'Xbox asks you to verify that you\'re an adult before playing with this account.';

  @override
  String get accountNoGameTitle => 'This account doesn\'t have Minecraft';

  @override
  String get accountNoGameDesc =>
      'To play you need Minecraft: Java Edition on the Microsoft account you signed in with.';

  @override
  String get loginExpiredTitle => 'Sign in again';

  @override
  String get loginExpiredDesc =>
      'Your Microsoft session expired or was closed somewhere else. Sign in again in the browser.';

  @override
  String updateReadyTitle(String version) {
    return 'BC Launcher $version is ready';
  }

  @override
  String get updateReadyDesc => 'Restart to install it.';

  @override
  String get updateCloseGameDesc => 'Close the game to restart';

  @override
  String updateAvailableTitle(String version) {
    return 'A new version is out: BC Launcher $version';
  }

  @override
  String get updateAvailableDesc => 'Download it and replace the one you have.';

  @override
  String get whatsNew => 'What\'s new';

  @override
  String get restart => 'Restart';

  @override
  String get download => 'Download';

  @override
  String get hideNotice => 'Hide';

  @override
  String updatingPercent(String percent) {
    return 'Updating $percent%';
  }

  @override
  String get updating => 'Updating…';

  @override
  String get newVersion => 'the new version';

  @override
  String updateUnsupportedDownloadingDesc(String version) {
    return 'This launcher version is no longer supported. Downloading $version; the launcher restarts by itself when it\'s done.';
  }

  @override
  String updateDownloadingDesc(String version) {
    return 'Downloading $version; the launcher restarts by itself when it\'s done.';
  }

  @override
  String get launcherUpdateFailedTitle => 'The launcher couldn\'t be updated';

  @override
  String get launcherUpdateFailedDesc =>
      'Check your internet connection and try again.';

  @override
  String get updateRequiredTitle => 'Update to keep playing';

  @override
  String updateRequiredDesc(String version) {
    return 'This launcher version is no longer supported. Download $version to keep playing.';
  }

  @override
  String get updateStepClose => 'Close BC Launcher.';

  @override
  String get updateStepReplaceMac =>
      'Open the downloaded .dmg and drag BC Launcher to Applications, replacing the old one.';

  @override
  String get updateStepReplaceLinux =>
      'Replace your AppImage with the downloaded one and make it executable.';

  @override
  String get updateStepOpenMac =>
      'Open it again. If macOS blocks it: System Settings › Privacy & Security › Open Anyway. Your instances, worlds and account are still there.';

  @override
  String get updateStepOpenLinux =>
      'Open it again. Your instances, worlds and account are still there.';

  @override
  String get updateLauncher => 'Update the launcher';
}
