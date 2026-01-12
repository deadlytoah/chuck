class Item {
  final String itemId;
  final String folderId;
  final String imageUrl;
  final String state;
  final String? notes;
  final bool archived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Item({
    required this.itemId,
    required this.folderId,
    required this.imageUrl,
    required this.state,
    this.notes,
    required this.archived,
    this.createdAt,
    this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemId: json['itemId'] as String,
      folderId: json['folderId'] as String,
      imageUrl: json['imageUrl'] as String,
      state: json['state'] as String,
      notes: json['notes'] as String?,
      archived: json['archived'].toString() == 'true',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'folderId': folderId,
      'imageUrl': imageUrl,
      'state': state,
      'notes': notes,
      'archived': archived,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Item copyWith({
    String? itemId,
    String? folderId,
    String? imageUrl,
    String? state,
    String? notes,
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      itemId: itemId ?? this.itemId,
      folderId: folderId ?? this.folderId,
      imageUrl: imageUrl ?? this.imageUrl,
      state: state ?? this.state,
      notes: notes ?? this.notes,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get thumbnailUrl {
    return imageUrl.replaceAll('/full.jpg', '/thumb.jpg');
  }
}

class ItemsResponse {
  final List<Item> items;
  final String? nextToken;

  ItemsResponse({required this.items, this.nextToken});

  factory ItemsResponse.fromJson(Map<String, dynamic> json) {
    return ItemsResponse(
      items: (json['data'] as List)
          .map((item) => Item.fromJson(item as Map<String, dynamic>))
          .toList(),
      nextToken: json['nextToken'] as String?,
    );
  }
}
