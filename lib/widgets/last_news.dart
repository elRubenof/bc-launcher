import 'package:flutter/material.dart';
import 'package:launcher/utils/data.dart';
import 'package:launcher/widgets/mouse_icon_button.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LastNews extends StatefulWidget {
  const LastNews({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LastNewsState();
  }
}

class _LastNewsState extends State<LastNews> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 650,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Últimas noticias",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(
                  news.length,
                  (index) => MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => currentIndex = index),
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: AnimatedContainer(
                          height: 3,
                          width: currentIndex == index ? 45 : 35,
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(left: 7),
                          decoration: BoxDecoration(
                              color: currentIndex == index
                                  ? Theme.of(context).primaryColor
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
          NewsCard(newData: news[currentIndex]),
        ],
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final Map<String, String> newData;

  const NewsCard({super.key, required this.newData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 650,
      height: 380,
      margin: const EdgeInsets.only(top: 26),
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        color: const Color(0xff23162A),
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(newData['image']!),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        width: double.infinity,
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 50),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 400,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    newData['title']!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    newData['description']!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  )
                ],
              ),
            ),
            if (newData['discordLink'] != null)
              MouseIconButton(
                icon: Icons.open_in_new,
                size: 19.0,
                toolTip: "Abrir",
                color: Colors.white.withOpacity(0.4),
                hoverColor: Colors.white.withOpacity(0.7),
                backgroundSize: 40.0,
                backgroundColor: Colors.white.withOpacity(0.12),
                onTap: () => launchUrlString(newData['discordLink']!),
              ),
          ],
        ),
      ),
    );
  }
}
