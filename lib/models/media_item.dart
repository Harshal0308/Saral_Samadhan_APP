class MediaItem {
  final int id;
  final String? title;
  final String? description;
  final String photoUrl;
  final String? localPath;
  final String centerName;
  final String? uploadedBy;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MediaItem({
    required this.id,
    this.title,
    this.description,
    required this.photoUrl,
    this.localPath,
    required this.centerName,
    this.uploadedBy,
    this.isSynced = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory MediaItem.fromMap(Map<String, dynamic> map, int id) {
    return MediaItem(
      id: id,
      title: map['title'] as String?,
      description: map['description'] as String?,
      photoUrl: (map['photoUrl'] ?? map['photo_url'] ?? '') as String,
      localPath: (map['localPath'] ?? map['local_path']) as String?,
      centerName: (map['centerName'] ?? map['center_name'] ?? '') as String,
      uploadedBy: (map['uploadedBy'] ?? map['uploaded_by']) as String?,
      isSynced: (map['isSynced'] ?? map['is_synced'] ?? false) as bool,
      createdAt: _parseDate(map['createdAt'] ?? map['created_at']),
      updatedAt: _parseDateNullable(map['updatedAt'] ?? map['updated_at']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.parse(value.toString());
  }

  static DateTime? _parseDateNullable(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value.toString());
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'photoUrl': photoUrl,
      'localPath': localPath,
      'centerName': centerName,
      'uploadedBy': uploadedBy,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  MediaItem copyWith({
    int? id,
    String? title,
    String? description,
    String? photoUrl,
    String? localPath,
    String? centerName,
    String? uploadedBy,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      localPath: localPath ?? this.localPath,
      centerName: centerName ?? this.centerName,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
