import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'common/theme/app_theme.dart';
import 'view/screens/chat_screen.dart';
// import 'providers/theme_provider.dart'; // 생성 후 주석 해제

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(400, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    const ProviderScope(
      child: VibeCodeApp(),
    ),
  );
}

class VibeCodeApp extends ConsumerWidget {
  const VibeCodeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Provider 생성 후 주석 해제
    // final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Vibe Code',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // TODO: Provider로 대체
      home: const ChatScreen(),
    );
  }
}
