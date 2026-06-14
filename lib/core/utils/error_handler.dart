import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AppError { networkError, firestoreError, permissionDenied, adNotLoaded, unknown }

class AppException implements Exception {
  final AppError type;
  final String message;
  final dynamic originalError;

  AppException(this.type, this.message, [this.originalError]);

  @override
  String toString() => 'AppException: $message ($type)';
}

class ErrorHandler {
  static AppException handleFirebaseError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return AppException(AppError.permissionDenied, 'Erişim engellendi. İzniniz yok.', e);
    } else if (e.code == 'unavailable' || e.code == 'network-request-failed') {
      return AppException(AppError.networkError, 'İnternet bağlantınızı kontrol edin.', e);
    } else {
      return AppException(AppError.firestoreError, 'Sunucu hatası oluştu: ${e.message}', e);
    }
  }

  static AppException handleGenericError(dynamic e) {
    if (e is FirebaseException) {
      return handleFirebaseError(e);
    }
    return AppException(AppError.unknown, 'Bilinmeyen bir hata oluştu.', e);
  }
}
