import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/services/callkit_service.dart';
import 'package:yarisa_doctor/services/deep_link_router.dart';
import 'package:yarisa_doctor/services/fcm_service.dart';

import 'services/firebase_options.dart';
import 'theme/theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  DeepLinkRouter.attach(appNavigatorKey);
  await CallKitService.initialize();
  await FcmService.initialize(
    userCollection: 'Doctors',
    onMessageTap: DeepLinkRouter.handle,
    onForegroundCall: CallKitService.showIncoming,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Yarisa Doctor',
      debugShowCheckedModeBanner: false,
      theme: YarisaTheme.lightThemeData(context),
      darkTheme: YarisaTheme.darkThemeData(context),
      home: const LoadingScreen(),
    );
  }
}

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(apimethods).checkAuthState(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }
}
