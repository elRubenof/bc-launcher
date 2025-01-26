import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/news_card.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Constants.horizontalPadding,
        vertical: Constants.topBarHeight,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(),
          if (Utility.news.isNotEmpty) newSection(),
        ],
      ),
    );
  }

  Widget newSection() {
     double width = MediaQuery.of(context).size.width * 0.4;
    if (width > 1000) width = 1000;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Últimas noticias",
                style: TextStyle(
                  color: Constants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(
                  Utility.news.length,
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
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
          NewsCard(
            width: width,
            newData: Utility.news[currentIndex],
          ),
        ],
      ),
    );
  }
}
