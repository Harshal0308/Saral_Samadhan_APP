import 'package:sembast/sembast.dart';

enum SyncOperation {
  create,
  update,
  delete,
}

enum SyncStatus {
  pending,
  inProgress,
  completed,
  failed,
}

enum SyncEntityType {
  student,
  attendance,
  volunteerReport,
}

class SyncQueueItem {
  final int id;
  final SyncEntityType entityType;
  final SyncOperation operation;
  final int entityId; // ID of the student/attendance/report
  final Map<String, dynamic> data; // The actual data to sync
  final String centerName;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int attemptCount;
  final SyncStatus status;
  final String? errorMessage;

  SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.entityId,
    required this.data,
    required this.centerName,
    required this.createdAt,
    this.lastAttemptAt,
    this.attemptCount = 0,
    this.status = SyncStatus.pending,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'entityType': entityType.name,
      'operation': operation.name,
      'entityId': entityId,
      'data': data,
      'centerName': centerName,
      'createdAt': createdAt.toIso8601String(),
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'attemptCount': attemptCount,
      'status': status.name,
      'errorMessage': errorMessage,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map, int id) {
    return SyncQueueItem(
      id: id,
      entityType: SyncEntityType.values.firstWhere(
        (e) => e.name == map['entityType'],
      ),
      operation: SyncOperation.values.firstWhere(
        (e) => e.name == map['operation'],
      ),
      entityId: map['entityId'] as int,
      data: Map<String, dynamic>.from(map['data']),
      centerName: map['centerName'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastAttemptAt: map['lastAttemptAt'] != null
          ? DateTime.parse(map['lastAttemptAt'] as String)
          : null,
      attemptCount: map['attemptCount'] as int? ?? 0,
      status: SyncStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SyncStatus.pending,
      ),
      errorMessage: map['errorMessage'] as String?,
    );
  }

  SyncQueueItem copyWith({
    SyncStatus? status,
    DateTime? lastAttemptAt,
    int? attemptCount,
    String? errorMessage,
  }) {
    return SyncQueueItem(
      id: id,
      entityType: entityType,
      operation: operation,
      entityId: entityId,
      data: data,
      centerName: centerName,
      createdAt: createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      attemptCount: attemptCount ?? this.attemptCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
