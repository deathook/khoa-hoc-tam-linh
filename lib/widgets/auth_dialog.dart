import 'package:flutter/material.dart';
import '../services/firebase_sync_service.dart';
import '../theme/app_colors.dart';

/// Hiển thị hộp thoại Đăng nhập / Đăng ký / Quản lý tài khoản đồng bộ đám mây
Future<void> showAppAuthDialog(BuildContext context, {bool? isDark, bool? isEnglish}) async {
  final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
  final english = isEnglish ?? false;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AuthDialog(isDark: dark, isEnglish: english),
  );
}

class AuthDialog extends StatefulWidget {
  final bool isDark;
  final bool isEnglish;

  const AuthDialog({
    super.key,
    required this.isDark,
    required this.isEnglish,
  });

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final FirebaseSyncService _sync = FirebaseSyncService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isRegister = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _cleanErrorMessage(Object error) {
    final s = error.toString();
    if (s.contains('user-not-found')) {
      return widget.isEnglish ? 'Account not found with this email.' : 'Không tìm thấy tài khoản với email này.';
    }
    if (s.contains('wrong-password') || s.contains('invalid-credential')) {
      return widget.isEnglish ? 'Incorrect email or password.' : 'Email hoặc mật khẩu không chính xác.';
    }
    if (s.contains('email-already-in-use')) {
      return widget.isEnglish ? 'This email is already registered.' : 'Email này đã được đăng ký trước đó.';
    }
    if (s.contains('weak-password')) {
      return widget.isEnglish ? 'Password should be at least 6 characters.' : 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    if (s.contains('invalid-email')) {
      return widget.isEnglish ? 'Invalid email format.' : 'Định dạng email không hợp lệ.';
    }
    if (s.contains('network-request-failed')) {
      return widget.isEnglish ? 'Network error. Please check your connection.' : 'Lỗi kết nối mạng, vui lòng kiểm tra lại.';
    }
    if (s.contains('popup-closed-by-user')) {
      return widget.isEnglish ? 'Sign-in popup was closed.' : 'Cửa sổ đăng nhập đã bị đóng trước khi hoàn tất.';
    }
    if (s.contains('unauthorized-domain')) {
      return widget.isEnglish
          ? 'Domain not authorized for OAuth. Please add "sach.khoahoctamlinh.vn" to Firebase Console > Authentication > Settings > Authorized domains.'
          : 'Tên miền chưa được cấp phép. Vui lòng thêm "sach.khoahoctamlinh.vn" vào Firebase Console > Authentication > Settings > Authorized domains.';
    }
    return s.replaceAll('Exception: ', '').replaceAll('FirebaseAuthException: ', '');
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final cred = await _sync.signInWithGoogle();
      if (!mounted) return;
      if (cred != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish
                  ? 'Welcome ${cred.user?.displayName ?? ''}! Google Cloud Sync connected.'
                  : 'Chào mừng ${cred.user?.displayName ?? ''}! Đã kết nối đồng bộ Google thành công.',
            ),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(e);
      });
    }
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() {
        _errorMessage = widget.isEnglish
            ? 'Please enter email and password'
            : 'Vui lòng nhập đầy đủ email và mật khẩu';
      });
      return;
    }

    if (_isRegister && pass.length < 6) {
      setState(() {
        _errorMessage = widget.isEnglish
            ? 'Password must be at least 6 characters'
            : 'Mật khẩu phải có ít nhất 6 ký tự';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_isRegister) {
        await _sync.registerWithEmail(
          email,
          pass,
          displayName: _nameController.text.trim(),
        );
      } else {
        await _sync.signInWithEmail(email, pass);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? (_isRegister ? 'Account created & synced!' : 'Signed in successfully!')
                : (_isRegister ? 'Đã tạo tài khoản và đồng bộ thành công!' : 'Đã đăng nhập thành công!'),
          ),
          backgroundColor: AppColors.primaryDark,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(e);
      });
    }
  }

  Future<void> _handleGuestSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _sync.signInAnonymously();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Signed in as Guest. Your notes are syncing!'
                : 'Đã đăng nhập tài khoản Khách. Dữ liệu đang được đồng bộ!',
          ),
          backgroundColor: AppColors.primaryDark,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(e);
      });
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = widget.isEnglish
            ? 'Please enter your email above to receive password reset link.'
            : 'Vui lòng nhập email ở trên để nhận đường dẫn đặt lại mật khẩu.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _sync.sendPasswordResetEmail(email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _successMessage = widget.isEnglish
            ? 'Password reset email sent! Check your inbox.'
            : 'Đã gửi email đặt lại mật khẩu! Vui lòng kiểm tra hộp thư.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isEnglish = widget.isEnglish;
    final isLoggedIn = _sync.isLoggedIn;
    final user = _sync.currentUser;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E2230) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cloud_sync, color: AppColors.primaryDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoggedIn
                      ? (isEnglish ? 'Cloud Account' : 'Tài Khoản Đám Mây')
                      : (_isRegister
                          ? (isEnglish ? 'Create Account' : 'Tạo Tài Khoản Mới')
                          : (isEnglish ? 'Sign In / Sync' : 'Đăng Nhập / Đồng Bộ')),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1B1E28),
                  ),
                ),
                Text(
                  isEnglish ? 'The Science of Spirituality' : 'Sách Khoa Học Tâm Linh',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
            splashRadius: 18,
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: isLoggedIn ? _buildLoggedInView(user!, isDark, isEnglish) : _buildAuthForm(isDark, isEnglish),
        ),
      ),
    );
  }

  /// Giao diện khi người dùng đã đăng nhập thành công
  Widget _buildLoggedInView(dynamic user, bool isDark, bool isEnglish) {
    final photoUrl = user.photoURL as String?;
    final displayName = user.displayName as String? ?? (isEnglish ? 'Spirituality Reader' : 'Độc Giả Sách');
    final email = user.email as String? ?? (user.isAnonymous == true ? (isEnglish ? 'Guest Account' : 'Tài Khoản Khách') : '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.25) : AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.cardDarkBorder : AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withOpacity(0.3),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(Icons.person, size: 28, color: AppColors.primaryDark)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          isEnglish ? 'Cloud Sync Active' : 'Đang tự động đồng bộ',
                          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isEnglish
              ? 'Your reading highlights, notes, bookmarks, and last position are securely synchronized.'
              : 'Đoạn tô màu, ghi chú, dấu trang và vị trí đọc đang được đồng bộ tự động giữa điện thoại và website.',
          style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await _sync.syncLocalToCloud();
                    if (mounted) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEnglish ? 'Data synchronized successfully!' : 'Đã đồng bộ dữ liệu thành công!'),
                          backgroundColor: AppColors.primaryDark,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                        _errorMessage = e.toString();
                      });
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
              : const Icon(Icons.sync, size: 18),
          label: Text(
            isEnglish ? 'Sync Now' : 'Đồng Bộ Ngay',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            await _sync.signOut();
            if (mounted) Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.logout, size: 18),
          label: Text(isEnglish ? 'Sign Out' : 'Đăng Xuất'),
        ),
      ],
    );
  }

  /// Giao diện Form đăng nhập / đăng ký / Google
  Widget _buildAuthForm(bool isDark, bool isEnglish) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        Text(
          isEnglish
              ? 'Sign in to access your highlights and notes across all your devices.'
              : 'Đăng nhập để tự động sao lưu và đồng bộ đoạn tô màu, ghi chú, dấu trang giữa Web và App.',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 16),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_successMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 1. Google Sign-In Button (Prominent & Official)
        InkWell(
          onTap: _isLoading ? null : _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF272C3E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/google_logo.png',
                        width: 22,
                        height: 22,
                        errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24, color: Color(0xFF4285F4)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEnglish ? 'Continue with Google' : 'Đăng nhập bằng tài khoản Google',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF3C4043),
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // 2. OR divider
        Row(
          children: [
            Expanded(child: Divider(color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.12))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                isEnglish ? 'OR WITH EMAIL' : 'HOẶC BẰNG EMAIL',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
              ),
            ),
            Expanded(child: Divider(color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.12))),
          ],
        ),

        const SizedBox(height: 14),

        // 3. Tab Switcher (Sign In vs Register)
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    _isRegister = false;
                    _errorMessage = null;
                    _successMessage = null;
                  }),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isRegister ? (isDark ? const Color(0xFF2C3246) : Colors.white) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: !_isRegister
                          ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isEnglish ? 'Sign In' : 'Đăng Nhập',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: !_isRegister ? FontWeight.bold : FontWeight.normal,
                        color: !_isRegister ? (isDark ? Colors.white : Colors.black87) : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    _isRegister = true;
                    _errorMessage = null;
                    _successMessage = null;
                  }),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isRegister ? (isDark ? const Color(0xFF2C3246) : Colors.white) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _isRegister
                          ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isEnglish ? 'Register' : 'Đăng Ký',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _isRegister ? FontWeight.bold : FontWeight.normal,
                        color: _isRegister ? (isDark ? Colors.white : Colors.black87) : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Name (if registering)
        if (_isRegister) ...[
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: isEnglish ? 'Full Name' : 'Họ và tên hiển thị',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Email field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // Password field
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: isEnglish ? 'Password' : 'Mật khẩu',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),

        if (!_isRegister) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _handleForgotPassword,
              child: Text(
                isEnglish ? 'Forgot password?' : 'Quên mật khẩu?',
                style: const TextStyle(fontSize: 12, color: AppColors.primaryDark),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 14),
        ],

        // Submit Button
        ElevatedButton(
          onPressed: _isLoading ? null : _handleEmailAuth,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                )
              : Text(
                  _isRegister
                      ? (isEnglish ? 'Create Cloud Account' : 'Tạo Tài Khoản Mới')
                      : (isEnglish ? 'Sign In' : 'Đăng Nhập'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
        ),

        const SizedBox(height: 16),

        // Guest Anonymous Button
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _handleGuestSignIn,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.14)),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.flash_on, size: 17, color: Color(0xFFE5B968)),
          label: Text(
            isEnglish ? 'Instant Guest Sync (No password)' : 'Đồng bộ Khách tức thì (Không cần mật khẩu)',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
