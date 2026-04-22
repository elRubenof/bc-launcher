import 'package:bc_launcher/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String? description;
  final String mainButtonText;
  final String? secondaryButtonText;

  final Color backgroundColor;
  final Color? mainButtonColor;
  final Color? secondaryButtonColor;

  final VoidCallback mainButtonOnPressed;
  final VoidCallback? secondaryButtonOnPressed;

  const CustomDialog({
    super.key,
    required this.title,
    this.description,
    required this.mainButtonText,
    this.secondaryButtonText,
    this.backgroundColor = Constants.backgroundColor,
    this.mainButtonColor,
    this.secondaryButtonColor = const Color(0x666750A4),
    required this.mainButtonOnPressed,
    this.secondaryButtonOnPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Constants.textColor,
                  fontSize: MediaQuery.of(context).size.height * 0.03,
                ),
              ),
              if (description != null)
                Text(
                  description!,
                  style: TextStyle(
                    color: Constants.textColor.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 30),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: CupertinoButton.filled(
                      color: mainButtonColor,
                      onPressed: mainButtonOnPressed,
                      child: Container(
                        width: 25,
                        alignment: Alignment.center,
                        child: Text(mainButtonText),
                      ),
                    ),
                  ),
                  if (secondaryButtonText != null) const SizedBox(width: 10),
                  if (secondaryButtonText != null)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: CupertinoButton.filled(
                        color: secondaryButtonColor,
                        onPressed: () => Navigator.pop(context),
                        child: Container(
                          width: 25,
                          alignment: Alignment.center,
                          child: Text(secondaryButtonText!),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
