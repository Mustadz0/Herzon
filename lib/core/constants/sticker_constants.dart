/// Sticker categories and constants for Herzon
class StickerCategory {
  final String id;
  final String name;
  final String icon;
  final List<StickerItem> stickers;

  const StickerCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.stickers,
  });
}

class StickerItem {
  final String id;
  final String emoji;
  final String? name;

  const StickerItem({
    required this.id,
    required this.emoji,
    this.name,
  });
}

class AppStickers {
  AppStickers._();

  static const List<StickerCategory> categories = [
    StickerCategory(
      id: 'herzon',
      name: 'Herzon',
      icon: '🏠',
      stickers: [
        StickerItem(id: 'h1', emoji: '🫂', name: 'Camaraderie'),
        StickerItem(id: 'h2', emoji: '🤝', name: 'Main tendue'),
        StickerItem(id: 'h3', emoji: '💪', name: 'Force'),
        StickerItem(id: 'h4', emoji: '🫡', name: 'Salut'),
        StickerItem(id: 'h5', emoji: '✨', name: 'Brillance'),
        StickerItem(id: 'h6', emoji: '🎉', name: 'Célébration'),
      ],
    ),
    StickerCategory(
      id: 'reactions',
      name: 'Réactions',
      icon: '😊',
      stickers: [
        StickerItem(id: 'r1', emoji: '❤️', name: 'Cœur'),
        StickerItem(id: 'r2', emoji: '🔥', name: 'Feu'),
        StickerItem(id: 'r3', emoji: '👍', name: 'Pouce'),
        StickerItem(id: 'r4', emoji: '😂', name: 'rire'),
        StickerItem(id: 'r5', emoji: '😮', name: 'Wow'),
        StickerItem(id: 'r6', emoji: '😢', name: 'Triste'),
        StickerItem(id: 'r7', emoji: '👏', name: 'Applaudir'),
        StickerItem(id: 'r8', emoji: '🙌', name: 'Joie'),
      ],
    ),
    StickerCategory(
      id: 'nature',
      name: 'Nature',
      icon: '🌍',
      stickers: [
        StickerItem(id: 'n1', emoji: '🌍', name: 'Terre'),
        StickerItem(id: 'n2', emoji: '☀️', name: 'Soleil'),
        StickerItem(id: 'n3', emoji: '🌙', name: 'Lune'),
        StickerItem(id: 'n4', emoji: '⭐', name: 'Étoile'),
        StickerItem(id: 'n5', emoji: '🌈', name: 'Arc-en-ciel'),
        StickerItem(id: 'n6', emoji: '🌸', name: 'Fleur'),
      ],
    ),
    StickerCategory(
      id: 'food',
      name: 'Nourriture',
      icon: '🍕',
      stickers: [
        StickerItem(id: 'f1', emoji: '🍕', name: 'Pizza'),
        StickerItem(id: 'f2', emoji: '☕', name: 'Café'),
        StickerItem(id: 'f3', emoji: '🧋', name: 'Thé'),
        StickerItem(id: 'f4', emoji: '🥐', name: 'Croissant'),
        StickerItem(id: 'f5', emoji: '🍰', name: 'Gâteau'),
        StickerItem(id: 'f6', emoji: '🧁', name: 'Cupcake'),
      ],
    ),
  ];

  static StickerItem? getStickerById(String id) {
    for (final category in categories) {
      for (final sticker in category.stickers) {
        if (sticker.id == id) return sticker;
      }
    }
    return null;
  }
}
