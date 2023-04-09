import 'package:flutter/material.dart';
import 'package:launcher/utils/server.dart';

class ServerStatus extends StatelessWidget {
  const ServerStatus({super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> playersList = List.generate(
        Server.players.length > 6 ? 6 : Server.players.length,
        (index) => Container(
            margin: const EdgeInsets.only(left: 7),
            child: Image.network(
              "https://mc-heads.net/avatar/${Server.players[index]['uuid']}",
              height: 20,
            )));

    if (Server.players.length > 6) {
      playersList += [
        Container(
          margin: const EdgeInsets.only(left: 6),
          child: Text(
            "+${Server.players.length - 6}",
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Detalles del servidor",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          width: 290,
          height: 380,
          margin: const EdgeInsets.only(top: 30),
          decoration: BoxDecoration(
            color: const Color(0xff23162A),
            borderRadius: BorderRadius.circular(12),
            image: const DecorationImage(
                alignment: Alignment.bottomCenter,
                image: AssetImage(
                  "assets/test.png",
                ),
                fit: BoxFit.cover),
          ),
          child: Container(
            padding: const EdgeInsets.only(left: 20, top: 15, bottom: 15),
            decoration: BoxDecoration(
              color: const Color(0xff23162A).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Spartaland 3",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Estado:  ",
                          style: TextStyle(color: Colors.white)),
                      Icon(Icons.circle,
                          size: 14,
                          color: Server.isActive ? Colors.green : Colors.red),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: playersList.isEmpty ? 11 : 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Jugadores:",
                        style: TextStyle(color: Colors.white),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: playersList,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
