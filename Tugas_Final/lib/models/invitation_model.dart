import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  cancelled('cancelled');

  const InvitationStatus(this.value);
  final String value;

  static InvitationStatus fromString(String? raw) {
    return InvitationStatus.values.firstWhere(
      (item) => item.value == raw,
      orElse: () => InvitationStatus.pending,
    );
  }
}

class InvitationModel {
  const InvitationModel({
    required this.id,
    required this.bookingId,
    required this.senderId,
    this.senderName,
    required this.recipientIdentifier,
    this.courtName,
    this.scheduleLabel,
    this.status = InvitationStatus.pending,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String senderId;
  final String? senderName;
  final String recipientIdentifier;
  final String? courtName;
  final String? scheduleLabel;
  final InvitationStatus status;
  final DateTime createdAt;

  InvitationModel copyWith({InvitationStatus? status}) {
    return InvitationModel(
      id: id,
      bookingId: bookingId,
      senderId: senderId,
      senderName: senderName,
      recipientIdentifier: recipientIdentifier,
      courtName: courtName,
      scheduleLabel: scheduleLabel,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  factory InvitationModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return InvitationModel(
      id: id,
      bookingId: (map['bookingId'] as String?) ?? '',
      senderId: (map['senderId'] as String?) ?? '',
      senderName: map['senderName'] as String?,
      recipientIdentifier: (map['recipientIdentifier'] as String?) ?? '',
      courtName: map['courtName'] as String?,
      scheduleLabel: map['scheduleLabel'] as String?,
      status: InvitationStatus.fromString(map['status'] as String?),
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.relatedId,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedId;

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      relatedId: relatedId,
    );
  }

  factory NotificationModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return NotificationModel(
      id: id,
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'general',
      isRead: (map['isRead'] as bool?) ?? false,
      createdAt: _parseDateTime(map['createdAt']),
      relatedId: map['relatedId'] as String?,
    );
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
