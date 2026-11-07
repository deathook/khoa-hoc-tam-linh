import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'routes/seo_router.dart';
import 'services/book_repository.dart';
import 'services/seo/seo_service.dart';
import 'services/storage_service.dart';
import 'services/tts_service.dart';
import 'services/firebase_sync_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/main_nav_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  SeoService.init();

  // Capture the browser's incoming URL IMMEDIATELY on load/F5 before any Flutter widget mounts!
  final initialPath = SeoService.getCurrentPath();
  final initialRoute = SeoRouter.parsePath(initialPath);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize storage & firebase sync
  final storage = StorageService();
  await storage.init();
  await FirebaseSyncService().init();

  runApp(KhoaHocTamLinhApp(initialRoute: initialRoute));
}

class KhoaHocTamLinhApp extends StatefulWidget {
  final ParsedSeoRoute? initialRoute;

  const KhoaHocTamLinhApp({Key? key, this.initialRoute}) : super(key: key);

  @override
  State<KhoaHocTamLinhApp> createState() => _KhoaHocTamLinhAppState();
}

class _KhoaHocTamLinhAppState extends State<KhoaHocTamLinhApp> {
  final StorageService _storage = StorageService();
  final BookRepository _repo = BookRepository();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _repo.loadData();
    await TtsService().init();

    final route = widget.initialRoute;
    if (route != null && route.isEnglish != _storage.isEnglish) {
      await _storage.setIsEnglish(route.isEnglish);
      await TtsService().setLanguage(route.isEnglish);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onThemeChanged() {
    setState(() {});
  }

  ThemeData _getThemeForMode(String mode) {
    if (mode == 'sepia') return AppTheme.sepiaTheme;
    if (mode == 'dark') return AppTheme.darkTheme;
    return AppTheme.lightTheme;
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(54),
                child: Image.asset(
                  'assets/images/app_logo_circle.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'KHOA HỌC TÂM LINH',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hoàng Nhật Minh',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _storage.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Khoa Học Tâm Linh',
          debugShowCheckedModeBanner: false,
          theme: _getThemeForMode(themeMode),
          home: _isLoading
              ? _buildSplashScreen()
              : MainNavScreen(
                  onThemeChanged: _onThemeChanged,
                  initialTabIndex: widget.initialRoute?.tabIndex ?? 0,
                  initialSectionId: widget.initialRoute?.sectionId,
                  initialParagraphIndex: widget.initialRoute?.paragraphIndex ?? -1,
                ),
        );
      },
    );
  }
}
