class SubscriptionModel {
  final bool isActive;
  final String status;
  final DateTime? currentPeriodEnd;

  const SubscriptionModel({
    required this.isActive,
    required this.status,
    this.currentPeriodEnd,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final status =
        _firstString(json, const [
          'status',
          'subscription_status',
          'stripe_status',
        ]) ??
        '';
    final isActiveValue =
        json['is_active'] ?? json['active'] ?? json['has_active_subscription'];

    return SubscriptionModel(
      isActive: isActiveValue is bool
          ? isActiveValue
          : const {'active', 'trialing'}.contains(status.toLowerCase()),
      status: status.isEmpty ? 'inactive' : status,
      currentPeriodEnd: _parseDate(json['current_period_end']),
    );
  }

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
