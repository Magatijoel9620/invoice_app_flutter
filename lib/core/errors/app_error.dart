import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

enum AppErrorCategory {
  noInternet,
  timeout,
  serverUnavailable,
  authenticationRequired,
  invalidCredentials,
  emailConfirmationRequired,
  duplicateRegistration,
  permissionDenied,
  validation,
  subscriptionPayment,
  sync,
  localStorage,
  unexpected,
}

class AppError implements Exception {
  const AppError(this.category, this.message, {this.retryable = false});
  final AppErrorCategory category;
  final String message;
  final bool retryable;
  @override
  String toString() => message;
}

class AppErrorHandler {
  AppErrorHandler._();

  static AppError classify(Object error, {String? operation}) {
    final text = error is AuthException
        ? '${error.code ?? ''} ${error.message}'.toLowerCase()
        : error is PostgrestException
        ? '${error.code ?? ''} ${error.message}'.toLowerCase()
        : error.toString().toLowerCase();

    AppError result;
    if (error is SocketException ||
        error is ClientException ||
        text.contains('network request failed') ||
        text.contains('socketexception')) {
      result = const AppError(
        AppErrorCategory.noInternet,
        'You appear to be offline. Check your connection and try again.',
        retryable: true,
      );
    } else if (error is TimeoutException ||
        text.contains('timeout') ||
        text.contains('timed out')) {
      result = const AppError(
        AppErrorCategory.timeout,
        'The request took too long. Check your connection and try again.',
        retryable: true,
      );
    } else if (error is AuthException) {
      if (text.contains('already registered') ||
          text.contains('user_already_exists') ||
          text.contains('already been registered')) {
        result = const AppError(
          AppErrorCategory.duplicateRegistration,
          'An account may already exist for this email. Try signing in or resetting your password.',
        );
      } else if (text.contains('email_not_confirmed') ||
          text.contains('email not confirmed')) {
        result = const AppError(
          AppErrorCategory.emailConfirmationRequired,
          'Please confirm your email address before signing in. You can request a new confirmation email.',
        );
      } else if (text.contains('invalid login') ||
          text.contains('invalid_credentials') ||
          text.contains('invalid email or password')) {
        result = const AppError(
          AppErrorCategory.invalidCredentials,
          'The email or password is incorrect. Check your details or reset your password.',
        );
      } else if (text.contains('email') &&
          (text.contains('invalid') || text.contains('format'))) {
        result = const AppError(
          AppErrorCategory.validation,
          'Enter a valid email address.',
        );
      } else {
        result = const AppError(
          AppErrorCategory.authenticationRequired,
          'We could not complete sign-in. Please try again.',
        );
      }
    } else if (error is PostgrestException) {
      if (error.code == '42501' ||
          text.contains('permission denied') ||
          text.contains('row-level security')) {
        result = const AppError(
          AppErrorCategory.permissionDenied,
          'You do not have permission to complete this action. Check your account access.',
        );
      } else if (error.code?.startsWith('22') == true ||
          error.code == '23502' ||
          error.code == '23503') {
        result = const AppError(
          AppErrorCategory.validation,
          'Some information is missing or invalid. Review the details and try again.',
        );
      } else {
        result = const AppError(
          AppErrorCategory.serverUnavailable,
          'The service is temporarily unavailable. Your saved information is safe. Try again shortly.',
          retryable: true,
        );
      }
    } else if (error.runtimeType.toString() == 'FunctionException') {
      result = const AppError(
        AppErrorCategory.subscriptionPayment,
        'We could not complete the billing request. Check your payment status before trying again.',
        retryable: true,
      );
    } else if (error.runtimeType.toString() == 'StorageException') {
      result = const AppError(
        AppErrorCategory.localStorage,
        'We could not access stored files. Check available device storage and try again.',
      );
    } else if (error is FormatException) {
      result = const AppError(
        AppErrorCategory.validation,
        'Some information could not be read. Review it and try again.',
      );
    } else if (operation?.startsWith('billing.') == true) {
      result = const AppError(
        AppErrorCategory.subscriptionPayment,
        'We could not complete this billing action. Check your payment status before trying again.',
      );
    } else if (operation?.startsWith('sync.') == true) {
      result = const AppError(
        AppErrorCategory.sync,
        'Some changes could not sync yet. They remain safely on this device. Try again when your connection is stable.',
        retryable: true,
      );
    } else if (error is StateError) {
      result = const AppError(
        AppErrorCategory.unexpected,
        'This action is temporarily unavailable. Please try again.',
      );
    } else if (error is PlatformException) {
      result = const AppError(
        AppErrorCategory.localStorage,
        'Your device could not complete this action. Please try again.',
      );
    } else {
      result = const AppError(
        AppErrorCategory.unexpected,
        'Something went wrong. Your saved information has not been intentionally removed. Please try again.',
      );
    }

    // Deliberately log only safe metadata. Exception text can contain PII,
    // credentials, request bodies, URLs or provider responses.
    if (kDebugMode) {
      debugPrint(
        'AppError operation=${_safeOperation(operation)} category=${result.category.name} type=${error.runtimeType}',
      );
    }
    return result;
  }

  static String message(Object error, {String? operation}) =>
      classify(error, operation: operation).message;

  static String _safeOperation(String? operation) {
    final value = (operation ?? 'unspecified').replaceAll(
      RegExp(r'[^a-zA-Z0-9_.-]'),
      '_',
    );
    return value.substring(0, value.length > 48 ? 48 : value.length);
  }
}
