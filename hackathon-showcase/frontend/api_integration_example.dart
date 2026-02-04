/// Project NexH - Frontend API Integration Examples
/// ================================================
///
/// This file demonstrates our Flutter/Dart patterns for:
/// - Secure API client with Firebase Auth
/// - AI endpoint consumption
/// - State management with Riverpod
///
/// Full source available upon request for judges.

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// SECURE API CLIENT - Singleton with Firebase Token Injection
// =============================================================================

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio _dio;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    // [SECURITY] API URL from compile-time environment variable
    // Build with: flutter build web --dart-define=API_URL=https://your-backend.run.app
    const apiUrl = String.fromEnvironment(
      'API_URL',
      defaultValue: 'https://your-cloud-run-backend.run.app',
    );

    _dio = Dio(BaseOptions(
      baseUrl: apiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
    ));

    // Firebase Token Interceptor - Auto-inject auth header
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Public endpoints that don't require authentication
        final publicPaths = ['/health'];
        if (publicPaths.contains(options.path)) {
          return handler.next(options);
        }

        // [Security] Inject Firebase Token for protected endpoints
        try {
          var user = FirebaseAuth.instance.currentUser;

          // Wait briefly for auth state to settle (race condition fix)
          if (user == null) {
            try {
              user = await FirebaseAuth.instance
                  .authStateChanges()
                  .firstWhere((u) => u != null)
                  .timeout(const Duration(seconds: 2));
            } catch (_) {
              // Timeout, user remains null
            }
          }

          if (user != null) {
            final token = await user.getIdToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            } else {
              return handler.reject(DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                error: "Unable to retrieve Auth Token",
              ));
            }
          } else {
            return handler.reject(DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: "User not authenticated",
            ));
          }
        } catch (e) {
          return handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: "Auth Error: $e",
          ));
        }
        return handler.next(options);
      },
    ));

    // Debug logging (only in debug mode)
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  Dio get client => _dio;
}

// =============================================================================
// AI ENDPOINT EXAMPLES
// =============================================================================

/// Represents a daily AI-generated report
class DailyReport {
  final String strategySummary;
  final List<TacticalAction> tacticalActions;
  final DateTime reportDate;

  DailyReport({
    required this.strategySummary,
    required this.tacticalActions,
    required this.reportDate,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      strategySummary: json['strategy_summary'] ?? '',
      tacticalActions: (json['tactical_actions'] as List?)
              ?.map((a) => TacticalAction.fromJson(a))
              .toList() ??
          [],
      reportDate: DateTime.tryParse(json['report_date'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Actionable item from AI analysis
class TacticalAction {
  final String targetClientId;
  final String targetClientName;
  final String targetClientPhone;
  final String title;
  final String reason;
  final String draftContent; // Pre-generated WhatsApp message

  TacticalAction({
    required this.targetClientId,
    required this.targetClientName,
    required this.targetClientPhone,
    required this.title,
    required this.reason,
    required this.draftContent,
  });

  factory TacticalAction.fromJson(Map<String, dynamic> json) {
    return TacticalAction(
      targetClientId: json['target_client_id'] ?? '',
      targetClientName: json['target_client_name'] ?? '',
      targetClientPhone: json['target_client_phone'] ?? '',
      title: json['title'] ?? '',
      reason: json['reason'] ?? '',
      draftContent: json['draft_content'] ?? '',
    );
  }
}

// =============================================================================
// RIVERPOD STATE MANAGEMENT
// =============================================================================

/// Provider for fetching daily AI-generated reports
final dailyReportProvider =
    FutureProvider.autoDispose.family<DailyReport?, String>((ref, dateStr) async {
  try {
    final response = await ApiClient().client.get('/insights/daily/$dateStr');

    if (response.statusCode == 200 && response.data != null) {
      return DailyReport.fromJson(response.data);
    }
    return null;
  } on DioException catch (e) {
    if (kDebugMode) debugPrint('Daily Report Error: $e');
    return null;
  }
});

/// Provider for triggering AI image analysis
final imageAnalysisProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, ImageAnalysisParams>((ref, params) async {
  try {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(params.filePath),
      'industry': params.industry,
    });

    final response = await ApiClient().client.post(
      '/assets/${params.assetId}/analyze_image',
      data: formData,
    );

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  } on DioException catch (e) {
    if (kDebugMode) debugPrint('Image Analysis Error: $e');
    return null;
  }
});

/// Parameters for image analysis request
class ImageAnalysisParams {
  final String assetId;
  final String filePath;
  final String industry;

  ImageAnalysisParams({
    required this.assetId,
    required this.filePath,
    required this.industry,
  });
}

// =============================================================================
// USAGE IN WIDGET
// =============================================================================

/// Example widget showing how to consume AI data
class DailyReportCard extends ConsumerWidget {
  final String date;

  const DailyReportCard({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(dailyReportProvider(date));

    return reportAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (report) {
        if (report == null) {
          return const Text('No report available');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Strategy Summary from AI
            Text(
              'Strategy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(report.strategySummary),

            const SizedBox(height: 16),

            // Tactical Actions (AI-generated)
            Text(
              'Actions (${report.tacticalActions.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...report.tacticalActions.map((action) => ListTile(
                  title: Text(action.title),
                  subtitle: Text(action.reason),
                  trailing: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _sendWhatsApp(action),
                  ),
                )),
          ],
        );
      },
    );
  }

  void _sendWhatsApp(TacticalAction action) {
    // Launch WhatsApp with pre-filled AI-generated message
    final phone = action.targetClientPhone.replaceAll(RegExp(r'[^\d]'), '');
    final message = Uri.encodeComponent(action.draftContent);
    // url_launcher: launchUrl(Uri.parse('https://wa.me/$phone?text=$message'));
  }
}

// Stub for compilation
class Widget {}
class BuildContext {}
class ConsumerWidget extends Widget {
  const ConsumerWidget({dynamic key});
  Widget build(BuildContext context, WidgetRef ref) => throw UnimplementedError();
}
class WidgetRef {}
class Theme {
  static ThemeData of(BuildContext context) => ThemeData();
}
class ThemeData {
  TextTheme get textTheme => TextTheme();
}
class TextTheme {
  dynamic get titleMedium => null;
}
class Column extends Widget {
  Column({dynamic crossAxisAlignment, required List<Widget> children});
}
class Text extends Widget {
  Text(String text, {dynamic style});
}
class SizedBox extends Widget {
  const SizedBox({double? height});
}
class ListTile extends Widget {
  ListTile({dynamic title, dynamic subtitle, dynamic trailing});
}
class IconButton extends Widget {
  IconButton({dynamic icon, required void Function() onPressed});
}
class Icon extends Widget {
  const Icon(dynamic icon);
}
class Icons {
  static const send = null;
}
class CircularProgressIndicator extends Widget {
  const CircularProgressIndicator();
}
class CrossAxisAlignment {
  static const start = null;
}
