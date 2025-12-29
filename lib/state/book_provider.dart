import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// State provider for the current book being read.
/// Manages book selection, loading, and current reading state.
/// Supports both demo mode (mock data) and live mode (real backend API).
/// Implements lazy loading - only fetches chapters as needed with a 3-chapter window.
class BookProvider extends ChangeNotifier {
  Book? _currentBook;
  List<Book> _availableBooks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _uploadedPdfPath;
  String? _uploadedPdfContent;

  // API integration
  ApiConfig? _apiConfig;
  BackendApiClient? _apiClient;

  // Lazy loading state
  final Set<int> _processedChapters = {};
  final Set<int> _processingChapters = {};
  List<String> _rawChunks = [];
  String? _currentBookId;
  String? _currentBookTitle;

  // Rate limiting - 5 requests per minute = 1 every 12 seconds
  DateTime? _lastApiCall;
  static const _minApiInterval = Duration(seconds: 13);

  // Getters
  Book? get currentBook => _currentBook;
  List<Book> get availableBooks => _availableBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCurrentBook => _currentBook != null;
  bool get hasUploadedPdf =>
      _uploadedPdfPath != null && _uploadedPdfContent != null;
  String? get uploadedPdfPath => _uploadedPdfPath;
  String? get uploadedPdfContent => _uploadedPdfContent;

  /// Check if using live API mode
  bool get isLiveMode =>
      _apiConfig != null && !_apiConfig!.isDemoMode && _apiConfig!.isConnected;

  /// Set API configuration for live mode
  void setApiConfig(ApiConfig config) {
    _apiConfig = config;
    _apiClient = BackendApiClient(config);
    notifyListeners();
  }

