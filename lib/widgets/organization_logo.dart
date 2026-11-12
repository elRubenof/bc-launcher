import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:flutter/material.dart';

/// An organization's logo in a rounded square; its initials while it has
/// none or it can't be loaded. [greyedOut] dims it (no access, incompatible).
class OrganizationLogo extends StatelessWidget {
  final Organization organization;
  final double size;
  final bool greyedOut;

  const OrganizationLogo({
    super.key,
    required this.organization,
    this.size = 48,
    this.greyedOut = false,
  });

  @override
  Widget build(BuildContext context) {
    final initials = Container(
      alignment: Alignment.center,
      color: greyedOut
          ? Colors.white.withValues(alpha: 0.08)
          : Constants.mainColor.withValues(alpha: 0.45),
      child: Text(
        _initials(organization.name),
        style: TextStyle(
          color: Colors.white.withValues(alpha: greyedOut ? 0.5 : 1),
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final logoUrl = organization.logoUrl;
    return Opacity(
      opacity: greyedOut && logoUrl != null ? 0.45 : 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: SizedBox(
          width: size,
          height: size,
          child: logoUrl == null
              ? initials
              : Image.network(
                  logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => initials,
                ),
        ),
      ),
    );
  }

  static String _initials(String name) => name
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0].toUpperCase())
      .join();
}
