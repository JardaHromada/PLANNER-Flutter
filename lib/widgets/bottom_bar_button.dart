import 'package:flutter/material.dart';

class BottomBarButton extends StatelessWidget {
  final BuildContext context;
  final String label;
  final IconData icon;
  final String route;
  final bool isSpecial;

  const BottomBarButton({
    super.key,
    required this.context,
    required this.label,
    required this.icon,
    required this.route,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSpecial)
          Container(
            width: 64,
            height: 32,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 35, 74, 97),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(icon, size: 24, color: Colors.white),
              onPressed: () {},
            ),
          )
        else
          IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, route);
            },
          ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFD7E2FF),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.50,
          ),
        ),
      ],
    );
  }
}
