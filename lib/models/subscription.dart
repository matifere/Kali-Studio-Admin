import 'package:flutter/material.dart';

class Subscription {
  final String id;
  final String studentName;
  final String? avatarUrl;
  final String planName;
  final double price;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  const Subscription({
    required this.id,
    required this.studentName,
    this.avatarUrl,
    required this.planName,
    required this.price,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] ?? {};
    final plan = json['plans'] ?? {};

    return Subscription(
      id: json['id'] ?? '',
      studentName: profile['full_name'] ?? 'Desconocido',
      avatarUrl: profile['avatar_url'],
      planName: plan['name'] ?? 'Sin plan',
      price: (plan['price'] as num?)?.toDouble() ?? 0.0,
      currency: plan['currency'] ?? 'ARS',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date']) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date']) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] ?? 'pending',
    );
  }

  String get studentInitials {
    if (studentName.split(" ").length <= 1) {
      if (studentName.isEmpty) return "";
      return studentName.substring(0, 1);
    }
    return studentName.split(' ')[0].substring(0, 1) +
        studentName.split(' ')[1].substring(0, 1);
  }

  Color get avatarColor {
    List<Color> colores = [Colors.grey, Colors.brown, Colors.white];
    return colores[studentName.length % colores.length];
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'ACTIVO';
      case 'pending':
        return 'PENDIENTE';
      case 'overdue':
        return 'VENCIDO';
      case 'canceled':
        return 'CANCELADO';
      default:
        return status.toUpperCase();
    }
  }

  Color get statusColor {
    switch (status) {
      case 'active':
        return const Color(0xFF5C9E6C);
      case 'pending':
        return const Color(0xFFD4A836);
      case 'overdue':
      case 'canceled':
        return const Color(0xFFD4685C);
      default:
        return Colors.grey;
    }
  }

  Color get statusBgColor {
    switch (status) {
      case 'active':
        return const Color(0xFFE8F5E9);
      case 'pending':
        return const Color(0xFFFFF8E1);
      case 'overdue':
      case 'canceled':
        return const Color(0xFFFDECEA);
      default:
        return Colors.grey.withValues(alpha: 0.2);
    }
  }

  String get startDateFormatted =>
      '${startDate.day.toString().padLeft(2, '0')} ${_monthAbbr(startDate.month)} ${startDate.year}';

  String get endDateFormatted =>
      '${endDate.day.toString().padLeft(2, '0')} ${_monthAbbr(endDate.month)} ${endDate.year}';

  String _monthAbbr(int month) {
    const months = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return month >= 1 && month <= 12 ? months[month] : '';
  }

  String get amountFormatted => '\$${price.toStringAsFixed(2)} $currency';
}
