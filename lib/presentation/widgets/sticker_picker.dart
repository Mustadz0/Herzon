import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/sticker_constants.dart';

class StickerPicker extends StatefulWidget {
  final ValueChanged<String> onStickerSelected;
  final VoidCallback? onClose;

  const StickerPicker({
    super.key,
    required this.onStickerSelected,
    this.onClose,
  });

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppStickers.categories.length,
                      itemBuilder: (context, index) {
                        final category = AppStickers.categories[index];
                        final isSelected = _selectedCategoryIndex == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategoryIndex = index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF4F46E5).withOpacity(0.1)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? Border.all(color: const Color(0xFF4F46E5))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  category.icon,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: const Color(0xFF94A3B8),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),
          // Sticker grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: AppStickers.categories[_selectedCategoryIndex].stickers.length,
              itemBuilder: (context, index) {
                final sticker = AppStickers.categories[_selectedCategoryIndex].stickers[index];
                return GestureDetector(
                  onTap: () => widget.onStickerSelected(sticker.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          sticker.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        if (sticker.name != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            sticker.name!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: const Color(0xFF94A3B8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
