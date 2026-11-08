// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get home => 'Inicio';

  @override
  String get settings => 'Ajustes';

  @override
  String get play => 'Jugar';

  @override
  String get screenshots => 'Capturas de pantalla';

  @override
  String get autoConnect => 'Auto-Conectar';

  @override
  String get loginTitle => 'Inicia sesión';

  @override
  String get loginInBrowser =>
      'Inicia sesión con tu cuenta de Microsoft y regresa a esta pantalla';

  @override
  String get loginOpenBrowser => 'Abrir en navegador';

  @override
  String get loginCopyLink => 'Copiar enlace';

  @override
  String get loginLinkCopied => 'Enlace copiado';

  @override
  String get loginError => 'No se ha podido iniciar sesión';

  @override
  String get loginErrorDesc =>
      'Algo ha fallado al iniciar sesión con Microsoft';

  @override
  String get loginRetry => 'Reintentar';

  @override
  String get loginBrowserDone =>
      'Ya puedes cerrar esta pestaña y volver a BC Launcher';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get switchInstances => 'Cambiar servidor';

  @override
  String get webTabError => 'No se ha podido cargar la página';

  @override
  String get gameSettings => 'Ajustes de Juego';

  @override
  String get directory => 'Directorio';

  @override
  String get directoryDesc => 'Ruta donde se guardan tus archivos de juego';

  @override
  String get open => 'Abrir';

  @override
  String get resolution => 'Resolución';

  @override
  String get resolutionDesc => 'Tamaño inicial de la ventana del juego';

  @override
  String get fullscreen => 'Pantalla completa';

  @override
  String get memoryAllocation => 'Memoria Asignada';

  @override
  String get resetSettings => 'Reiniciar ajustes';

  @override
  String get openLastInstance => 'Abrir directamente la última instancia';

  @override
  String get openLastInstanceDesc =>
      'Al abrir el launcher entrarás en la última instancia que usaste. Si lo desactivas, empezarás siempre en la lista de instancias.';

  @override
  String get keepLauncherOpen => 'Mantener el launcher abierto';

  @override
  String get keepLauncherOpenDesc =>
      'Mientras juegas, el launcher sigue a la vista. Si lo desactivas, se oculta y se cierra al salir del juego.';

  @override
  String get gameLogs => 'Registros de partidas';

  @override
  String get gameLogsDesc =>
      'Lo que pasó en cada partida. Si algo falla, expórtalos y envíalos a la organización.';

  @override
  String get openFolder => 'Abrir carpeta';

  @override
  String get export => 'Exportar';

  @override
  String get noLogsTitle => 'Todavía no hay registros';

  @override
  String get noLogsDesc =>
      'Se guardan al jugar: vuelve aquí después de tu primera partida.';

  @override
  String get close => 'Cerrar';

  @override
  String get launchError => 'No se pudo iniciar el juego';

  @override
  String get launchErrorDesc => 'Comprueba tu conexión e inténtalo de nuevo';

  @override
  String get playing => 'Jugando';

  @override
  String get gameCrashedTitle => 'El juego se cerró por un error';

  @override
  String gameCrashedDesc(String name) {
    return '$name se ha cerrado inesperadamente. Si vuelve a pasar, exporta el registro de la partida y envíaselo a la organización.';
  }

  @override
  String get exportLog => 'Exportar';

  @override
  String get openLogsFolder => 'Abrir carpeta de registros';

  @override
  String logsFileName(String instance, String date) {
    return '$instance-registros-$date';
  }

  @override
  String get lastNews => 'Últimas noticias';

  @override
  String get missingClientId =>
      'Falta MS_CLIENT_ID: ejecuta o compila con --dart-define-from-file=.env';

  @override
  String get noOrganizationsTitle => 'Aún no tienes ninguna organización';

  @override
  String get noOrganizationsDesc =>
      'Abre el enlace de tu organización desde su página web y se añadirá aquí.';

  @override
  String addOrganizationQuestion(String name) {
    return '¿Añadir $name?';
  }

  @override
  String get addOrganizationDesc =>
      'Podrás ver y jugar sus instancias desde el launcher.';

  @override
  String get add => 'Añadir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get retry => 'Reintentar';

  @override
  String get connecting => 'Conectando…';

  @override
  String get signingIn => 'Iniciando sesión…';

  @override
  String get organizationOfflineTitle => 'No se ha podido conectar';

  @override
  String get organizationOfflineDesc =>
      'La organización no responde. Revisa tu conexión a internet y vuelve a intentarlo.';

  @override
  String organizationNoAccessTitle(String name) {
    return 'No tienes acceso a $name';
  }

  @override
  String get organizationNoAccessDesc =>
      'Si crees que deberías tenerlo, pide acceso a quien gestiona la organización.';

  @override
  String organizationIncompatibleTitle(String name) {
    return '$name no es compatible';
  }

  @override
  String get organizationIncompatibleDesc =>
      'Esta organización usa una versión del servidor que tu launcher no admite. Prueba a actualizar el launcher o avisa a la organización.';

  @override
  String get launcherOutdatedTitle => 'Actualiza BC Launcher';

  @override
  String launcherOutdatedDesc(String name, String required) {
    return '$name necesita la versión $required o posterior del launcher.';
  }

  @override
  String get downloadNewVersion => 'Descargar la nueva versión';

  @override
  String get organizationSignInErrorTitle => 'No se ha podido iniciar sesión';

  @override
  String get organizationSignInErrorDesc =>
      'Algo ha fallado al iniciar sesión en la organización. Vuelve a intentarlo.';

  @override
  String get minecraftSessionRejectedTitle =>
      'Minecraft no ha aceptado tu sesión';

  @override
  String get minecraftSessionRejectedDesc =>
      'Cierra sesión y vuelve a entrar con tu cuenta de Microsoft.';

  @override
  String get chooseInstance => 'Elige una instancia';

  @override
  String get noInstancesTitle => 'Aún no hay instancias para ti';

  @override
  String noInstancesDesc(String name) {
    return 'Cuando $name te dé acceso a una instancia, aparecerá aquí.';
  }

  @override
  String get noDescription => 'Sin descripción';

  @override
  String lostAccessTitle(String name) {
    return 'Ya no tienes acceso a $name';
  }

  @override
  String get lostAccessDesc =>
      'Si vuelven a darte acceso, aparecerá aquí sola. Si no la necesitas, puedes eliminarla.';

  @override
  String noLongerCompatibleTitle(String name) {
    return '$name ya no es compatible';
  }

  @override
  String organizationUnreachableTitle(String name) {
    return 'No se ha podido conectar con $name';
  }

  @override
  String get organizationUnreachableDesc =>
      'Revisa tu conexión a internet y vuelve a intentarlo.';

  @override
  String get removeOrganization => 'Eliminar organización';

  @override
  String removeOrganizationQuestion(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get removeOrganizationDesc =>
      'Dejará de aparecer en el launcher y se borrarán de este equipo sus instancias, incluidos los mundos y las capturas de pantalla. Para volver a añadirla tendrás que abrir su enlace.';

  @override
  String get remove => 'Eliminar';

  @override
  String get installed => 'Instalada';

  @override
  String get unavailable => 'No disponible';

  @override
  String get showInFinder => 'Mostrar en Finder';

  @override
  String get openInExplorer => 'Abrir en el Explorador';

  @override
  String get deleteFromComputer => 'Borrar de este equipo';

  @override
  String get deleteInstance => 'Borrar instancia';

  @override
  String deleteInstanceQuestion(String name) {
    return '¿Borrar $name de este equipo?';
  }

  @override
  String get deleteInstanceDesc =>
      'Se borrarán sus mundos, capturas y ajustes del juego. El resto se puede volver a descargar entrando en la instancia.';

  @override
  String get delete => 'Borrar';

  @override
  String deletingInstance(String name) {
    return 'Borrando $name…';
  }

  @override
  String deleteFailedTitle(String name) {
    return 'No se ha podido borrar $name';
  }

  @override
  String get deleteFailedDesc =>
      'Cierra el juego y cualquier programa que esté usando su carpeta y vuelve a intentarlo.';

  @override
  String get notInstalled => 'Sin instalar';

  @override
  String get updateAvailable => 'Actualización disponible';

  @override
  String downloadingInstance(String name, int percent) {
    return 'Descargando $name · $percent %';
  }

  @override
  String installingInstance(String name, int percent) {
    return 'Instalando $name · $percent %';
  }

  @override
  String updatingInstance(String name, int percent) {
    return 'Actualizando $name · $percent %';
  }

  @override
  String syncProgress(
    int files,
    int totalFiles,
    int megabytes,
    int totalMegabytes,
  ) {
    return '$files de $totalFiles archivos · $megabytes MB de $totalMegabytes MB';
  }

  @override
  String gameFiles(String version) {
    return 'Archivos del juego (Minecraft $version)';
  }

  @override
  String gameFilesWithLoader(String version, String loader) {
    return 'Archivos del juego (Minecraft $version y $loader)';
  }

  @override
  String downloadFailedTitle(String name) {
    return 'No se ha podido descargar $name';
  }

  @override
  String updateFailedTitle(String name) {
    return 'No se ha podido actualizar $name';
  }

  @override
  String installFailedTitle(String name) {
    return 'No se ha podido instalar $name';
  }

  @override
  String get downloadOfflineDesc =>
      'Revisa tu conexión a internet y vuelve a intentarlo. Lo que ya se ha descargado no se vuelve a bajar.';

  @override
  String get downloadFailedDesc =>
      'Algo ha fallado. Vuelve a intentarlo; lo que ya se ha descargado no se vuelve a bajar.';

  @override
  String loaderNotSupportedDesc(String name, String loader, String minecraft) {
    return '$name usa $loader para Minecraft $minecraft, que este launcher no puede instalar.';
  }

  @override
  String get gameFilesFailedDesc =>
      'No se han podido preparar los archivos del juego (Minecraft, su loader y Java). Vuelve a intentarlo más tarde.';

  @override
  String get notEnoughSpaceTitle => 'No hay espacio suficiente';

  @override
  String notEnoughSpaceDesc(String name, int needed, int available) {
    return '$name necesita $needed MB y solo quedan $available MB libres en el disco. Libera espacio y vuelve a intentarlo.';
  }

  @override
  String instanceGoneTitle(String name) {
    return '$name ya no está disponible';
  }

  @override
  String get instanceGoneDesc =>
      'Puede que la organización la haya quitado o que ya no tengas acceso.';

  @override
  String get backToInstances => 'Volver a las instancias';

  @override
  String get latestNews => 'Últimas noticias';

  @override
  String get pinnedNews => 'FIJADA';

  @override
  String get readMore => 'Leer más';

  @override
  String get readLess => 'Leer menos';

  @override
  String get newsError => 'No se han podido cargar las noticias';

  @override
  String get discord => 'Discord';

  @override
  String get website => 'Web';

  @override
  String organizationNotResponding(String name) {
    return '$name no responde';
  }

  @override
  String get playInstalledDesc =>
      'Puedes jugar lo que ya tienes instalado, solo en local. Las demás instancias aparecerán cuando el servidor responda.';

  @override
  String get playingInstalledDesc =>
      'Juegas con lo instalado. Puede que no esté al día.';

  @override
  String get noInternetTitle => 'Sin conexión a internet';

  @override
  String get singlePlayerOnlyDesc =>
      'Puedes jugar en un solo jugador. No podrás entrar en servidores.';

  @override
  String get useAnotherAccount => 'Usar otra cuenta';

  @override
  String get accountChildTitle => 'Tu cuenta necesita permiso';

  @override
  String get accountChildDesc =>
      'Es una cuenta de menor. Un adulto de tu familia tiene que permitir que juegues en línea desde los ajustes familiares de Xbox.';

  @override
  String get accountNoXboxTitle => 'Tu cuenta no tiene perfil de Xbox';

  @override
  String get accountNoXboxDesc =>
      'Crea uno gratis en xbox.com con esta cuenta y vuelve a intentarlo.';

  @override
  String get accountCountryTitle => 'Xbox Live no está disponible en tu país';

  @override
  String get accountCountryDesc =>
      'Con esta cuenta no se puede jugar a Minecraft desde tu país.';

  @override
  String get accountAdultTitle => 'Tienes que verificar tu edad';

  @override
  String get accountAdultDesc =>
      'Xbox pide verificar que eres adulto antes de jugar con esta cuenta. Después, vuelve a intentarlo.';

  @override
  String get accountNoGameTitle => 'Esta cuenta no tiene Minecraft';

  @override
  String get accountNoGameDesc =>
      'Para jugar necesitas Minecraft: Java Edition en la cuenta de Microsoft con la que has entrado.';

  @override
  String get loginExpiredTitle => 'Vuelve a iniciar sesión';

  @override
  String get loginExpiredDesc =>
      'Tu sesión de Microsoft ha caducado o se ha cerrado desde otro sitio. Inicia sesión otra vez en el navegador.';

  @override
  String updateReadyTitle(String version) {
    return 'BC Launcher $version está lista';
  }

  @override
  String get updateReadyDesc => 'Reinicia para instalarla.';

  @override
  String get updateCloseGameDesc => 'Cierra el juego para reiniciar';

  @override
  String updateAvailableTitle(String version) {
    return 'Hay una versión nueva: BC Launcher $version';
  }

  @override
  String get updateAvailableDesc => 'Descárgala y reemplaza la que tienes.';

  @override
  String get whatsNew => 'Novedades';

  @override
  String get restart => 'Reiniciar';

  @override
  String get download => 'Descargar';

  @override
  String get hideNotice => 'Ocultar';

  @override
  String updatingPercent(String percent) {
    return 'Actualizando $percent %';
  }

  @override
  String get updating => 'Actualizando…';

  @override
  String get newVersion => 'nueva versión';

  @override
  String updateUnsupportedDownloadingDesc(String version) {
    return 'Esta versión del launcher ya no tiene soporte. Estamos descargando la $version; al terminar se reiniciará sola.';
  }

  @override
  String updateDownloadingDesc(String version) {
    return 'Estamos descargando la $version; al terminar se reiniciará sola.';
  }

  @override
  String get launcherUpdateFailedTitle =>
      'No se ha podido actualizar el launcher';

  @override
  String get launcherUpdateFailedDesc =>
      'Comprueba tu conexión a internet y vuelve a intentarlo.';

  @override
  String get updateRequiredTitle => 'Actualiza para seguir';

  @override
  String updateRequiredDesc(String version) {
    return 'Esta versión del launcher ya no tiene soporte. Descarga la $version para seguir jugando.';
  }

  @override
  String get updateStepClose => 'Cierra BC Launcher.';

  @override
  String get updateStepReplaceMac =>
      'Abre el .dmg descargado y arrastra BC Launcher a Aplicaciones, reemplazando el anterior.';

  @override
  String get updateStepReplaceLinux =>
      'Reemplaza tu AppImage por la descargada y dale permiso de ejecución.';

  @override
  String get updateStepOpenMac =>
      'Ábrelo de nuevo. Si macOS lo bloquea: Ajustes del Sistema › Privacidad y seguridad › Abrir igualmente. Tus instancias, mundos y cuenta siguen ahí.';

  @override
  String get updateStepOpenLinux =>
      'Ábrelo de nuevo. Tus instancias, mundos y cuenta siguen ahí.';

  @override
  String get updateLauncher => 'Actualizar el launcher';
}
