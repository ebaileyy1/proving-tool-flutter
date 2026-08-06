import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proving_tool/config.dart';
import 'package:proving_tool/screens/auth/login_screen.dart';
import 'package:proving_tool/screens/dashboard/dashboard_screen.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/services/connectivity_service.dart';
import 'package:proving_tool/services/local_db.dart';
import 'package:proving_tool/services/sync_service.dart';
import 'package:proving_tool/services/trial_repository.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/widgets/sync_status_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

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

  runApp(MyApp(
    trialRepository: trialRepository,
    syncService: syncService,
    connectivity: connectivity,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.trialRepository,
    required this.syncService,
    required this.connectivity,
  });

  final TrialRepository trialRepository;
  final SyncService syncService;
  final ConnectivityService connectivity;

  @override
  Widget build(BuildContext context) {
    return AppServices(
      trialRepository: trialRepository,
      syncService: syncService,
      connectivity: connectivity,
      child: MaterialApp(
        title: 'Proving Tool',
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
        bodyLarge: GoogleFonts.montserrat(color: mainText, fontSize: 15),
        bodyMedium: GoogleFonts.montserrat(color: mainText, fontSize: 14),
        bodySmall: GoogleFonts.montserrat(color: otherText, fontSize: 13),
        titleLarge: GoogleFonts.montserrat(color: navy, fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.montserrat(color: navy, fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.montserrat(color: navy, fontSize: 15, fontWeight: FontWeight.w600),
        labelLarge: GoogleFonts.montserrat(color: background, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );

    return base.copyWith(
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: navy,
        foregroundColor: background,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        titleTextStyle: GoogleFonts.montserrat(
          color: background,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: background),
        actionsIconTheme: const IconThemeData(color: background),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated buttons (primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightNavy,
          textStyle: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightNavy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: GoogleFonts.montserrat(color: otherText, fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.montserrat(color: otherText, fontSize: 14),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: subBackground,
        labelStyle: GoogleFonts.montserrat(fontSize: 12),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 0,
      ),

      // List tiles
      listTileTheme: ListTileThemeData(
        tileColor: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titleTextStyle: GoogleFonts.montserrat(color: mainText, fontSize: 14, fontWeight: FontWeight.w500),
        subtitleTextStyle: GoogleFonts.montserrat(color: otherText, fontSize: 13),
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: navy,
        foregroundColor: background,
        elevation: 2,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: midNavy,
        contentTextStyle: GoogleFonts.montserrat(color: background, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: GoogleFonts.montserrat(color: navy, fontSize: 16, fontWeight: FontWeight.w600),
        contentTextStyle: GoogleFonts.montserrat(color: mainText, fontSize: 14),
      ),

      // DataTable
      dataTableTheme: DataTableThemeData(
        headingTextStyle: GoogleFonts.montserrat(
          color: otherText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        dataTextStyle: GoogleFonts.montserrat(color: mainText, fontSize: 14),
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        dividerThickness: 1,
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: lightNavy,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.session != null) {
          return const SyncStatusBanner(child: DashboardScreen());
        }
        return const LoginScreen();
      },
    );
  }
}