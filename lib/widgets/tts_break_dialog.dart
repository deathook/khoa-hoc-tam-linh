import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

/// Hiển thị hộp thoại Thiết lập ngắt nghỉ cho giọng đọc TTS
Future<void> showTtsBreakDialog(
  BuildContext context, {
  bool? isDark,
  bool? isEnglish,
  VoidCallback? onSaved,
}) async {
  final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
  final english = isEnglish ?? false;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => TtsBreakDialog(
      isDark: dark,
      isEnglish: english,
      onSaved: onSaved,
    ),
  );
}

class TtsBreakDialog extends StatefulWidget {
  final bool isDark;
  final bool isEnglish;
  final VoidCallback? onSaved;

  const TtsBreakDialog({
    super.key,
    required this.isDark,
    required this.isEnglish,
    this.onSaved,
  });

  @override
  State<TtsBreakDialog> createState() => _TtsBreakDialogState();
}

class _TtsBreakDialogState extends State<TtsBreakDialog> {
  final StorageService _storage = StorageService();

  late double _breakPeriod;
  late double _breakComma;
  late double _breakSemicolon;
  late double _breakParagraph;

  @override
  void initState() {
    super.initState();
    _breakPeriod = _storage.ttsBreakPeriod;
    _breakComma = _storage.ttsBreakComma;
    _breakSemicolon = _storage.ttsBreakSemicolon;
    _breakParagraph = _storage.ttsBreakParagraph;
  }

  void _resetDefaults() {
    setState(() {
      _breakPeriod = StorageService.defaultBreakPeriod;
      _breakComma = StorageService.defaultBreakComma;
      _breakSemicolon = StorageService.defaultBreakSemicolon;
      _breakParagraph = StorageService.defaultBreakParagraph;
    });
  }

  Future<void> _saveSettings() async {
    await _storage.setTtsBreakPeriod(_breakPeriod);
    await _storage.setTtsBreakComma(_breakComma);
    await _storage.setTtsBreakSemicolon(_breakSemicolon);
    await _storage.setTtsBreakParagraph(_breakParagraph);

    if (!mounted) return;
    Navigator.pop(context);

    if (widget.onSaved != null) {
      widget.onSaved!();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEnglish
              ? 'Pause settings saved successfully!'
              : 'Đã lưu thiết lập thời gian ngắt nghỉ thành công!',
        ),
        backgroundColor: AppColors.primaryDark,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildBreakControl({
    required String label,
    required String symbol,
    required double value,
    required ValueChanged<double> onChanged,
    String? subLabel,
  }) {
    final isDark = widget.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232838) : const Color(0xFFF9F7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              symbol,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (subLabel != null)
                  Text(
                    subLabel,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Stepper: [-] [ 0.55s ] [+]
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // [-]
                InkWell(
                  onTap: () {
                    final next = (value - 0.05).clamp(0.05, 3.0);
                    onChanged(double.parse(next.toStringAsFixed(2)));
                  },
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: const Text('−', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                Container(
                  width: 58,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                    border: Border.symmetric(
                      vertical: BorderSide(
                        color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.12),
                      ),
                    ),
                  ),
                  child: Text(
                    '${value.toStringAsFixed(2)}s',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFFE5B968) : AppColors.primaryDark,
                    ),
                  ),
                ),
                // [+]
                InkWell(
                  onTap: () {
                    final next = (value + 0.05).clamp(0.05, 3.0);
                    onChanged(double.parse(next.toStringAsFixed(2)));
                  },
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: const Text('+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isEnglish = widget.isEnglish;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1B1E28) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
      titlePadding: const EdgeInsets.fromLTRB(22, 18, 16, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.timer_outlined, color: AppColors.primaryDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEnglish ? 'Pause & Break Settings' : 'Thiết lập ngắt nghỉ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1B1E28),
              ),
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
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEnglish
                    ? 'Adjust the natural pause duration at punctuation marks and paragraphs for audiobook reading.'
                    : 'Tùy chỉnh thời gian nghỉ tự nhiên theo từng dấu câu và đoạn văn khi nghe giọng đọc TTS.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 18),

              // 1. Dấu chấm
              _buildBreakControl(
                label: isEnglish ? 'Period' : 'Dấu chấm',
                symbol: '.',
                subLabel: '. ! ? …',
                value: _breakPeriod,
                onChanged: (v) => setState(() => _breakPeriod = v),
              ),
              const SizedBox(height: 10),

              // 2. Dấu phẩy
              _buildBreakControl(
                label: isEnglish ? 'Comma' : 'Dấu phẩy',
                symbol: ',',
                subLabel: ', 、',
                value: _breakComma,
                onChanged: (v) => setState(() => _breakComma = v),
              ),
              const SizedBox(height: 10),

              // 3. Dấu chấm phẩy & Dấu gạch ngang (Tương đương nhau theo yêu cầu)
              _buildBreakControl(
                label: isEnglish ? 'Semicolon & Dash' : 'Dấu chấm phẩy & Gạch ngang',
                symbol: '; -',
                subLabel: isEnglish ? '; and - are equal' : '; và - tương đương nhau',
                value: _breakSemicolon,
                onChanged: (v) => setState(() => _breakSemicolon = v),
              ),
              const SizedBox(height: 10),

              // 4. Xuống dòng / Sang đoạn
              _buildBreakControl(
                label: isEnglish ? 'Paragraph Break' : 'Xuống dòng / Sang đoạn',
                symbol: '⏎',
                subLabel: isEnglish ? 'Between paragraphs' : 'Nghỉ giữa các đoạn văn',
                value: _breakParagraph,
                onChanged: (v) => setState(() => _breakParagraph = v),
              ),

              const SizedBox(height: 16),

              // Note
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.25) : AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEnglish
                            ? 'Tip: Semicolon (;) and dash (-) have equal pause length. Adjusting them applies to both Web and App.'
                            : 'Mẹo: Dấu chấm phẩy (;) và dấu gạch ngang (-) được cài đặt thời gian ngắt nghỉ bằng nhau.',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.4,
                          color: isDark ? AppColors.textLightMuted : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Actions: [ Đặt mặc định ] [ Lưu ]
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetDefaults,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark ? AppColors.cardDarkBorder : Colors.black.withOpacity(0.18),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isEnglish ? 'Reset Default' : 'Đặt mặc định',
                        style: TextStyle(
                          color: isDark ? AppColors.textLight : AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFFE5B968) : AppColors.primary,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isEnglish ? 'Save' : 'Lưu',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
