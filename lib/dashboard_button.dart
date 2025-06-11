import 'package:flutter/material.dart';

/// A custom button widget used for dashboard actions, featuring an icon and
/// label.
///
/// This widget is designed to provide a consistent and visually appealing button
/// that can be used within a dashboard or similar UI. It features a rounded
/// border, a drop shadow, and displays both an icon and a label in the center.

class DashboardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const DashboardButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
          decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(2, 4),
                )
              ]),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                )
              ],
            ),
          )),
    );
  }
}
