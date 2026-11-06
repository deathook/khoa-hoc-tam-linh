import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quote_item.dart';
import '../theme/app_colors.dart';

class QuoteCardDialog extends StatelessWidget {
  final QuoteItem quote;
  final bool isEnglish;

  const QuoteCardDialog({Key? key, required this.quote, this.isEnglish = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final quoteText = quote.getText(isEnglish);
    final sourceText = quote.getSource(isEnglish);
    final appTitle = isEnglish ? 'THE SCIENCE OF SPIRITUALITY' : 'KHOA HỌC TÂM LINH';
    final authorText = isEnglish ? 'Author: Hoang Nhat Minh' : 'Tác giả: Hoàng Nhật Minh';
    final shareClipboardText = isEnglish
        ? '$quoteText\n\n— Excerpt from "The Science of Spirituality" by Hoang Nhat Minh (https://khoahoctamlinh.vn)'
        : '$quoteText\n\n— Trích sách "Khoa Học Tâm Linh" - Tác giả Hoàng Nhật Minh (https://khoahoctamlinh.vn)';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C313E), Color(0xFF191C24)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top branding
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  appTitle,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quote text
            Text(
              quoteText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFAF6EE),
                fontSize: 17,
                height: 1.6,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),

            // Divider
            Container(
              width: 50,
              height: 2,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),

            // Author & Source
            Text(
              authorText,
              style: const TextStyle(
                color: Color(0xFFE0D8C8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sourceText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shareClipboardText));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEnglish ? 'Quote copied to clipboard!' : 'Đã sao chép trích dẫn vào bộ nhớ tạm!')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                  label: Text(
                    isEnglish ? 'Copy' : 'Sao Chép',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(isEnglish ? 'Close' : 'Đóng'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
