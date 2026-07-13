class CheckoutSessionModel {
  final String id;
  final Uri checkoutUri;

  const CheckoutSessionModel({required this.id, required this.checkoutUri});

  factory CheckoutSessionModel.fromJson(Map<String, dynamic> json) {
    final sessionId = _firstString(json, const [
      'id',
      'session_id',
      'checkout_session_id',
    ]);
    final checkoutUrl = _firstString(json, const [
      'url',
      'checkout_url',
      'checkoutUrl',
      'session_url',
    ]);

    if (checkoutUrl == null || checkoutUrl.trim().isEmpty) {
      throw const FormatException(
        'Checkout session response did not include a checkout URL.',
      );
    }

    final uri = Uri.tryParse(checkoutUrl.trim());
    if (uri == null || !uri.hasScheme) {
      throw const FormatException('Checkout session URL is invalid.');
    }

    return CheckoutSessionModel(id: sessionId ?? '', checkoutUri: uri);
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
}
