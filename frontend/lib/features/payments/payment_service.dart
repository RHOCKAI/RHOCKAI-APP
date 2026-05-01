import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rhockai/core/constants/api_constants.dart';
import 'package:rhockai/core/network/dio_client.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return PaymentService(dio);
});

class PaymentService {
  final Dio _dio;
  WebSocketChannel? _channel;

  PaymentService(this._dio);

  /// Initiate the checkout process
  Future<void> purchasePlan(String planType) async {
    try {
      final response = await _dio.post('/payments/checkout/$planType');

      if (response.statusCode == 200) {
        final checkoutUrl = response.data['checkout_url'];
        final Uri url = Uri.parse(checkoutUrl);
        
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          throw Exception('Could not launch checkout URL');
        }
      } else {
        throw Exception('Failed to create checkout session');
      }
    } catch (e) {
      debugPrint('Checkout Error: $e');
      rethrow;
    }
  }

  /// Connect to WebSocket to listen for payment success
  void connectToNotifications(String userToken, BuildContext context) {
    // Assuming ApiConstants.baseUrl has the host, we replace http with ws
    final String host = ApiConstants.baseUrl.replaceAll('http', 'ws');
    final wsUrl = Uri.parse('$host/notifications/ws?token=$userToken');
    
    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      
      if (data['type'] == 'payment_success') {
        _showSuccessDialog(context, data['message']);
      } else if (data['type'] == 'admin_payment_alert') {
        debugPrint("ADMIN ALERT: ${data['message']}");
        // Here you could also show a snackbar or toast for admins
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Admin Alert: ${data['message']}')),
        );
      }
    }, onError: (error) {
      debugPrint('WebSocket Error: $error');
    });
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful! 🎉', style: TextStyle(color: Colors.green)),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Trigger app reload or state update here
              // e.g., ref.refresh(userProvider)
            },
            child: const Text('Awesome!', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void dispose() {
    _channel?.sink.close();
  }
}
