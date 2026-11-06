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
  String get map => 'Mapa';

  @override
  String get settings => 'Ajustes';

  @override
  String get play => 'Jugar';

  @override
  String get screenshots => 'Capturas de pantalla';

  @override
  String get reinstall => 'Reinstalar';

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
  String get mapError => 'Error al cargar el mapa';

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
  String get installing => 'Instalando';

  @override
  String get availableUpdate => 'Actualización disponible';

  @override
  String get updateQuestion =>
      '¿Quieres instalar la última versión de la aplicación?';

  @override
  String get yes => 'Si';

  @override
  String get no => 'No';

  @override
  String get updatedNeeded => 'Actualización necesaria';

  @override
  String get close => 'Cerrar';

  @override
  String get downloading => 'Descargando';

  @override
  String get downloadingJava => 'Descargando Java';

  @override
  String get downloadingLibraries => 'Descargando archivos del juego';

  @override
  String get launchError => 'No se pudo iniciar el juego';

  @override
  String get launchErrorDesc => 'Comprueba tu conexión e inténtalo de nuevo';

  @override
  String get lastNews => 'Últimas noticias';

  @override
  String get userNotAuthorized => 'Usuario no autorizado';

  @override
  String get serverNotResponding => 'Servidor no responde';

  @override
  String get missingClientId =>
      'Falta MS_CLIENT_ID: ejecuta o compila con --dart-define-from-file=.env';

  @override
  String get versionErrorDialogTitle => 'Versión incorrecta';

  @override
  String get versionErrorDialogDescription =>
      'Se ha detectado una versión incorrecta de la instancia. ¿Deseas reinstalar';

  @override
  String get reinstallDialogTitle => 'Reinstalar instancia';

  @override
  String get reinstallDialogDescription =>
      '¿Estás seguro que deseas reinstalar';

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
  String launcherOutdatedDesc(String name, String required, String current) {
    return '$name necesita la versión $required o posterior del launcher. Tienes la $current.';
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
}
