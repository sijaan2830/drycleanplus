import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class SocialLoginButton extends StatelessWidget {
  final String? icon;
  final IconData? iconData;
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    this.icon,
    this.iconData,
    required this.text,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
          color: AppColors.gold.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconData != null)
            Icon(
              iconData,
              size: 20,
              color: textColor,
            )
          else if (icon != null)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.account_circle,
                size: 20,
                color: textColor,
              ),
            ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
