import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Callback to get the current ID token for Authorization header.
typedef TokenGetter = String? Function();

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
  final String slideTitle;
  final String headline;
  final String body;
  final String text; // Legacy field
  final List<String> lyricLines;
  final bool imageHint;
  final String imagePrompt;

  ContentBlock({
    required this.type,
    this.slideTitle = '',
    this.headline = '',
    this.body = '',
    required this.text,
    required this.lyricLines,
    required this.imageHint,
    this.imagePrompt = '',
  });

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      type: json['type'] as String? ?? 'insight',
      slideTitle: json['slide_title'] as String? ?? '',
      headline: json['headline'] as String? ?? '',
      body: json['body'] as String? ?? json['text'] as String? ?? '',
      text: json['text'] as String? ?? json['body'] as String? ?? '',
      lyricLines:
          (json['lyric_lines'] as List?)?.map((e) => e as String).toList() ??
          [],
      imageHint: json['image_hint'] as bool? ?? false,
      imagePrompt: json['image_prompt'] as String? ?? '',
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
  TokenGetter? _tokenGetter;

  BackendApiClient(this._config) : _httpClient = http.Client();

  /// Set the token getter so all authenticated requests include Authorization.
  void setTokenGetter(TokenGetter getter) {
    _tokenGetter = getter;
  }

  /// Common headers with optional auth.
  Map<String, String> _headers({String contentType = 'application/json'}) {
    final h = <String, String>{
      'Content-Type': contentType,
    };
    final token = _tokenGetter?.call();
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  /// Check if backend is reachable and healthy
  Future<bool> checkHealth() async {
    _config.setChecking(true);

    try {
      final url = Uri.parse('${_config.apiBaseUrl}/health');
      final response = await _httpClient
          .get(url, headers: _headers())
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
          .post(url, headers: _headers(), body: jsonEncode(body))
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
    final uri = Uri.parse('${_config.apiBaseUrl}/extractText');
    final request = http.MultipartRequest('POST', uri);
    final token = _tokenGetter?.call();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

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
    try {
      final url = Uri.parse('${_config.apiBaseUrl}/cache/stats');
      final response = await _httpClient
          .get(url, headers: _headers())
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

  /// Generate image URL from prompt
  Future<String?> generateImageUrl({
    required String prompt,
    int width = 512,
    int height = 768,
    String style = 'anime',
    String bookTitle = '',
    String characterContext = '',
  }) async {
    try {
      final url = Uri.parse('${_config.apiBaseUrl}/generateImage');
      final body = {
        'prompt': prompt,
        'width': width,
        'height': height,
        'style': style,
        'book_title': bookTitle,
        'character_context': characterContext,
      };

      debugPrint(
        'BackendApiClient: Generating image for: ${prompt.substring(0, 50.clamp(0, prompt.length))}...',
      );

      final response = await _httpClient
          .post(url, headers: _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final imageUrl = data['image_url'] as String?;

        // If the URL is relative (starts with /), prepend the backend base URL
        if (imageUrl != null && imageUrl.startsWith('/')) {
          return '${_config.apiBaseUrl}$imageUrl';
        }
        return imageUrl;
      }
      return null;
    } catch (e) {
      debugPrint('BackendApiClient: Failed to generate image: $e');
      return null;
    }
  }

  /// Dispose HTTP client
  void dispose() {
    _httpClient.close();
  }

  // ============================================
  // NOTE ENDPOINTS
  // ============================================

  /// Create a new note
  Future<Map<String, dynamic>> createNote({
    required String bookId,
    required int cardIndex,
    required String cardTitle,
    required String noteText,
  }) async {
    try {
      final url = Uri.parse('${_config.apiBaseUrl}/notes/create');
      final body = {
        'book_id': bookId,
        'card_index': cardIndex,
        'card_title': cardTitle,
        'note_text': noteText,
      };

      final response = await _httpClient
          .post(url, headers: _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to create note: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('BackendApiClient: Error creating note: $e');
      rethrow;
    }
  }

  /// Get a note by ID
  Future<Map<String, dynamic>?> getNote(String noteId) async {
    try {
      final url = Uri.parse('${_config.apiBaseUrl}/notes/$noteId');
      final response = await _httpClient
          .get(url, headers: _headers())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get note: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('BackendApiClient: Error getting note: $e');
      return null;
    }
  }

  /// Update a note
  Future<Map<String, dynamic>> updateNote(
    String noteId,
    String noteText,
  ) async {
    try {
      final url = Uri.parse('${_config.apiBaseUrl}/notes/$noteId');
      final body = {'note_text': noteText};

      final response = await _httpClient
          .put(url, headers: _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to update note: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('BackendApiClient: Error updating note: $e');
      rethrow;
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      final url = Uri.parse('${_config.apiBaseUrl}/notes/$noteId');
      final response = await _httpClient
          .delete(url, headers: _headers())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw Exception(
          'Failed to delete note: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('BackendApiClient: Error deleting note: $e');
      rethrow;
    }
  }

  /// Get all notes for a book
  Future<List<Map<String, dynamic>>> getNotesForBook(String bookId) async {
    try {
      final url = Uri.parse('${_config.apiBaseUrl}/notes/book/$bookId');
      final response = await _httpClient
          .get(url, headers: _headers())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final notes = data['notes'] as List? ?? [];
        return notes.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get notes: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('BackendApiClient: Error getting notes for book: $e');
      return [];
    }
  }

  /// Get all notes
  Future<List<Map<String, dynamic>>> getAllNotes() async {
    try {
      final url = Uri.parse('${_config.apiBaseUrl}/notes/');
      final response = await _httpClient
          .get(url, headers: _headers())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final notes = data['notes'] as List? ?? [];
        return notes.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get notes: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('BackendApiClient: Error getting all notes: $e');
      return [];
    }
  }

  // ============================================
  // BOOK / PDF ENDPOINTS
  // ============================================

  /// Request a presigned upload URL for a new PDF.
  /// Returns {book_id, upload_url, s3_key}.
  Future<Map<String, dynamic>> requestPdfUpload({
    required String filename,
    String title = '',
  }) async {
    final url = Uri.parse('${_config.apiBaseUrl}/books/upload');
    final response = await _httpClient
        .post(
          url,
          headers: _headers(),
          body: jsonEncode({'filename': filename, 'title': title}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      'Failed to request upload: ${response.statusCode} ${response.body}',
    );
  }

  /// Upload raw PDF bytes to the presigned S3 URL.
  /// Follows 307/301 redirects manually because Dart's http.Client
  /// does not resend the request body when redirecting PUT requests.
  Future<void> uploadPdfToS3({
    required String presignedUrl,
    required List<int> fileBytes,
  }) async {
    final bodyBytes = Uint8List.fromList(fileBytes);
    String currentUrl = presignedUrl;

    for (int attempt = 0; attempt < 5; attempt++) {
      final request = http.Request('PUT', Uri.parse(currentUrl));
      request.headers['Content-Type'] = 'application/pdf';
      request.bodyBytes = bodyBytes;
      request.followRedirects = false;

      final streamed = await _httpClient
          .send(request)
          .timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) return;

      // S3 regional redirect — resend PUT with body to new URL
      if (response.statusCode == 307 ||
          response.statusCode == 301 ||
          response.statusCode == 302) {
        final location = response.headers['location'];
        if (location != null && location.isNotEmpty) {
          debugPrint(
            'BackendApiClient: S3 redirect ${response.statusCode} → $location',
          );
          currentUrl = location;
          continue;
        }
      }

      throw Exception(
        'S3 upload failed: ${response.statusCode} - ${response.body}',
      );
    }

    throw Exception('S3 upload failed: too many redirects');
  }

  /// Confirm the PDF was uploaded — backend reads it to count pages.
  /// Returns {book_id, total_pages, status, s3_key}.
  Future<Map<String, dynamic>> confirmPdfUpload(String bookId) async {
    final url = Uri.parse('${_config.apiBaseUrl}/books/$bookId/confirm');
    final response = await _httpClient
        .post(url, headers: _headers())
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Confirm failed: ${response.statusCode} ${response.body}');
  }

  /// Extract a batch of pages from a PDF stored in S3.
  /// Returns {text, start_page, end_page, total_pages, has_more, char_count}.
  Future<Map<String, dynamic>> extractBatch({
    required String s3Key,
    int startPage = 0,
    int pageCount = 50,
  }) async {
    final url = Uri.parse('${_config.apiBaseUrl}/extractText');
    final response = await _httpClient
        .post(
          url,
          headers: _headers(),
          body: jsonEncode({
            's3_key': s3Key,
            'start_page': startPage,
            'page_count': pageCount,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      'Batch extract failed: ${response.statusCode} ${response.body}',
    );
  }

  /// Get all books for the current user.
  Future<List<Map<String, dynamic>>> getUserBooks() async {
    final url = Uri.parse('${_config.apiBaseUrl}/books');
    final response = await _httpClient
        .get(url, headers: _headers())
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['books'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    }
    throw Exception('Failed to get books: ${response.statusCode}');
  }

  /// Update reading progress for a book.
  Future<void> updateBookProgress({
    required String bookId,
    int chapterIndex = 0,
    int blockIndex = 0,
    int progressPct = 0,
    int? pagesExtracted,
    String? status,
    Map<String, String>? imageUrls,
  }) async {
    final url = Uri.parse('${_config.apiBaseUrl}/books/$bookId/progress');
    final body = <String, dynamic>{
      'current_chapter_index': chapterIndex,
      'current_block_index': blockIndex,
      'progress_pct': progressPct,
    };
    if (pagesExtracted != null) body['pages_extracted'] = pagesExtracted;
    if (status != null) body['status'] = status;
    if (imageUrls != null && imageUrls.isNotEmpty) body['image_urls'] = imageUrls;

    await _httpClient
        .put(url, headers: _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
  }

  /// Delete a book.
  Future<void> deleteBook(String bookId) async {
    final url = Uri.parse('${_config.apiBaseUrl}/books/$bookId');
    await _httpClient
        .delete(url, headers: _headers())
        .timeout(const Duration(seconds: 10));
  }
}
