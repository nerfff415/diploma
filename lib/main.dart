import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/reminder_service.dart';
import 'screens/auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/first_aid_kits_list_screen.dart';
import 'widgets/bottom_navigation.dart';

void main() async {
  // Инициализация Flutter и Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем Firebase с явными опциями
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDFJFGWEald7RYymGQ9Akq-b3ZJqztJflA",
      appId: "1:960133105280:android:8fcf085f162ac80cfb0865",
      messagingSenderId: "960133105280",
      projectId: "firstaidkit-ec246",
      storageBucket: "firstaidkit-ec246.firebasestorage.app",
    ),
  );

  // Инициализируем проверку уведомлений
  _initializeReminders();

  runApp(const MyApp());
}

// Функция для инициализации и проверки уведомлений
void _initializeReminders() async {
  // Получаем текущего пользователя
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final reminderService = ReminderService();

    // Проверяем и создаем уведомления о приеме лекарств
    await reminderService.checkAndCreateMedicationReminders(user.uid);

    // Проверяем и создаем уведомления о сроке годности
    await reminderService.checkAndCreateExpiryReminders(user.uid);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MultiProvider(
      providers: [
        StreamProvider<User?>.value(
          value: authService.userStream,
          initialData: null,
        ),
        Provider<AuthService>(create: (_) => authService),
      ],
      child: MaterialApp(
        title: 'Аптечки',
        debugShowCheckedModeBanner: false, // Убираем баннер Debug
        theme: ThemeData(
          // This is the theme of your application.
          //
          // TRY THIS: Try running your application with "flutter run". You'll see
          // the application has a purple toolbar. Then, without quitting the app,
          // try changing the seedColor in the colorScheme below to Colors.green
          // and then invoke "hot reload" (save your changes or press the "hot
          // reload" button in a Flutter-supported IDE, or press "r" if you used
          // the command line to start the app).
          //
          // Notice that the counter didn't reset back to zero; the application
          // state is not lost during the reload. To reset the state, use hot
          // restart instead.
          //
          // This works for code too, not just values: Most code changes can be
          // tested with just a hot reload.
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        // Определяем маршруты в приложении
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
          '/home': (context) => const BottomNavigation(),
        },
      ),
    );
  }
}
