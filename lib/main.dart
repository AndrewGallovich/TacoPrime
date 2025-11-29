import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tacoprime/authorization/login_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Add this import

import 'models/cart.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Add this here:
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got foreground message!');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
  });
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Cart(),
      builder: (context, child) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoginCheck(),
      ),
    );
  }
}