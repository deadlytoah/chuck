class Folder {
  final String folderId;
  final String name;
  final DateTime? createdAt;

  Folder({
    required this.folderId,
    required this.name,
    this.createdAt,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      folderId: json['folderId'] as String,
      name: json['name'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folderId': folderId,
      'name': name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Folder copyWith({
    String? folderId,
    String? name,
    DateTime? createdAt,
  }) {
    return Folder(
      folderId: folderId ?? this.folderId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FoldersResponse {
  final List<Folder> folders;

  FoldersResponse({required this.folders});

  factory FoldersResponse.fromJson(Map<String, dynamic> json) {
    return FoldersResponse(
      folders: (json['data'] as List)
          .map((folder) => Folder.fromJson(folder as Map<String, dynamic>))
          .toList(),
    );
  }
}
