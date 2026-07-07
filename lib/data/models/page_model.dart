// â”€â”€â”€ PageModel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Represents a public or private page / organisation profile.
class PageModel {
  final String   id;
  final String   ownerId;
  final String   name;
  final String   slug;
  final String   category;
  final String?  description;
  final String?  avatarUrl;
  final String?  bannerUrl;
  final String?  contactEmail;
  final String?  contactPhone;
  final String?  websiteUrl;
  final double?  latitude;
  final double?  longitude;
  final String?  address;
  final bool     isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PageModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.slug,
    required this.category,
    this.description,
    this.avatarUrl,
    this.bannerUrl,
    this.contactEmail,
    this.contactPhone,
    this.websiteUrl,
    this.latitude,
    this.longitude,
    this.address,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id:           json['id']           as String,
      ownerId:      json['owner_id']     as String,
      name:         json['name']         as String,
      slug:         json['slug']         as String,
      category:     json['category']     as String,
      description:  json['description']  as String?,
      avatarUrl:    json['avatar_url']   as String?,
      bannerUrl:    json['banner_url']   as String?,
      contactEmail: json['contact_email']as String?,
      contactPhone: json['contact_phone']as String?,
      websiteUrl:   json['website_url']  as String?,
      latitude:     (json['latitude']   as num?)?.toDouble(),
      longitude:    (json['longitude']  as num?)?.toDouble(),
      address:      json['address']      as String?,
      isActive:     json['is_active']    as bool,
      createdAt:    DateTime.parse(json['created_at'] as String),
      updatedAt:    DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id':            id,
    'owner_id':      ownerId,
    'name':          name,
    'slug':          slug,
    'category':      category,
    'description':   description,
    'avatar_url':    avatarUrl,
    'banner_url':    bannerUrl,
    'contact_email': contactEmail,
    'contact_phone': contactPhone,
    'website_url':   websiteUrl,
    'latitude':      latitude,
    'longitude':     longitude,
    'address':       address,
    'is_active':     isActive,
    'created_at':    createdAt.toIso8601String(),
    'updated_at':    updatedAt.toIso8601String(),
  };
}

// â”€â”€â”€ PageMemberModel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Represents a user's membership in a page.
class PageMemberModel {
  final String    id;
  final String    pageId;
  final String    userId;
  final String    role;      // e.g. 'admin', 'moderator', 'member'
  final DateTime  joinedAt;

  const PageMemberModel({
    required this.id,
    required this.pageId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  factory PageMemberModel.fromJson(Map<String, dynamic> json) => PageMemberModel(
    id:       json['id']       as String,
    pageId:   json['page_id']  as String,
    userId:   json['user_id']  as String,
    role:     json['role']     as String,
    joinedAt: DateTime.parse(json['joined_at'] as String),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id':        id,
    'page_id':   pageId,
    'user_id':   userId,
    'role':      role,
    'joined_at': joinedAt.toIso8601String(),
  };
}
