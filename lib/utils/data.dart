import 'dart:io';

const String appVersion = "1.0.0";

late Directory documentsDirectory;
final String minecraftPath = "${documentsDirectory.path}/minecraft";

const String minecraftApi = "https://api.minecraftservices.com";
const String serverIp = "server.spartaland.es";

final news = [
  {
    "title": "Nueva dimensión",
    "description":
        "Una desconocida dimensión repleta de lava ha sido descubierta. Explora el Nether y sus misterios desde ya mismo, solo debes crear un portal y atravesarlo.",
    "image": "https://i.imgur.com/OJcLAr6.jpg",
    "discordLink":
        "discord://discord.com/channels/535511017753411615/535512478960975923/946043873023623229",
  },
  {
    "title": "Bienvenido a Spartaland",
    "description":
        "Un nuevo mundo por explorar. Descubre los secretos y aventuras que envuelven este enigmático lugar y sus murallas.",
    "image": "https://i.imgur.com/RKqKEQH.png",
  },
];
