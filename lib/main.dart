import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'routes/seo_router.dart';
import 'services/book_repository.dart';
import 'services/seo/seo_service.dart';
import 'services/storage_service.dart';
import 'services/tts_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/main_nav_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  SeoService.init();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize storage
  final storage = StorageService();
  await storage.init();

  runApp(const KhoaHocTamLinhApp());
}

class KhoaHocTamLinhApp extends StatefulWidget {
  const KhoaHocTamLinhApp({Key? key}) : super(key: key);

  @override
  State<KhoaHocTamLinhApp> createState() => _KhoaHocTamLinhAppState();
}

class _KhoaHocTamLinhAppState extends State<KhoaHocTamLinhApp> {
  final StorageService _storage = StorageService();
  final BookRepository _repo = BookRepository();
  bool _isLoading = true;
  ParsedSeoRoute? _initialRoute;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _repo.loadData();
    await TtsService().init();

    // Check deep link URL on initial page load
    final currentPath = SeoService.getCurrentPath();
    final parsed = SeoRouter.parsePath(currentPath);
    _initialRoute = parsed;

    if (parsed.isEnglish != _storage.isEnglish) {
      await _storage.setIsEnglish(parsed.isEnglish);
      await TtsService().setLanguage(parsed.isEnglish);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: AppColors.lightBg,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/image1.jpg',
                    width: 120,
                    height: 160,
                    fit: BoxFit.cover,
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
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: _storage.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Khoa Học Tâm Linh',
          debugShowCheckedModeBanner: false,
          theme: _getThemeForMode(themeMode),
          home: MainNavScreen(
            onThemeChanged: _onThemeChanged,
            initialTabIndex: _initialRoute?.tabIndex ?? 0,
            initialSectionId: _initialRoute?.sectionId,
          ),
        );
      },
    );
  }
}
