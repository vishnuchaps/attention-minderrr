import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/payments/data/model/checkout_session_model.dart';
import 'package:attention_minder/module/payments/data/model/subscription_model.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentRepository {
  PaymentRepository({Dio? dio, SharedPreferences? preferences})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          ),
      _preferences = preferences;

  final Dio _dio;
  final SharedPreferences? _preferences;

  Future<CheckoutSessionModel> createCheckoutSession() async {
    try {
      final response = await _postCheckoutSession();

      return CheckoutSessionModel.fromJson(_responseMap(response.data));
    } on DioException catch (error) {
      if (_canRetryCheckoutWithoutReturnUrls(error)) {
        try {
          final response = await _postCheckoutSession();
          return CheckoutSessionModel.fromJson(_responseMap(response.data));
        } on DioException catch (fallbackError) {
          throw PaymentException(_messageFromDio(fallbackError));
        } on FormatException catch (fallbackError) {
          throw PaymentException(fallbackError.message);
        }
      }

      throw PaymentException(_messageFromDio(error));
    } on FormatException catch (error) {
      throw PaymentException(error.message);
    }
  }

  Future<Response<dynamic>> _postCheckoutSession({
    Map<String, dynamic>? data,
  }) async {
    return _dio.post(
      createCheckoutSessionUrl,
      data: data,
      options: Options(headers: await _headers()),
    );
  }

  bool _canRetryCheckoutWithoutReturnUrls(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != 400 && statusCode != 422) {
      return false;
    }

    final message = _messageFromDio(error).toLowerCase();
    return message.contains('success_url') ||
        message.contains('cancel_url') ||
        message.contains('return url') ||
        message.contains('unknown field') ||
        message.contains('unexpected field') ||
        message.contains('invalid url');
  }

  Future<Uri> createBillingPortalSession() async {
    try {
      final response = await _dio.post(
        createBillingPortalSessionUrl,
        data: const <String, dynamic>{},
        options: Options(headers: await _headers()),
      );
      final data = _responseMap(response.data);
      final url =
          data['url'] ?? data['portal_url'] ?? data['billing_portal_url'];

      if (url is! String || url.trim().isEmpty) {
        throw const FormatException(
          'Billing portal response did not include a URL.',
        );
      }

      final uri = Uri.tryParse(url.trim());
      if (uri == null || !uri.hasScheme) {
        throw const FormatException('Billing portal URL is invalid.');
      }

      return uri;
    } on DioException catch (error) {
      throw PaymentException(_messageFromDio(error));
    } on FormatException catch (error) {
      throw PaymentException(error.message);
    }
  }

  Future<SubscriptionModel> getSubscription() async {
    try {
      final response = await _dio.get(
        subscriptionUrl,
        options: Options(headers: await _headers()),
      );

      return SubscriptionModel.fromJson(_subscriptionMap(response.data));
    } on DioException catch (error) {
      throw PaymentException(_messageFromDio(error));
    } on FormatException catch (error) {
      throw PaymentException(error.message);
    }
  }

  Future<Map<String, String>> _headers() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    return {
      'accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _responseMap(dynamic data) {
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw const FormatException('Unexpected payment API response.');
  }

  Map<String, dynamic> _subscriptionMap(dynamic data) {
    if (data is Map && data['data'] is List) {
      return _firstSubscription(data['data'] as List);
    }
    if (data is Map && data['results'] is List) {
      return _firstSubscription(data['results'] as List);
    }
    if (data is List) {
      return _firstSubscription(data);
    }
    return _responseMap(data);
  }

  Map<String, dynamic> _firstSubscription(List<dynamic> subscriptions) {
    if (subscriptions.isEmpty) {
      return const <String, dynamic>{'status': 'inactive', 'is_active': false};
    }

    final subscriptionMaps = subscriptions.whereType<Map>().toList();
    if (subscriptionMaps.isEmpty) {
      throw const FormatException('Unexpected subscription API response.');
    }

    final activeSubscription = subscriptionMaps.firstWhere((subscription) {
      final status = subscription['status']?.toString().toLowerCase();
      final active = subscription['is_active'] ?? subscription['active'];
      return active == true || status == 'active' || status == 'trialing';
    }, orElse: () => subscriptionMaps.first);

    return Map<String, dynamic>.from(activeSubscription);
  }

  String _messageFromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message =
          data['message'] ?? data['detail'] ?? data['error'] ?? data['errors'];
      if (message != null) return message.toString();
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    return 'Payment request failed. Please try again.';
  }
}

class PaymentException implements Exception {
  final String message;

  const PaymentException(this.message);

  @override
  String toString() => message;
}
