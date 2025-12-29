import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Response model matching backend's SummaryResponse
class SummaryResponse {
  final String unitTitle;
  final List<ContentBlock> blocks;
  final int visualSlotsUsed;
  final bool cached;
  final GenerationNotes notes;

  SummaryResponse({
    required this.unitTitle,
    required this.blocks,
    required this.visualSlotsUsed,
    required this.cached,
    required this.notes,
  });

  factory SummaryResponse.fromJson(Map<String, dynamic> json) {
    return SummaryResponse(
      unitTitle: json['unit_title'] as String? ?? 'Learning Unit',
      blocks:
          (json['blocks'] as List?)
              ?.map((b) => ContentBlock.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      visualSlotsUsed: json['visual_slots_used'] as int? ?? 0,
      cached: json['cached'] as bool? ?? false,
      notes: GenerationNotes.fromJson(
        json['notes'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

/// Content block from backend
class ContentBlock {
  final String type;
  final String text;
  final List<String> lyricLines;
  final bool imageHint;

  ContentBlock({
    required this.type,
    required this.text,
    required this.lyricLines,
    required this.imageHint,
  });

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      type: json['type'] as String? ?? 'insight',
      text: json['text'] as String? ?? '',
      lyricLines:
          (json['lyric_lines'] as List?)?.map((e) => e as String).toList() ??
          [],
      imageHint: json['image_hint'] as bool? ?? false,
    );
  }
}

/// Generation notes from backend
class GenerationNotes {
  final bool compressionApplied;
  final bool longChapterHandled;
  final bool contextUsedOnlyForContinuity;

  GenerationNotes({
    required this.compressionApplied,
    required this.longChapterHandled,
    required this.contextUsedOnlyForContinuity,
  });

  factory GenerationNotes.fromJson(Map<String, dynamic> json) {
    return GenerationNotes(
      compressionApplied: json['compression_applied'] as bool? ?? false,
      longChapterHandled: json['long_chapter_handled'] as bool? ?? false,
      contextUsedOnlyForContinuity:
          json['context_used_only_for_continuity'] as bool? ?? true,
    );
  }
}

/// Client for communicating with the Flashbook backend API.
class BackendApiClient {
  final ApiConfig _config;
  final http.Client _httpClient;

  BackendApiClient(this._config) : _httpClient = http.Client();

  /// Check if backend is reachable and healthy
  Future<bool> checkHealth() async {
    if (_config.isDemoMode) return false;

    _config.setChecking(true);

    try {
      final url = Uri.parse('${_config.apiBaseUrl}/health');
      final response = await _httpClient
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isHealthy = data['status'] == 'healthy';
        _config.setConnectionStatus(connected: isHealthy);
        return isHealthy;
      } else {
        _config.setConnectionStatus(
          connected: false,
          error: 'Server returned ${response.statusCode}',
        );
        return false;
      }
    } on TimeoutException {
      _config.setConnectionStatus(
        connected: false,
        error: 'Connection timed out',
      );
      return false;
    } catch (e) {
      _config.setConnectionStatus(connected: false, error: e.toString());
      return false;
    }
  }

  /// Generate summary for a text chunk
  Future<SummaryResponse?> generateSummary({
    required String textChunk,
    String mode = 'chapter',
    String? bookId,
    String? chapterTitle,
    String? prevContext,
    String? nextContext,
  }) async {
    if (_config.isDemoMode) {
      debugPrint('BackendApiClient: Demo mode, skipping API call');
      return null;
    }

    try {
      final url = Uri.parse('${_config.apiBaseUrl}/generateSummary');

      final body = {
        'text_chunk': textChunk,
        'mode': mode,
        if (bookId != null) 'book_id': bookId,
        if (chapterTitle != null) 'chapter_title': chapterTitle,
        if (prevContext != null) 'prev_context': prevContext,
        if (nextContext != null) 'next_context': nextContext,
      };

      debugPrint('BackendApiClient: Calling $url');
      debugPrint('BackendApiClient: Body length: ${textChunk.length} chars');

      final response = await _httpClient
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      debugPrint('BackendApiClient: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SummaryResponse.fromJson(data as Map<String, dynamic>);
      } else {
        debugPrint('BackendApiClient: Error response: ${response.body}');
        return null;
      }
    } on TimeoutException {
      debugPrint('BackendApiClient: Request timed out');
      return null;
    } catch (e) {
      debugPrint('BackendApiClient: Error: $e');
      return null;
    }
  }

  /// Extract text from a PDF file using the backend
  Future<String> extractTextFromPdf({
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    if (_config.isDemoMode) {
      throw Exception('Cannot extract PDF text in demo mode');
    }

    final uri = Uri.parse('${_config.apiBaseUrl}/extractText');
    final request = http.MultipartRequest('POST', uri);

    // Add file
    if (fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName ?? 'upload.pdf',
        ),
      );
    } else if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    } else {
      throw Exception('Either filePath or fileBytes must be provided');
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['text'] as String;
      } else {
        throw Exception(
          'Failed to extract text: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('BackendApiClient: Error extracting PDF text: $e');
      rethrow;
    }
  }

  /// Get cache statistics from backend
  Future<Map<String, dynamic>?> getCacheStats() async {
    if (_config.isDemoMode) return null;

    try {
      final url = Uri.parse('${_config.apiBaseUrl}/cache/stats');
      final response = await _httpClient
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('BackendApiClient: Failed to get cache stats: $e');
      return null;
    }
  }

  /// Dispose HTTP client
  void dispose() {
    _httpClient.close();
  }
}
