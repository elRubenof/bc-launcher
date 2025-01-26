import 'package:bc_launcher/widgets/mouse_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class NewsCard extends StatelessWidget {
  final Map newData;
  final double width;

  const NewsCard({super.key, required this.width, required this.newData});

  @override
  Widget build(BuildContext context) {
    final hasLink = newData['link'] != null;

    return Container(
      width: width,
      height: width * 0.58,
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
        height: 92,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: hasLink ? width * 0.62 : width - 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    newData['title']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    newData['description']!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12.5,
                    ),
                  )
                ],
              ),
            ),
            if (hasLink)
              MouseIconButton(
                icon: Icons.open_in_new,
                size: 19.0,
                toolTip: "Abrir",
                color: Colors.white.withValues(alpha: 0.4),
                hoverColor: Colors.white.withValues(alpha: 0.7),
                backgroundSize: 40.0,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                onTap: () => launchUrlString(newData['discordLink']!),
              ),
          ],
        ),
      ),
    );
  }
}
