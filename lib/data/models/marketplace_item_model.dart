class MarketplaceItemModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double? price;
  final String currency;
  final String category;
  final List<String> images;
  final String status;
  final DateTime? createdAt;

  final String? userUsername;
  final String? userDisplayName;
  final String? userAvatarUrl;
  final double distanceMeters;

  const MarketplaceItemModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.price,
    this.currency = 'DZD',
    required this.category,
    this.images = const [],
    this.status = 'active',
    this.createdAt,
    this.userUsername,
    this.userDisplayName,
    this.userAvatarUrl,
    this.distanceMeters = 0.0,
  });

  factory MarketplaceItemModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'DZD',
      category: json['item_category'] as String? ?? json['category'] as String? ?? '',
      images: List<String>.from(json['images'] ?? []),
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      userUsername: json['username'] as String?,
      userDisplayName: json['display_name'] as String?,
      userAvatarUrl: json['avatar_url'] as String?,
      distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

const marketplaceCategories = [
  'Tout',
  'Vetements',
  'Electronique',
  'Meubles',
  'Vehicules',
  'Immobilier',
  'Services',
  'Emplois',
  'Animaux',
  'Loisirs',
  'Autre',
];
