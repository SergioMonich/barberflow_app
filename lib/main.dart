import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';

void main() {
  runApp(const ProviderScope(child: BarberFlowApp()));
}

class BarberFlowApp extends ConsumerWidget {
  const BarberFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'BarberFlow',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      routerConfig: router,
    );
  }
}
