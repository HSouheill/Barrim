import 'package:flutter/material.dart';

class HeaderComponent extends StatelessWidget {
  final String logoPath;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Color backgroundColor;
  final VoidCallback? onMenuPressed;
  final bool isLogoutButton;

  const HeaderComponent({
    Key? key,
    required this.logoPath,
    required this.scaffoldKey,
    this.backgroundColor = const Color(0xFF5B87EA),
    this.onMenuPressed,
    this.isLogoutButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 360,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0x00000000),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      logoPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 16),
                if (onMenuPressed != null)
                  InkWell(
                    onTap: onMenuPressed,
                    child: isLogoutButton
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.logout, color: Colors.red, size: 18),
                          )
                        : Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.menu, color: Colors.white, size: 18),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}