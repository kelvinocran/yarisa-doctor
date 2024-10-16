import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:yarisa_doctor/api/api_methods.dart';
import 'package:yarisa_doctor/services/mqtt_listener.dart';

import 'models/chat_model.dart';
import 'providers/chat_provider.dart';
import 'services/firebase_options.dart';
import 'services/mqtt_service.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> implements MQTTMessageListener {
  @override
  void dispose() {
    MQTTService.instance.unregisterListener(this);
    super.dispose();
  }

  @override
  Future<void> onMessageReceived(String payloadJson) async {
    final data = jsonDecode(payloadJson);
    if (mounted) {
      if (data['data_type'] == 'chat') {
        final chat = Chat.fromMQTT((data['data']));

        if (chat.senderId != FirebaseAuth.instance.currentUser?.uid) {
          await ref.read(chatconfig).saveChat(chat.senderId!, chat);
        }
      } else {
        if (data['sender_id'] != FirebaseAuth.instance.currentUser?.uid) {
          ref.read(chatconfig).changeTyingStatus(data['status']);
        }
      }
    }
  }

  mqttForUser() async {
    MQTTService.instance.registerListener(this);

    try {
      await MQTTService.instance.connect();
    } on NoConnectionException catch (e) {
      debugPrint(e.toString());
      MQTTService.instance.connect();
    }
  }

  @override
  void initState() {
    super.initState();
    mqttForUser();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
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
