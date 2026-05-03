import 'package:flutter/material.dart';
import '../screens/how_it_works_screen.dart';

class AnimatedHowItWorksTile extends StatefulWidget {
  const AnimatedHowItWorksTile({super.key});

  @override
  State<AnimatedHowItWorksTile> createState() => _AnimatedHowItWorksTileState();
}

class _AnimatedHowItWorksTileState extends State<AnimatedHowItWorksTile>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.05, // subtle pulse
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: const Icon(Icons.lightbulb_outline, color: Colors.orange),
          title: const Text(
            'See How It Works',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('Quick demo of ScanBite'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.pop(context); // close drawer
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HowItWorksScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}