  /// Load available books from the mock service
  Future<void> loadAvailableBooks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      _availableBooks = MockBookService.getPublicDomainBooks();
    } catch (e) {
      _errorMessage = 'Failed to load books: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a book to read
  void selectBook(Book book) {
    _currentBook = book;
    notifyListeners();
  }

  /// Process a book - uses real API if connected, otherwise mock
  Future<void> processBook(String bookId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isLiveMode) {
        debugPrint('BookProvider: Using LIVE API for book processing');
        _currentBook = await _processBookWithApi(bookId);
      } else {
        debugPrint('BookProvider: Using MOCK data for book processing');
        _currentBook = await MockBookService.processBook(bookId);
      }
    } catch (e) {
      _errorMessage = 'Failed to process book: $e';
      debugPrint('BookProvider: Error processing book: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Process book using real backend API with rate limiting
  Future<Book> _processBookWithApi(String bookId) async {
    final baseBook = await MockBookService.processBook(bookId);
    final processedChapters = <Chapter>[];

    for (final chapter in baseBook.chapters) {
      final chapterText = _getChapterTextForApi(chapter);

      // Wait for rate limit
      await _waitForRateLimit();

      final response = await _apiClient?.generateSummary(
        textChunk: chapterText,
        mode: 'chapter',
        bookId: bookId,
        chapterTitle: chapter.title,
      );

      if (response != null && response.blocks.isNotEmpty) {
        final blocks = _convertBlocksToLearningBlocks(
          response.blocks,
          chapter.id,
        );
        processedChapters.add(
          Chapter(
            id: chapter.id,
            title:
                response.unitTitle.isNotEmpty
                    ? response.unitTitle
                    : chapter.title,
            number: chapter.number,
            blocks: blocks,
          ),
        );
        debugPrint(
          'BookProvider: Processed chapter "${chapter.title}" with ${blocks.length} blocks',
        );
      } else {
        processedChapters.add(chapter);
        debugPrint(
          'BookProvider: Using fallback for chapter "${chapter.title}"',
        );
      }
    }

    return baseBook.copyWith(chapters: processedChapters);
  }

  /// Wait for rate limit before making API call (5 per minute limit)
  Future<void> _waitForRateLimit() async {
    if (_lastApiCall != null) {
      final elapsed = DateTime.now().difference(_lastApiCall!);
      if (elapsed < _minApiInterval) {
        final waitTime = _minApiInterval - elapsed;
        debugPrint(
          'BookProvider: Rate limiting, waiting ${waitTime.inSeconds}s',
        );
        await Future.delayed(waitTime);
      }
    }
    _lastApiCall = DateTime.now();
  }

  /// Get chapter text to send to API
  String _getChapterTextForApi(Chapter chapter) {
    final buffer = StringBuffer();
    buffer.writeln('Chapter: ${chapter.title}');
    buffer.writeln();
    for (final block in chapter.blocks) {
      if (block.headline.isNotEmpty) {
        buffer.writeln(block.headline);
      }
      buffer.writeln(block.content);
      if (block.quote != null) {
        buffer.writeln('"${block.quote}"');
      }
      if (block.takeaway != null) {
        buffer.writeln('Takeaway: ${block.takeaway}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// Convert API blocks to LearningBlocks
  List<LearningBlock> _convertBlocksToLearningBlocks(
    List<ContentBlock> apiBlocks,
    String chapterId,
  ) {
    return apiBlocks.asMap().entries.map((entry) {
      final idx = entry.key;
      final block = entry.value;
      return LearningBlock(
        id: '${chapterId}_$idx',
        tag: _mapBlockTypeToTag(block.type),
        headline: _extractHeadline(block),
        content: block.text,
        takeaway: block.type == 'takeaway' ? block.text : null,
        estimatedReadTime: _estimateReadTime(block.text),
      );
    }).toList();
  }

  /// Map backend block type to UI tag
  String _mapBlockTypeToTag(String type) {
    switch (type) {
      case 'core_idea':
        return 'CORE IDEA';
      case 'explanation':
        return 'EXPLANATION';
      case 'example':
        return 'EXAMPLE';
      case 'insight':
        return 'INSIGHT';
      case 'takeaway':
        return 'TAKEAWAY';
      case 'nuance':
        return 'NUANCE';
      case 'contrast':
        return 'CONTRAST';
      case 'reflection':
        return 'REFLECTION';
      case 'lyric_scroll':
        return 'DEEP READ';
      default:
        return type.toUpperCase();
    }
  }

  /// Extract headline from block (first sentence or type-based)
  String _extractHeadline(ContentBlock block) {
    if (block.text.isEmpty) return block.type.toUpperCase();
    final firstSentenceEnd = block.text.indexOf('. ');
    if (firstSentenceEnd > 0 && firstSentenceEnd < 100) {
      return block.text.substring(0, firstSentenceEnd + 1);
    }
    if (block.text.length <= 80) {
      return block.text;
    }
    return '${block.text.substring(0, 77)}...';
  }

  /// Estimate read time in seconds
  int _estimateReadTime(String text) {
    final wordCount = text.split(RegExp(r'\s+')).length;
    return ((wordCount / 200) * 60).round().clamp(30, 300);
  }

  /// Check if text content is readable (not binary)
  bool _isReadableText(String text) {
    if (text.isEmpty) return false;
    final sample = text.substring(0, text.length.clamp(0, 1000));

    // PDF markers indicate binary content
    if (sample.contains('%PDF') ||
        sample.contains('endobj') ||
        sample.contains('/Type /Catalog') ||
        sample.contains('/AcroForm')) {
      return false;
    }

    // Count non-printable characters
    int nonPrintable = 0;
    for (int i = 0; i < sample.length; i++) {
      final code = sample.codeUnitAt(i);
      if (code < 32 && code != 9 && code != 10 && code != 13) {
        nonPrintable++;
      }
      if (code > 65000) {
        nonPrintable++;
      }
    }
    return nonPrintable < sample.length * 0.1;
  }

  /// Clean text of non-printable characters
  String _cleanText(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if ((code >= 32 && code < 127) ||
          code == 9 ||
          code == 10 ||
          code == 13 ||
          (code >= 160 && code < 65000)) {
        buffer.writeCharCode(code);
      } else if (code < 32) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  /// Process uploaded PDF with lazy loading (3-chapter window)
  Future<void> processUploadedPdf(
    String filePath, {
    String? textContent,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _uploadedPdfPath = filePath;
    notifyListeners();

    try {
      if (isLiveMode && textContent != null && textContent.isNotEmpty) {
        // Validate text is readable (not binary)
        if (!_isReadableText(textContent)) {
          _errorMessage =
              'File appears to be binary/PDF format. Please upload a .txt file with plain text content.';
          debugPrint('BookProvider: Content is not readable text');
          _isLoading = false;
          notifyListeners();
          return;
        }

        debugPrint(
          'BookProvider: Processing text with LIVE API (lazy loading)',
        );
        await _initializeLazyLoading(
          textContent,
          fileName: filePath.split('/').last.split('\\').last,
        );
      } else {
        debugPrint('BookProvider: Processing PDF with MOCK service');
        _currentBook = await MockBookService.processUploadedPdf(filePath);
      }
    } catch (e) {
      _errorMessage = 'Failed to process file: $e';
      debugPrint('BookProvider: Error processing file: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initialize lazy loading with chunks - only process first chapter, prefetch next 2
  Future<void> _initializeLazyLoading(
    String textContent, {
    String? fileName,
  }) async {
    _currentBookTitle =
        fileName?.replaceAll('.pdf', '').replaceAll('.txt', '') ??
        'Uploaded Book';
    _currentBookId = 'uploaded_${DateTime.now().millisecondsSinceEpoch}';

    final cleanedText = _cleanText(textContent);
    _rawChunks = _splitTextIntoChunks(cleanedText);
    _processedChapters.clear();
    _processingChapters.clear();

    // Limit to max 15 chapters to avoid rate limit issues
    if (_rawChunks.length > 15) {
      debugPrint(
        'BookProvider: Limiting from ${_rawChunks.length} to 15 chunks',
      );
      _rawChunks = _rawChunks.sublist(0, 15);
    }

    debugPrint(
      'BookProvider: Initialized ${_rawChunks.length} chunks for lazy loading',
    );

    // Create placeholder book with loading chapters
    final placeholderChapters = List.generate(_rawChunks.length, (i) {
      return Chapter(
        id: '${_currentBookId}_ch${i + 1}',
        title: 'Chapter ${i + 1}',
        number: i + 1,
        blocks: [
          LearningBlock(
            id: '${_currentBookId}_ch${i + 1}_loading',
            tag: 'LOADING',
            headline: 'Loading Chapter ${i + 1}...',
            content: 'AI is processing this chapter. Please wait...',
            estimatedReadTime: 30,
          ),
        ],
      );
    });

    _currentBook = Book(
      id: _currentBookId!,
      title: _currentBookTitle!,
      author: 'Uploaded Document',
      coverUrl: '',
      description: 'Content processed from uploaded file',
      chapters: placeholderChapters,
      source: BookSource.uploadedPdf,
    );

    _isLoading = false;
    notifyListeners();

    // Process first chapter immediately, then prefetch next 2
    await _processChaptersInWindow(0);
  }

  /// Process chapters in a sliding window around current position (max 3)
  Future<void> _processChaptersInWindow(int currentChapter) async {
    final chaptersToProcess = <int>[];

    // Window: current + 2 ahead
    for (
      int i = currentChapter;
      i <= currentChapter + 2 && i < _rawChunks.length;
      i++
    ) {
      if (!_processedChapters.contains(i) && !_processingChapters.contains(i)) {
        chaptersToProcess.add(i);
      }
    }

    if (chaptersToProcess.isEmpty) {
      debugPrint('BookProvider: No chapters to process in window');
      return;
    }

    debugPrint('BookProvider: Processing chapters $chaptersToProcess');

    for (final chapterIndex in chaptersToProcess) {
      await _processChapter(chapterIndex);
    }
  }

  /// Process a single chapter with rate limiting
  Future<void> _processChapter(int chapterIndex) async {
    if (_processedChapters.contains(chapterIndex) ||
        _processingChapters.contains(chapterIndex) ||
        chapterIndex >= _rawChunks.length) {
      return;
    }

    _processingChapters.add(chapterIndex);
    final chunk = _rawChunks[chapterIndex];
    final chapterNum = chapterIndex + 1;

    debugPrint('BookProvider: Processing chapter $chapterNum...');

    try {
      await _waitForRateLimit();

      final response = await _apiClient?.generateSummary(
        textChunk: chunk,
        mode: 'chapter',
        bookId: _currentBookId!,
        chapterTitle: 'Chapter $chapterNum',
      );

      Chapter newChapter;

      if (response != null && response.blocks.isNotEmpty) {
        final blocks = _convertBlocksToLearningBlocks(
          response.blocks,
          '${_currentBookId}_ch$chapterNum',
        );

        newChapter = Chapter(
          id: '${_currentBookId}_ch$chapterNum',
          title:
              response.unitTitle.isNotEmpty
                  ? response.unitTitle
                  : 'Chapter $chapterNum',
          number: chapterNum,
          blocks: blocks,
        );

        debugPrint(
          'BookProvider: Chapter $chapterNum processed with ${blocks.length} blocks',
        );
      } else {
        newChapter = _createFallbackChapter(chapterIndex, chunk);
        debugPrint('BookProvider: Created fallback for chapter $chapterNum');
      }

      // Update book with processed chapter
      if (_currentBook != null) {
        final updatedChapters = List<Chapter>.from(_currentBook!.chapters);
        updatedChapters[chapterIndex] = newChapter;
        _currentBook = _currentBook!.copyWith(chapters: updatedChapters);
        notifyListeners();
      }

      _processedChapters.add(chapterIndex);
    } catch (e) {
      debugPrint('BookProvider: Error processing chapter $chapterNum: $e');
      if (_currentBook != null) {
        final updatedChapters = List<Chapter>.from(_currentBook!.chapters);
        updatedChapters[chapterIndex] = _createFallbackChapter(
          chapterIndex,
          chunk,
        );
        _currentBook = _currentBook!.copyWith(chapters: updatedChapters);
        notifyListeners();
      }
      _processedChapters.add(chapterIndex);
    } finally {
      _processingChapters.remove(chapterIndex);
    }
  }

  /// Create a fallback chapter when API fails
  Chapter _createFallbackChapter(int chapterIndex, String chunk) {
    final chapterNum = chapterIndex + 1;
    final preview =
        chunk.length > 800 ? '${chunk.substring(0, 800)}...' : chunk;

    return Chapter(
      id: '${_currentBookId}_ch$chapterNum',
      title: 'Chapter $chapterNum',
      number: chapterNum,
      blocks: [
        LearningBlock(
          id: '${_currentBookId}_ch${chapterNum}_0',
          tag: 'CONTENT',
          headline: 'Chapter $chapterNum Content',
          content: preview,
          estimatedReadTime: _estimateReadTime(preview),
        ),
      ],
    );
  }

  /// Called when user navigates to a chapter - triggers prefetching next 2
  void onChapterViewed(int chapterIndex) {
    debugPrint('BookProvider: User viewing chapter ${chapterIndex + 1}');
    _processChaptersInWindow(chapterIndex);
  }

  /// Split text into manageable chunks (max 15 chapters)
  List<String> _splitTextIntoChunks(String text) {
    const maxChunks = 15;
    const targetChunkSize = 5000;
    const minChunkSize = 2000;

    final chunks = <String>[];
    final sections = text.split(
      RegExp(r'\n\s*\n\s*\n|Chapter \d+|CHAPTER \d+', caseSensitive: false),
    );

    var currentChunk = StringBuffer();

    for (final section in sections) {
      final trimmed = section.trim();
      if (trimmed.isEmpty) continue;

      if (currentChunk.length + trimmed.length > targetChunkSize &&
          currentChunk.length >= minChunkSize) {
        chunks.add(currentChunk.toString().trim());
        currentChunk = StringBuffer();
        if (chunks.length >= maxChunks) break;
      }
      currentChunk.writeln(trimmed);
      currentChunk.writeln();
    }

    if (currentChunk.isNotEmpty && chunks.length < maxChunks) {
      chunks.add(currentChunk.toString().trim());
    }

    if (chunks.length == 1 && chunks.first.length > targetChunkSize * 3) {
      final bigText = chunks.first;
      chunks.clear();
      for (
        var i = 0;
        i < bigText.length && chunks.length < maxChunks;
        i += targetChunkSize
      ) {
        chunks.add(
          bigText.substring(i, (i + targetChunkSize).clamp(0, bigText.length)),
        );
      }
    }

    return chunks.isEmpty ? [text] : chunks;
  }

  /// Upload PDF and extract text via backend
  Future<void> uploadPdf({
    String? path,
    List<int>? bytes,
    String? filename,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isLiveMode && _apiClient != null) {
        final text = await _apiClient!.extractTextFromPdf(
          filePath: path,
          fileBytes: bytes,
          fileName: filename,
        );
        setUploadedPdfContent(path ?? filename ?? 'uploaded.pdf', text);
      } else {
        throw Exception("PDF upload requires live API connection");
      }
    } catch (e) {
      _errorMessage = 'Failed to upload PDF: $e';
      debugPrint('BookProvider: Error uploading PDF: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set uploaded PDF content for processing
  void setUploadedPdfContent(String path, String content) {
    _uploadedPdfPath = path;
    _uploadedPdfContent = content;
    notifyListeners();
  }

  /// Clear current book selection and reset lazy loading state
  void clearCurrentBook() {
    _currentBook = null;
    _rawChunks.clear();
    _processedChapters.clear();
    _processingChapters.clear();
    _currentBookId = null;
    _currentBookTitle = null;
    notifyListeners();
  }

  /// Get all blocks from current book flattened
  List<LearningBlock> get allBlocks {
    if (_currentBook == null) return [];
    return _currentBook!.chapters.expand((chapter) => chapter.blocks).toList();
  }

  /// Get chapter for a specific block
  Chapter? getChapterForBlock(String blockId) {
    if (_currentBook == null) return null;
    for (final chapter in _currentBook!.chapters) {
      if (chapter.blocks.any((b) => b.id == blockId)) {
        return chapter;
      }
    }
    return null;
  }
}
