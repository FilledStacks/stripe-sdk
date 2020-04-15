import 'dart:convert';
import 'dart:developer';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:stripe_sdk/stripe_sdk.dart';
import 'package:stripe_sdk/stripe_sdk_ui.dart';

class NetworkService {
  final CloudFunctions _cf;

  NetworkService(this._cf);

  NetworkService.defaultInstance() : _cf = CloudFunctions(region: "europe-west2");

  /// Utility function to call a Firebase Function
  Future<T> _call<T>(String name, Map params) async {
    log('NetworkService._call, $name, $params');
    final HttpsCallable callable = _cf.getHttpsCallable(
      functionName: name,
    );
    try {
      final result = await callable.call(params);
      print(result);
      print(result.data);
      return result.data;
    } on CloudFunctionsException catch (e) {
      log(e.message);
      log(e.toString());
      return null;
    }
  }

  /// Get a stripe ephemeral key
  Future<String> getEphemeralKey(String apiVersion) async {
    final result = await _call('getEphemeralKey', {'stripeVersion': apiVersion});
    final key = result['key'];
    final jsonKey = json.encode(key);
    return jsonKey;
  }

  Future<SetupIntentResponse> createSetupIntent(String paymentMethod) async {
    final params = {'paymentMethod': paymentMethod};
    final response = await _call('createSetupIntent', params);
    return SetupIntentResponse(response['status'], response['clientSecret']);
  }

  Future<Map> createAutomaticPaymentIntent(int amount) {
    final params = {
      "amount": amount,
    };
    return _call('createAutomaticPaymentIntent', params);
  }

  Future<Map> createManualPaymentIntent(int amount, String paymentMethod) {
    final params = {
      "amount": amount,
      "paymentMethod": paymentMethod,
      "returnUrl": Stripe.instance.getReturnUrlForSca()
    };
    return _call('createManualPaymentIntent', params);
  }
}
