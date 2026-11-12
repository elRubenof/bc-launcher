import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @screenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get screenshots;

  /// No description provided for @autoConnect.
  ///
  /// In en, this message translates to:
  /// **'Auto-Connect'**
  String get autoConnect;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Microsoft account and come back to this screen'**
  String get loginInBrowser;

  /// No description provided for @loginOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get loginOpenBrowser;

  /// No description provided for @loginCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get loginCopyLink;

  /// No description provided for @loginLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get loginLinkCopied;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in'**
  String get loginError;

  /// No description provided for @loginErrorDesc.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while signing in with Microsoft'**
  String get loginErrorDesc;

  /// No description provided for @loginRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get loginRetry;

  /// No description provided for @loginBrowserDone.
  ///
  /// In en, this message translates to:
  /// **'You can close this tab and go back to BC Launcher'**
  String get loginBrowserDone;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @switchInstances.
  ///
  /// In en, this message translates to:
  /// **'Switch server'**
  String get switchInstances;

  /// No description provided for @webTabError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the page'**
  String get webTabError;

  /// No description provided for @gameSettings.
  ///
  /// In en, this message translates to:
  /// **'Game Settings'**
  String get gameSettings;

  /// No description provided for @directory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get directory;

  /// No description provided for @directoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Path where your game files are located'**
  String get directoryDesc;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolution;

  /// No description provided for @resolutionDesc.
  ///
  /// In en, this message translates to:
  /// **'Initial size for the game´s window'**
  String get resolutionDesc;

  /// No description provided for @fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// No description provided for @memoryAllocation.
  ///
  /// In en, this message translates to:
  /// **'Memory Allocation'**
  String get memoryAllocation;

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset settings'**
  String get resetSettings;

  /// No description provided for @openLastInstance.
  ///
  /// In en, this message translates to:
  /// **'Open the last instance directly'**
  String get openLastInstance;

  /// No description provided for @openLastInstanceDesc.
  ///
  /// In en, this message translates to:
  /// **'When you open the launcher you\'ll go into the last instance you used. If you turn it off, you\'ll always start at the list of instances.'**
  String get openLastInstanceDesc;

  /// No description provided for @keepLauncherOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep the launcher open'**
  String get keepLauncherOpen;

  /// No description provided for @keepLauncherOpenDesc.
  ///
  /// In en, this message translates to:
  /// **'While you play, the launcher stays in view. If you turn it off, it hides and closes when you leave the game.'**
  String get keepLauncherOpenDesc;

  /// No description provided for @gameLogs.
  ///
  /// In en, this message translates to:
  /// **'Game logs'**
  String get gameLogs;

  /// No description provided for @gameLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'What happened in each game. If something goes wrong, export them and send them to the organization.'**
  String get gameLogsDesc;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get openFolder;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @noLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get noLogsTitle;

  /// No description provided for @noLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'Come back after your first game.'**
  String get noLogsDesc;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @launchError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the game'**
  String get launchError;

  /// No description provided for @launchErrorDesc.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get launchErrorDesc;

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get playing;

  /// No description provided for @gameCrashedTitle.
  ///
  /// In en, this message translates to:
  /// **'The game closed because of an error'**
  String get gameCrashedTitle;

  /// No description provided for @gameCrashedDesc.
  ///
  /// In en, this message translates to:
  /// **'{name} closed unexpectedly. If it happens again, export the game\'s log and send it to the organization.'**
  String gameCrashedDesc(String name);

  /// No description provided for @exportLog.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportLog;

  /// No description provided for @openLogsFolder.
  ///
  /// In en, this message translates to:
  /// **'Open logs folder'**
  String get openLogsFolder;

  /// No description provided for @logsFileName.
  ///
  /// In en, this message translates to:
  /// **'{instance}-logs-{date}'**
  String logsFileName(String instance, String date);

  /// No description provided for @lastNews.
  ///
  /// In en, this message translates to:
  /// **'Last news'**
  String get lastNews;

  /// No description provided for @missingClientId.
  ///
  /// In en, this message translates to:
  /// **'Missing MS_CLIENT_ID: run or build with --dart-define-from-file=.env'**
  String get missingClientId;

  /// No description provided for @noOrganizationsTitle.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any organization yet'**
  String get noOrganizationsTitle;

  /// No description provided for @noOrganizationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Open your organization\'s link from its website and it will be added here.'**
  String get noOrganizationsDesc;

  /// No description provided for @addOrganizationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add {name}?'**
  String addOrganizationQuestion(String name);

  /// No description provided for @addOrganizationDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be able to see and play its instances from the launcher.'**
  String get addOrganizationDesc;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @organizationOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect'**
  String get organizationOfflineTitle;

  /// No description provided for @organizationOfflineDesc.
  ///
  /// In en, this message translates to:
  /// **'The organization isn\'t responding. Check your internet connection and try again.'**
  String get organizationOfflineDesc;

  /// No description provided for @organizationNoAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to {name}'**
  String organizationNoAccessTitle(String name);

  /// No description provided for @organizationNoAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'If you think you should, ask whoever runs the organization for access.'**
  String get organizationNoAccessDesc;

  /// No description provided for @organizationIncompatibleTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} isn\'t compatible'**
  String organizationIncompatibleTitle(String name);

  /// No description provided for @organizationIncompatibleDesc.
  ///
  /// In en, this message translates to:
  /// **'This organization uses a server version your launcher doesn\'t support. Try updating the launcher or let the organization know.'**
  String get organizationIncompatibleDesc;

  /// No description provided for @launcherOutdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Update BC Launcher'**
  String get launcherOutdatedTitle;

  /// No description provided for @launcherOutdatedDesc.
  ///
  /// In en, this message translates to:
  /// **'{name} needs launcher version {required} or later.'**
  String launcherOutdatedDesc(String name, String required);

  /// No description provided for @downloadNewVersion.
  ///
  /// In en, this message translates to:
  /// **'Download the new version'**
  String get downloadNewVersion;

  /// No description provided for @organizationSignInErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in'**
  String get organizationSignInErrorTitle;

  /// No description provided for @organizationSignInErrorDesc.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong signing in to the organization. Try again.'**
  String get organizationSignInErrorDesc;

  /// No description provided for @minecraftSessionRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Minecraft didn\'t accept your session'**
  String get minecraftSessionRejectedTitle;

  /// No description provided for @minecraftSessionRejectedDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign out and sign in again with your Microsoft account.'**
  String get minecraftSessionRejectedDesc;

  /// No description provided for @chooseInstance.
  ///
  /// In en, this message translates to:
  /// **'Choose an instance'**
  String get chooseInstance;

  /// No description provided for @noInstancesTitle.
  ///
  /// In en, this message translates to:
  /// **'There are no instances for you yet'**
  String get noInstancesTitle;

  /// No description provided for @noInstancesDesc.
  ///
  /// In en, this message translates to:
  /// **'When {name} gives you access to an instance, it will show up here.'**
  String noInstancesDesc(String name);

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @lostAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'You no longer have access to {name}'**
  String lostAccessTitle(String name);

  /// No description provided for @lostAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'If they give you access again, it will show up here by itself. If you don\'t need it, you can remove it.'**
  String get lostAccessDesc;

  /// No description provided for @noLongerCompatibleTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is no longer compatible'**
  String noLongerCompatibleTitle(String name);

  /// No description provided for @organizationUnreachableTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to {name}'**
  String organizationUnreachableTitle(String name);

  /// No description provided for @organizationUnreachableDesc.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get organizationUnreachableDesc;

  /// No description provided for @removeOrganization.
  ///
  /// In en, this message translates to:
  /// **'Remove organization'**
  String get removeOrganization;

  /// No description provided for @removeOrganizationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeOrganizationQuestion(String name);

  /// No description provided for @removeOrganizationDesc.
  ///
  /// In en, this message translates to:
  /// **'It will no longer show up, and its instances will be deleted, including worlds and screenshots.'**
  String get removeOrganizationDesc;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @showInFinder.
  ///
  /// In en, this message translates to:
  /// **'Show in Finder'**
  String get showInFinder;

  /// No description provided for @openInExplorer.
  ///
  /// In en, this message translates to:
  /// **'Open in Explorer'**
  String get openInExplorer;

  /// No description provided for @deleteFromComputer.
  ///
  /// In en, this message translates to:
  /// **'Delete from this computer'**
  String get deleteFromComputer;

  /// No description provided for @deleteInstance.
  ///
  /// In en, this message translates to:
  /// **'Delete instance'**
  String get deleteInstance;

  /// No description provided for @deleteInstanceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} from this computer?'**
  String deleteInstanceQuestion(String name);

  /// No description provided for @deleteInstanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Its worlds, screenshots and game settings will be deleted.'**
  String get deleteInstanceDesc;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deletingInstance.
  ///
  /// In en, this message translates to:
  /// **'Deleting {name}…'**
  String deletingInstance(String name);

  /// No description provided for @deletingInstanceDesc.
  ///
  /// In en, this message translates to:
  /// **'It may take a few seconds'**
  String get deletingInstanceDesc;

  /// No description provided for @deleteFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete {name}'**
  String deleteFailedTitle(String name);

  /// No description provided for @deleteFailedDesc.
  ///
  /// In en, this message translates to:
  /// **'Close the game and any program using its folder, then try again.'**
  String get deleteFailedDesc;

  /// No description provided for @notInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get notInstalled;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @downloadingInstance.
  ///
  /// In en, this message translates to:
  /// **'Downloading {name} · {percent}%'**
  String downloadingInstance(String name, int percent);

  /// No description provided for @installingInstance.
  ///
  /// In en, this message translates to:
  /// **'Installing {name} · {percent}%'**
  String installingInstance(String name, int percent);

  /// No description provided for @updatingInstance.
  ///
  /// In en, this message translates to:
  /// **'Updating {name} · {percent}%'**
  String updatingInstance(String name, int percent);

  /// No description provided for @loadingSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get loadingSigningIn;

  /// No description provided for @loadingChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking {name}…'**
  String loadingChecking(String name);

  /// No description provided for @syncProgress.
  ///
  /// In en, this message translates to:
  /// **'{files} of {totalFiles} files · {megabytes} MB of {totalMegabytes} MB'**
  String syncProgress(
    int files,
    int totalFiles,
    int megabytes,
    int totalMegabytes,
  );

  /// No description provided for @gameFiles.
  ///
  /// In en, this message translates to:
  /// **'Game files (Minecraft {version})'**
  String gameFiles(String version);

  /// No description provided for @gameFilesWithLoader.
  ///
  /// In en, this message translates to:
  /// **'Game files (Minecraft {version} and {loader})'**
  String gameFilesWithLoader(String version, String loader);

  /// No description provided for @downloadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download {name}'**
  String downloadFailedTitle(String name);

  /// No description provided for @updateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update {name}'**
  String updateFailedTitle(String name);

  /// No description provided for @installFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t install {name}'**
  String installFailedTitle(String name);

  /// No description provided for @downloadOfflineDesc.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again. What\'s already downloaded won\'t be downloaded again.'**
  String get downloadOfflineDesc;

  /// No description provided for @downloadFailedDesc.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get downloadFailedDesc;

  /// No description provided for @loaderNotSupportedDesc.
  ///
  /// In en, this message translates to:
  /// **'{name} uses {loader} for Minecraft {minecraft}, which this launcher can\'t install.'**
  String loaderNotSupportedDesc(String name, String loader, String minecraft);

  /// No description provided for @gameFilesFailedDesc.
  ///
  /// In en, this message translates to:
  /// **'The game files (Minecraft, its loader and Java) couldn\'t be prepared. Try again later.'**
  String get gameFilesFailedDesc;

  /// No description provided for @notEnoughSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough space'**
  String get notEnoughSpaceTitle;

  /// No description provided for @notEnoughSpaceDesc.
  ///
  /// In en, this message translates to:
  /// **'{name} needs {needed} MB and there are only {available} MB free on the disk. Free up some space and try again.'**
  String notEnoughSpaceDesc(String name, int needed, int available);

  /// No description provided for @instanceGoneTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is no longer available'**
  String instanceGoneTitle(String name);

  /// No description provided for @instanceGoneDesc.
  ///
  /// In en, this message translates to:
  /// **'The organization may have removed it, or you no longer have access to it.'**
  String get instanceGoneDesc;

  /// No description provided for @backToInstances.
  ///
  /// In en, this message translates to:
  /// **'Back to the instances'**
  String get backToInstances;

  /// No description provided for @latestNews.
  ///
  /// In en, this message translates to:
  /// **'Latest news'**
  String get latestNews;

  /// No description provided for @pinnedNews.
  ///
  /// In en, this message translates to:
  /// **'PINNED'**
  String get pinnedNews;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @readLess.
  ///
  /// In en, this message translates to:
  /// **'Read less'**
  String get readLess;

  /// No description provided for @newsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the news'**
  String get newsError;

  /// No description provided for @discord.
  ///
  /// In en, this message translates to:
  /// **'Discord'**
  String get discord;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @organizationNotResponding.
  ///
  /// In en, this message translates to:
  /// **'{name} isn\'t responding'**
  String organizationNotResponding(String name);

  /// No description provided for @playInstalledDesc.
  ///
  /// In en, this message translates to:
  /// **'You can play what you already have installed, only local mode. The other instances will show up when it\'s server respondes.'**
  String get playInstalledDesc;

  /// No description provided for @playingInstalledDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'re playing what\'s installed. It may not be up to date.'**
  String get playingInstalledDesc;

  /// No description provided for @noInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetTitle;

  /// No description provided for @singlePlayerOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'You can play single player. You won\'t be able to join servers.'**
  String get singlePlayerOnlyDesc;

  /// No description provided for @useAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Use another account'**
  String get useAnotherAccount;

  /// No description provided for @accountChildTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account needs permission'**
  String get accountChildTitle;

  /// No description provided for @accountChildDesc.
  ///
  /// In en, this message translates to:
  /// **'It\'s a child account. An adult in your family has to allow you to play online in the Xbox family settings.'**
  String get accountChildDesc;

  /// No description provided for @accountNoXboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account has no Xbox profile'**
  String get accountNoXboxTitle;

  /// No description provided for @accountNoXboxDesc.
  ///
  /// In en, this message translates to:
  /// **'Create one for free on xbox.com with this account and try again.'**
  String get accountNoXboxDesc;

  /// No description provided for @accountCountryTitle.
  ///
  /// In en, this message translates to:
  /// **'Xbox Live isn\'t available in your country'**
  String get accountCountryTitle;

  /// No description provided for @accountCountryDesc.
  ///
  /// In en, this message translates to:
  /// **'Minecraft can\'t be played with this account from your country.'**
  String get accountCountryDesc;

  /// No description provided for @accountAdultTitle.
  ///
  /// In en, this message translates to:
  /// **'You need to verify your age'**
  String get accountAdultTitle;

  /// No description provided for @accountAdultDesc.
  ///
  /// In en, this message translates to:
  /// **'Xbox asks you to verify that you\'re an adult before playing with this account.'**
  String get accountAdultDesc;

  /// No description provided for @accountNoGameTitle.
  ///
  /// In en, this message translates to:
  /// **'This account doesn\'t have Minecraft'**
  String get accountNoGameTitle;

  /// No description provided for @accountNoGameDesc.
  ///
  /// In en, this message translates to:
  /// **'To play you need Minecraft: Java Edition on the Microsoft account you signed in with.'**
  String get accountNoGameDesc;

  /// No description provided for @loginExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get loginExpiredTitle;

  /// No description provided for @loginExpiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Your Microsoft session expired or was closed somewhere else. Sign in again in the browser.'**
  String get loginExpiredDesc;

  /// No description provided for @updateReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'BC Launcher {version} is ready'**
  String updateReadyTitle(String version);

  /// No description provided for @updateReadyDesc.
  ///
  /// In en, this message translates to:
  /// **'Restart to install it.'**
  String get updateReadyDesc;

  /// No description provided for @updateCloseGameDesc.
  ///
  /// In en, this message translates to:
  /// **'Close the game to restart'**
  String get updateCloseGameDesc;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'A new version is out: BC Launcher {version}'**
  String updateAvailableTitle(String version);

  /// No description provided for @updateAvailableDesc.
  ///
  /// In en, this message translates to:
  /// **'Download it and replace the one you have.'**
  String get updateAvailableDesc;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNew;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @hideNotice.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideNotice;

  /// No description provided for @updatingPercent.
  ///
  /// In en, this message translates to:
  /// **'Updating {percent}%'**
  String updatingPercent(String percent);

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// No description provided for @newVersion.
  ///
  /// In en, this message translates to:
  /// **'the new version'**
  String get newVersion;

  /// No description provided for @updateUnsupportedDownloadingDesc.
  ///
  /// In en, this message translates to:
  /// **'This launcher version is no longer supported. Downloading {version}; the launcher restarts by itself when it\'s done.'**
  String updateUnsupportedDownloadingDesc(String version);

  /// No description provided for @updateDownloadingDesc.
  ///
  /// In en, this message translates to:
  /// **'Downloading {version}; the launcher restarts by itself when it\'s done.'**
  String updateDownloadingDesc(String version);

  /// No description provided for @launcherUpdateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'The launcher couldn\'t be updated'**
  String get launcherUpdateFailedTitle;

  /// No description provided for @launcherUpdateFailedDesc.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get launcherUpdateFailedDesc;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update to keep playing'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'This launcher version is no longer supported. Download {version} to keep playing.'**
  String updateRequiredDesc(String version);

  /// No description provided for @updateStepClose.
  ///
  /// In en, this message translates to:
  /// **'Close BC Launcher.'**
  String get updateStepClose;

  /// No description provided for @updateStepReplaceMac.
  ///
  /// In en, this message translates to:
  /// **'Open the downloaded .dmg and drag BC Launcher to Applications, replacing the old one.'**
  String get updateStepReplaceMac;

  /// No description provided for @updateStepReplaceLinux.
  ///
  /// In en, this message translates to:
  /// **'Replace your AppImage with the downloaded one and make it executable.'**
  String get updateStepReplaceLinux;

  /// No description provided for @updateStepOpenMac.
  ///
  /// In en, this message translates to:
  /// **'Open it again. If macOS blocks it: System Settings › Privacy & Security › Open Anyway. Your instances, worlds and account are still there.'**
  String get updateStepOpenMac;

  /// No description provided for @updateStepOpenLinux.
  ///
  /// In en, this message translates to:
  /// **'Open it again. Your instances, worlds and account are still there.'**
  String get updateStepOpenLinux;

  /// No description provided for @updateLauncher.
  ///
  /// In en, this message translates to:
  /// **'Update the launcher'**
  String get updateLauncher;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
