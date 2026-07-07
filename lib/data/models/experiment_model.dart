// â”€â”€â”€ ExperimentVariant â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// A single variant inside an A/B experiment.
class ExperimentVariant {
  final String   name;
  final dynamic  value;
  final double   weight;

  const ExperimentVariant({
    required this.name,
    required this.value,
    this.weight = 1.0,
  });

  factory ExperimentVariant.fromJson(Map<String, dynamic> json) => ExperimentVariant(
    name:   json['name']  as String,
    value:  json['value'],
    weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name':   name,
    'value':  value,
    'weight': weight,
  };
}

// â”€â”€â”€ ExperimentModel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Describes an A/B experiment with multiple variants.
class ExperimentModel {
  final String             id;
  final String             name;
  final String?            description;
  final List<ExperimentVariant> variants;
  final bool               isActive;
  final DateTime?          startDate;
  final DateTime?          endDate;

  const ExperimentModel({
    required this.id,
    required this.name,
    this.description,
    this.variants = const [],
    required this.isActive,
    this.startDate,
    this.endDate,
  });

  factory ExperimentModel.fromJson(Map<String, dynamic> json) => ExperimentModel(
    id:          json['id']           as String,
    name:        json['name']         as String,
    description: json['description']  as String?,
    variants:    (json['variants'] as List<dynamic>? ?? [])
                    .map((v) => ExperimentVariant.fromJson(v as Map<String, dynamic>))
                    .toList(),
    isActive:    json['is_active']    as bool,
    startDate:   json['start_date'] != null
                    ? DateTime.parse(json['start_date'] as String)
                    : null,
    endDate:     json['end_date'] != null
                    ? DateTime.parse(json['end_date']   as String)
                    : null,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id':          id,
    'name':        name,
    'description': description,
    'variants':    variants.map((v) => v.toJson()).toList(),
    'is_active':   isActive,
    'start_date':  startDate?.toIso8601String(),
    'end_date':    endDate?.toIso8601String(),
  };
}

// â”€â”€â”€ ExperimentAssignmentModel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Maps a user to an experiment variant.
class ExperimentAssignmentModel {
  final String    id;
  final String    userId;
  final String    experimentId;
  final String    variantName;
  final DateTime  createdAt;

  const ExperimentAssignmentModel({
    required this.id,
    required this.userId,
    required this.experimentId,
    required this.variantName,
    required this.createdAt,
  });

  factory ExperimentAssignmentModel.fromJson(Map<String, dynamic> json) => ExperimentAssignmentModel(
    id:          json['id']           as String,
    userId:      json['user_id']      as String,
    experimentId:json['experiment_id']as String,
    variantName: json['variant_name'] as String,
    createdAt:   DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id':            id,
    'user_id':       userId,
    'experiment_id': experimentId,
    'variant_name':  variantName,
    'created_at':    createdAt.toIso8601String(),
  };
}

// â”€â”€â”€ FeatureConfigModel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Runtime feature flag / config storage.
class FeatureConfigModel {
  final String              id;
  final String              key;
  final Map<String, dynamic> value;
  final String?             description;
  final DateTime            updatedAt;

  const FeatureConfigModel({
    required this.id,
    required this.key,
    this.value = const {},
    this.description,
    required this.updatedAt,
  });

  factory FeatureConfigModel.fromJson(Map<String, dynamic> json) => FeatureConfigModel(
    id:          json['id']          as String,
    key:         json['key']         as String,
    value:       (json['value'] as Map<String, dynamic>?) ?? {},
    description: json['description'] as String?,
    updatedAt:   DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id':          id,
    'key':         key,
    'value':       value,
    'description': description,
    'updated_at':  updatedAt.toIso8601String(),
  };
}
