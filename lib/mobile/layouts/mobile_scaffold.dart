import 'package:flutter/material.dart';

class MobileScaffold extends StatelessWidget {
  const MobileScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottomNavigationBar,
    this.appBarColor,
  });

  final String title;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Color? appBarColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: appBarColor,
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
