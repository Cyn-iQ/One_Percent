import 'primary_attribute.dart';

class SecondaryAttribute {
  final int? id;
  final PrimaryAttributeType primaryType;
  final String name;
  final String? description;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SecondaryAttribute({
    this.id,
    required this.primaryType,
    required this.name,
    this.description,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  SecondaryAttribute copyWith({
    int? id,
    PrimaryAttributeType? primaryType,
    String? name,
    String? description,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SecondaryAttribute(
      id: id ?? this.id,
      primaryType: primaryType ?? this.primaryType,
      name: name ?? this.name,
      description: description ?? this.description,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'primaryType': primaryType.key,
      'name': name,
      'description': description,
      'isArchived': isArchived ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SecondaryAttribute.fromMap(Map<String, dynamic> map) {
    return SecondaryAttribute(
      id: map['id'] as int?,
      primaryType: PrimaryAttributeTypeX.fromKey(map['primaryType'] as String),
      name: map['name'] as String,
      description: map['description'] as String?,
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}