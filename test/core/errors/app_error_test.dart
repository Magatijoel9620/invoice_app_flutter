import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_easy/core/errors/app_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AppErrorHandler', () {
    test(
      'classifies duplicate registration without assuming an account was created',
      () {
        final result = AppErrorHandler.classify(
          const AuthException(
            'User already registered',
            code: 'user_already_exists',
          ),
        );
        expect(result.category, AppErrorCategory.duplicateRegistration);
        expect(result.message, contains('Try signing in'));
      },
    );

    test('classifies invalid credentials', () {
      final result = AppErrorHandler.classify(
        const AuthException(
          'Invalid login credentials',
          code: 'invalid_credentials',
        ),
      );
      expect(result.category, AppErrorCategory.invalidCredentials);
    });

    test('classifies unconfirmed email accounts', () {
      final result = AppErrorHandler.classify(
        const AuthException('Email not confirmed', code: 'email_not_confirmed'),
      );
      expect(result.category, AppErrorCategory.emailConfirmationRequired);
      expect(result.message, contains('confirm your email'));
    });

    test('classifies offline socket failures with a safe retry message', () {
      final result = AppErrorHandler.classify(
        const SocketException('secret host'),
      );
      expect(result.category, AppErrorCategory.noInternet);
      expect(result.retryable, isTrue);
      expect(result.message, contains('offline'));
      expect(result.message, isNot(contains('secret host')));
    });

    test('classifies timeouts separately from offline state', () {
      final result = AppErrorHandler.classify(
        TimeoutException('request timed out'),
      );
      expect(result.category, AppErrorCategory.timeout);
      expect(result.retryable, isTrue);
    });

    test('classifies Supabase service failures as temporarily unavailable', () {
      final result = AppErrorHandler.classify(
        const PostgrestException(message: 'Service unavailable', code: '503'),
      );
      expect(result.category, AppErrorCategory.serverUnavailable);
      expect(result.retryable, isTrue);
      expect(result.message, isNot(contains('Service unavailable')));
    });

    test('classifies malformed input as validation', () {
      final result = AppErrorHandler.classify(
        const FormatException('private payload'),
      );
      expect(result.category, AppErrorCategory.validation);
      expect(result.message, isNot(contains('private payload')));
    });

    test('never exposes generic exception details', () {
      final result = AppErrorHandler.classify(Exception('token=do-not-show'));
      expect(result.category, AppErrorCategory.unexpected);
      expect(result.message, isNot(contains('do-not-show')));
    });

    test(
      'classifies local state errors without leaking implementation details',
      () {
        final result = AppErrorHandler.classify(StateError('database path'));
        expect(result.category, AppErrorCategory.unexpected);
        expect(result.message, isNot(contains('database path')));
      },
    );
  });
}
