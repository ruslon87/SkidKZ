// lib/core/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/core/widgets/app_gradient_background.dart';

class AppScaffold extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final FloatingActionButton? floatingActionButton;
  final bool extendBodyBehindAppBar;
  final bool safeTop;
  final bool safeBottom;

  const AppScaffold({
    super.key,
    required this.body,
    this.scaffoldKey,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = true,
    this.safeTop = true,
    this.safeBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppGradientBackground(
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: appBar,
        drawer: drawer,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        body: SafeArea(
          top: safeTop,
          bottom: safeBottom,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: body,
          ),
        ),
      ),
    );
  }
}

class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.r16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: child,
    );
  }
}
