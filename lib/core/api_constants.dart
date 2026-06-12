import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get authUrl => dotenv.env['AUTH_BASE_URL']!;
  static String get registerUrl => '${dotenv.env['AUTH_BASE_URL']!}/users/register';
  static String get authSubscriptionKey => dotenv.env['AUTH_KEY']!;
  static String get authProduct => dotenv.env['AUTH_PRODUCT']!;
  static String get tenantId => dotenv.env['TENANT_ID']!;
  static String get managerEmail => dotenv.env['MANAGER_EMAIL']!;

  static String get legalBaseUrl => dotenv.env['LEGAL_BASE_URL']!;
  static String get legalApiKey => dotenv.env['LEGAL_KEY']!;

  static String get mlBaseUrl => dotenv.env['ML_BASE_URL']!;
  static String get descriptionApiUrl => '${dotenv.env['ML_BASE_URL']!}/describe-image';
  static String get comparisonApiUrl => '${dotenv.env['ML_BASE_URL']!}/describemulti-image';
  static String get descriptionApiKey => dotenv.env['ML_KEY']!;

  static String get origin => dotenv.env['ORIGIN']!;
  static String get referer => dotenv.env['REFERER']!;
}