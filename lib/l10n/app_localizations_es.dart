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
  String get syncing => 'Sincronizando';

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
  String get versionErrorDialogTitle => 'Versión incorrecta';

  @override
  String get versionErrorDialogDescription =>
      'Se ha detectado una versión incorrecta de la instancia. ¿Deseas reinstalar';

  @override
  String get reinstallDialogTitle => 'Reinstalar instancia';

  @override
  String get reinstallDialogDescription =>
      '¿Estás seguro que deseas reinstalar';
}
