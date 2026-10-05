import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proving_tool/config.dart';
import 'package:proving_tool/screens/auth/login_screen.dart';
import 'package:proving_tool/screens/dashboard/dashboard_screen.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/services/connectivity_service.dart';
import 'package:proving_tool/services/local_db.dart';
import 'package:proving_tool/services/notification_badge_service.dart';
import 'package:proving_tool/services/sync_service.dart';
import 'package:proving_tool/services/trial_repository.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/widgets/sync_status_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);

  final localDb = LocalDb();
  await localDb.resetInterruptedSyncStatus();

  final connectivity = ConnectivityService.instance..start();
  final trialRepository = TrialRepository(
    supabase: Supabase.instance.client,
    db: localDb,
    connectivity: connectivity,
  );
  final syncService = SyncService(
    supabase: Supabase.instance.client,
    db: localDb,
    connectivity: connectivity,
    trialRepository: trialRepository,
  )..start();
  final notificationBadge = NotificationBadgeService(Supabase.instance.client);

  runApp(
    MyApp(
      trialRepository: trialRepository,
      syncService: syncService,
      connectivity: connectivity,
      notificationBadge: notificationBadge,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.trialRepository,
    required this.syncService,
    required this.connectivity,
    required this.notificationBadge,
  });

  final TrialRepository trialRepository;
  final SyncService syncService;
  final ConnectivityService connectivity;
  final NotificationBadgeService notificationBadge;

  @override
  Widget build(BuildContext context) {
    return AppServices(
      trialRepository: trialRepository,
      syncService: syncService,
      connectivity: connectivity,
      notificationBadge: notificationBadge,
      child: MaterialApp(
        title: 'Prove It',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const AuthGate(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const navy = AppColors.navy;
    const midNavy = AppColors.midNavy;
    const lightNavy = AppColors.lightNavy;
    const accent = AppColors.accent;
    const background = AppColors.background;
    const subBackground = AppColors.subBackground;
    const mainText = AppColors.mainText;
    const otherText = AppColors.otherText;
    const border = AppColors.border;
    const error = AppColors.error;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: navy,
        onPrimary: background,
        secondary: accent,
        onSecondary: navy,
        surface: background,
        onSurface: mainText,
        error: error,
        onError: background,
      ),
      scaffoldBackgroundColor: subBackground,
      textTheme: GoogleFonts.montserratTextTheme().copyWith(
        bodyLarge: _font(15, color: mainText),
        bodyMedium: _font(14, color: mainText),
        bodySmall: _font(13, color: otherText),
        titleLarge: _font(22, color: navy, weight: FontWeight.w600),
        titleMedium: _font(16, color: navy, weight: FontWeight.w600),
        titleSmall: _font(15, color: navy, weight: FontWeight.w600),
        labelLarge: _font(14, color: background, weight: FontWeight.w500),
      ),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: navy,
        foregroundColor: background,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        titleTextStyle: _font(16, color: background, weight: FontWeight.w600),
        iconTheme: const IconThemeData(color: background),
        actionsIconTheme: const IconThemeData(color: background),
      ),

      cardTheme: CardThemeData(
        color: background,
        elevation: 0,
        shape: _rounded(8, const BorderSide(color: border)),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: _rounded(8),
          textStyle: _font(14, weight: FontWeight.w500),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightNavy,
          textStyle: _font(13, weight: FontWeight.w500),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: _rounded(8),
          textStyle: _font(14, weight: FontWeight.w500),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: _outline(border),
        enabledBorder: _outline(border),
        focusedBorder: _outline(lightNavy, 1.5),
        errorBorder: _outline(error),
        labelStyle: _font(13, color: otherText, weight: FontWeight.w500),
        hintStyle: _font(14, color: otherText),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: subBackground,
        labelStyle: _font(12),
        side: const BorderSide(color: border),
        shape: _rounded(20),
      ),

      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 0),

      listTileTheme: ListTileThemeData(
        tileColor: background,
        shape: _rounded(8),
        titleTextStyle: _font(14, color: mainText, weight: FontWeight.w500),
        subtitleTextStyle: _font(13, color: otherText),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: navy,
        foregroundColor: background,
        elevation: 2,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: midNavy,
        contentTextStyle: _font(14, color: background),
        shape: _rounded(8),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: background,
        shape: _rounded(12),
        titleTextStyle: _font(16, color: navy, weight: FontWeight.w600),
        contentTextStyle: _font(14, color: mainText),
      ),

      dataTableTheme: DataTableThemeData(
        headingTextStyle: _font(12, color: otherText, weight: FontWeight.w600, letterSpacing: 0.5),
        dataTextStyle: _font(14, color: mainText),
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        dividerThickness: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(color: lightNavy),
    );
  }
}

TextStyle _font(double size, {Color? color, FontWeight? weight, double? letterSpacing}) =>
    GoogleFonts.montserrat(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );

RoundedRectangleBorder _rounded(double radius, [BorderSide side = BorderSide.none]) =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: side);

OutlineInputBorder _outline(Color color, [double width = 1]) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: BorderSide(color: color, width: width),
);

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.session != null) {
          // Fire-and-forget so the header badge fills in as soon as there's a session.
          AppServices.of(context).notificationBadge.refresh();
          return const SyncStatusBanner(child: DashboardScreen());
        }
        return const LoginScreen();
      },
    );
  }
}
