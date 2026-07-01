// Modelo puro, sin dependencias de UI

class Subscription {
  final String id;
  final String studentName;
  final String? avatarUrl;
  final String? planId;
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
    this.planId,
    required this.planName,
    required this.price,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  Subscription copyWith({
    String? id,
    String? studentName,
    String? avatarUrl,
    String? planId,
    String? planName,
    double? price,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    return Subscription(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final profileRaw = json['profiles'];
    final profile = (profileRaw is List ? profileRaw.firstOrNull : profileRaw) as Map? ?? {};
    final planRaw = json['plans'];
    final plan = (planRaw is List ? planRaw.firstOrNull : planRaw) as Map? ?? {};

    return Subscription(
      id: json['id'] ?? '',
      studentName: profile['full_name'] ?? 'Desconocido',
      avatarUrl: profile['avatar_url'],
      planId: json['plan_id'] ?? plan['id'],
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
    final parts = studentName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1);
    return parts[0].substring(0, 1) + parts[1].substring(0, 1);
  }

  // UI: avatarColor was removed. Calculate in UI.

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'ACTIVO';
      case 'pending':
        return 'PENDIENTE';
      case 'expired':
        return 'VENCIDO';
      case 'cancelled':
        return 'CANCELADO';
      default:
        return status.toUpperCase();
    }
  }

  // UI: statusColor and statusBgColor were removed. Calculate in UI.

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
