import 'package:cloud_functions/cloud_functions.dart';

class SessionCodeService {
  final _fns = FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Called by the HOST app, not the technician app.
  /// Verifies the code and returns a custom token scoped to that session.
  Future<Map<String, dynamic>> redeemCode(String code) async {
    final callable = _fns.httpsCallable('joinSessionWithCode');
    final res = await callable.call({'sessionCode': code});
    return Map<String, dynamic>.from(res.data);
  }
}
