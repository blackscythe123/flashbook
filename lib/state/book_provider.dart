import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Uint8List? _uploadedPdfBytes; // Store PDF bytes for preview

  // API integration
  ApiConfig? _apiConfig;
  BackendApiClient? _apiClient;

  // Lazy loading state
  final Set<int> _processedChapters = {};
  final Set<int> _processingChapters = {};
  List<String> _rawChunks = [];
  String? _currentBookId;
  String? _currentBookTitle;

  // Loading state for chapters
  bool _isLoadingChapter = false;
  int? _loadingChapterIndex;
  DateTime? _loadingStartTime;
  String? _loadingError;

  // Rate limiting - 5 requests per minute = 1 every 12 seconds
  DateTime? _lastApiCall;
  static const _minApiInterval = Duration(seconds: 13);

  // Chapter window size (show only 3 chapters at a time)
  static const _chapterWindowSize = 3;

  // SharedPreferences keys for persistence
  static const _keyCurrentBook = 'current_book';
  static const _keyRawChunks = 'raw_chunks';
  static const _keyProcessedChapters = 'processed_chapters';
  static const _keyCurrentBookId = 'current_book_id';
  static const _keyCurrentBookTitle = 'current_book_title';
  static const _keyUploadedPdfPath = 'uploaded_pdf_path';
  static const _keyUploadedPdfContent = 'uploaded_pdf_content';

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
  Uint8List? get uploadedPdfBytes => _uploadedPdfBytes;

  // Loading state getters
  bool get isLoadingChapter => _isLoadingChapter;
  int? get loadingChapterIndex => _loadingChapterIndex;
  String? get loadingError => _loadingError;

  /// Get estimated wait time in seconds
  int get estimatedWaitSeconds {
    if (_loadingStartTime == null || !_isLoadingChapter) return 0;
    final elapsed = DateTime.now().difference(_loadingStartTime!).inSeconds;
    // Estimate ~15 seconds per chapter
    return (15 - elapsed).clamp(0, 30);
  }

  /// Check if a chapter is available (processed)
  bool isChapterAvailable(int index) {
    return _processedChapters.contains(index);
  }

  /// Get total available chapters count
  int get availableChaptersCount => _processedChapters.length;

  /// Get total chunks count
  int get totalChunksCount => _rawChunks.length;

  /// Check if using live API mode
  bool get isLiveMode =>
      _apiConfig != null && !_apiConfig!.isDemoMode && _apiConfig!.isConnected;

  /// Set API configuration for live mode
  void setApiConfig(ApiConfig config) {
    _apiConfig = config;
    _apiClient = BackendApiClient(config);
    notifyListeners();
  }

  /// Initialize provider - load persisted state
  Future<void> initialize() async {
    await loadBookState();
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
        final blocks = await _convertBlocksToLearningBlocks(
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
  Future<List<LearningBlock>> _convertBlocksToLearningBlocks(
    List<ContentBlock> apiBlocks,
    String chapterId,
  ) async {
    final blocks = <LearningBlock>[];

    // Variables intentionally removed as they are unused for synchronous processing
    // Image context is now handled during background generation

    // Track how many images we've generated (limit to 2 initially)
    // Track how many images we've generated
    // int imagesGenerated = 0; // No longer used for synchronous generation
    // const maxInitialImages = 2; // Moved to background processing

    for (var idx = 0; idx < apiBlocks.length; idx++) {
      final block = apiBlocks[idx];

      // Defer ALL image generation for instant text loading
      String? imageUrl;
      String? pendingPrompt;

      if (block.imageHint && block.imagePrompt.isNotEmpty) {
        pendingPrompt = block.imagePrompt;
      }

      // Use new fields, fallback to legacy
      final slideTitle =
          block.slideTitle.isNotEmpty
              ? block.slideTitle
              : _mapBlockTypeToTag(block.type);
      final headline =
          block.headline.isNotEmpty ? block.headline : _extractHeadline(block);
      final body = block.body.isNotEmpty ? block.body : block.text;

      blocks.add(
        LearningBlock(
          id: '${chapterId}_$idx',
          tag: slideTitle,
          headline: headline,
          content: body,
          takeaway: block.type == 'takeaway' ? body : null,
          imageUrl: imageUrl,
          pendingImagePrompt: pendingPrompt,
          estimatedReadTime: _estimateReadTime(body),
        ),
      );
    }

    return blocks;
  }

  /// Map backend block type to UI tag
  String _mapBlockTypeToTag(String type) {
    switch (type) {
      case 'scene':
        return 'SCENE';
      case 'reveal':
        return 'REVEAL';
      case 'emotion':
        return 'EMOTION';
      case 'tension':
        return 'TENSION';
      case 'insight':
        return 'INSIGHT';
      case 'quote':
        return 'QUOTE';
      case 'visual':
        return 'VISUAL';
      case 'lyric_scroll':
        return 'DEEP READ';
      // Legacy types
      case 'core_idea':
        return 'CORE IDEA';
      case 'explanation':
        return 'EXPLANATION';
      case 'example':
        return 'EXAMPLE';
      case 'takeaway':
        return 'TAKEAWAY';
      case 'nuance':
        return 'NUANCE';
      case 'contrast':
        return 'CONTRAST';
      case 'reflection':
        return 'REFLECTION';
      default:
        return type.toUpperCase().replaceAll('_', ' ');
    }
  }

  /// Extract headline from block (first sentence or type-based)
  String _extractHeadline(ContentBlock block) {
    // Prefer headline field
    if (block.headline.isNotEmpty) return block.headline;

    final text = block.body.isNotEmpty ? block.body : block.text;
    if (text.isEmpty) return block.type.toUpperCase();

    final firstSentenceEnd = text.indexOf('. ');
    if (firstSentenceEnd > 0 && firstSentenceEnd < 100) {
      return text.substring(0, firstSentenceEnd + 1);
    }
    if (text.length <= 80) {
      return text;
    }
    return '${text.substring(0, 77)}...';
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

    // Save initial state with placeholder chapters
    await saveBookState();

    // Process ONLY first chapter immediately for instant UI
    await _processChaptersInWindow(0, immediate: true);
  }

  /// Process chapters in a sliding window around current position
  /// If immediate=true, only process current chapter. Otherwise process current + next 2.
  Future<void> _processChaptersInWindow(
    int currentChapter, {
    bool immediate = false,
  }) async {
    final chaptersToProcess = <int>[];

    if (immediate) {
      // Only process the current chapter for instant loading
      if (!_processedChapters.contains(currentChapter) &&
          !_processingChapters.contains(currentChapter) &&
          currentChapter < _rawChunks.length) {
        chaptersToProcess.add(currentChapter);
      }
    } else {
      // Window: current + 2 ahead (total 3 chapters)
      for (
        int i = currentChapter;
        i < currentChapter + _chapterWindowSize && i < _rawChunks.length;
        i++
      ) {
        if (!_processedChapters.contains(i) &&
            !_processingChapters.contains(i)) {
          chaptersToProcess.add(i);
        }
      }
    }

    if (chaptersToProcess.isEmpty) {
      debugPrint('BookProvider: No chapters to process in window');
      return;
    }

    debugPrint(
      'BookProvider: Processing chapters $chaptersToProcess (immediate: $immediate)',
    );

    for (final chapterIndex in chaptersToProcess) {
      await _processChapter(chapterIndex);
    }

    // After processing immediate chapter, trigger background prefetch
    if (immediate && currentChapter == 0) {
      debugPrint(
        'BookProvider: Chapter 1 loaded, prefetching 2 & 3 in background',
      );
      // Don't await - let it run in background
      _processChaptersInWindow(0, immediate: false);
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
    _isLoadingChapter = true;
    _loadingChapterIndex = chapterIndex;
    _loadingStartTime = DateTime.now();
    _loadingError = null;
    notifyListeners();

    final chunk = _rawChunks[chapterIndex];
    final chapterNum = chapterIndex + 1;

    debugPrint(
      'BookProvider: Processing chapter $chapterNum (${chunk.length} chars)...',
    );

    // Validate chunk before sending - API requires 100-15000 chars
    if (chunk.trim().length < 100) {
      debugPrint(
        'BookProvider: Chunk too short (${chunk.length} chars), using fallback',
      );
      if (_currentBook != null) {
        final updatedChapters = List<Chapter>.from(_currentBook!.chapters);
        updatedChapters[chapterIndex] = _createFallbackChapter(
          chapterIndex,
          chunk,
        );
        _currentBook = _currentBook!.copyWith(chapters: updatedChapters);
      }
      _processedChapters.add(chapterIndex);
      _processingChapters.remove(chapterIndex);
      _isLoadingChapter = _processingChapters.isNotEmpty;
      if (!_isLoadingChapter) {
        _loadingChapterIndex = null;
        _loadingStartTime = null;
      }
      notifyListeners();
      return;
    }

    // Truncate if too long
    final validChunk = chunk.length > 15000 ? chunk.substring(0, 15000) : chunk;

    try {
      await _waitForRateLimit();

      final response = await _apiClient?.generateSummary(
        textChunk: validChunk,
        mode: 'chapter',
        bookId: _currentBookId!,
        chapterTitle: 'Chapter $chapterNum',
      );

      Chapter newChapter;

      if (response != null && response.blocks.isNotEmpty) {
        final blocks = await _convertBlocksToLearningBlocks(
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
      }

      _processedChapters.add(chapterIndex);

      // Save state after successful processing
      await saveBookState();

      // Trigger background image generation for this chapter
      // This runs without awaiting to allow UI to update instantly
      _triggerBackgroundBlockProcessing(newChapter);
    } catch (e) {
      debugPrint('BookProvider: Error processing chapter $chapterNum: $e');
      _loadingError = 'Error generating content. Using original text...';
      if (_currentBook != null) {
        final updatedChapters = List<Chapter>.from(_currentBook!.chapters);
        updatedChapters[chapterIndex] = _createFallbackChapter(
          chapterIndex,
          chunk,
        );
        _currentBook = _currentBook!.copyWith(chapters: updatedChapters);
      }
      _processedChapters.add(chapterIndex);

      // Save state even after error (fallback chapter created)
      await saveBookState();
    } finally {
      _processingChapters.remove(chapterIndex);
      _isLoadingChapter = _processingChapters.isNotEmpty;
      if (!_isLoadingChapter) {
        _loadingChapterIndex = null;
        _loadingStartTime = null;
      }
      notifyListeners();
    }
  }

  /// Trigger background image generation for a processed chapter
  /// This allows text to show instantly while images pop in later
  Future<void> _triggerBackgroundBlockProcessing(Chapter chapter) async {
    debugPrint(
      'BookProvider: Triggering background image generation for chapter ${chapter.number}',
    );

    // Process first 2 images immediately (but in background)
    int generatedCount = 0;
    const immediateBatchSize = 2;

    for (final block in chapter.blocks) {
      if (block.pendingImagePrompt != null && block.imageUrl == null) {
        // Don't await the entire chain, but await individual image generation to avoid flooding
        // We use unawaited execution for the whole loop if we wanted total parallelism,
        // but here we want kindness to our server rate limits.

        if (generatedCount < immediateBatchSize) {
          // These are "high priority" images
          await generateImageForBlock(block.id);
          generatedCount++;
        }
        // The rest remain pending and will be picked up by UI lazy loading (LearningCard)
        // or we could continue processing them slowly here.
        // For now, let's just do the first few to have a nice starting experience,
        // and let the scrolling trigger the rest via LearningCard._triggerLazyImageGeneration
      }
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
    const apiMinChunkSize = 100; // Backend requires at least 100 chars

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

    // Filter out chunks that are too small for the API (< 100 chars)
    final validChunks =
        chunks.where((c) => c.trim().length >= apiMinChunkSize).toList();

    return validChunks.isEmpty ? [text] : validChunks;
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
      // Store PDF bytes for preview
      if (bytes != null) {
        _uploadedPdfBytes = Uint8List.fromList(bytes);
      }

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
  Future<void> clearCurrentBook() async {
    _currentBook = null;
    _rawChunks.clear();
    _processedChapters.clear();
    _processingChapters.clear();
    _currentBookId = null;
    _currentBookTitle = null;
    _uploadedPdfPath = null;
    _uploadedPdfContent = null;
    _uploadedPdfBytes = null;

    // Clear persisted state
    await clearPersistedState();

    notifyListeners();
  }

  /// Save current book state to SharedPreferences
  Future<void> saveBookState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save current book as JSON
      if (_currentBook != null) {
        await prefs.setString(
          _keyCurrentBook,
          jsonEncode(_currentBook!.toJson()),
        );
      } else {
        await prefs.remove(_keyCurrentBook);
      }

      // Save raw chunks
      if (_rawChunks.isNotEmpty) {
        await prefs.setStringList(_keyRawChunks, _rawChunks);
      } else {
        await prefs.remove(_keyRawChunks);
      }

      // Save processed chapters as list of indices
      if (_processedChapters.isNotEmpty) {
        await prefs.setStringList(
          _keyProcessedChapters,
          _processedChapters.map((i) => i.toString()).toList(),
        );
      } else {
        await prefs.remove(_keyProcessedChapters);
      }

      // Save metadata
      if (_currentBookId != null) {
        await prefs.setString(_keyCurrentBookId, _currentBookId!);
      } else {
        await prefs.remove(_keyCurrentBookId);
      }

      if (_currentBookTitle != null) {
        await prefs.setString(_keyCurrentBookTitle, _currentBookTitle!);
      } else {
        await prefs.remove(_keyCurrentBookTitle);
      }

      if (_uploadedPdfPath != null) {
        await prefs.setString(_keyUploadedPdfPath, _uploadedPdfPath!);
      } else {
        await prefs.remove(_keyUploadedPdfPath);
      }

      if (_uploadedPdfContent != null) {
        await prefs.setString(_keyUploadedPdfContent, _uploadedPdfContent!);
      } else {
        await prefs.remove(_keyUploadedPdfContent);
      }

      debugPrint('BookProvider: State saved to SharedPreferences');
    } catch (e) {
      debugPrint('BookProvider: Failed to save state: $e');
    }
  }

  /// Load book state from SharedPreferences
  Future<void> loadBookState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load current book
      final bookJson = prefs.getString(_keyCurrentBook);
      if (bookJson != null) {
        _currentBook = Book.fromJson(
          jsonDecode(bookJson) as Map<String, dynamic>,
        );
      }

      // Load raw chunks
      final chunks = prefs.getStringList(_keyRawChunks);
      if (chunks != null) {
        _rawChunks = chunks;
      }

      // Load processed chapters
      final processedStr = prefs.getStringList(_keyProcessedChapters);
      if (processedStr != null) {
        _processedChapters.clear();
        _processedChapters.addAll(processedStr.map((s) => int.parse(s)));
      }

      // Load metadata
      _currentBookId = prefs.getString(_keyCurrentBookId);
      _currentBookTitle = prefs.getString(_keyCurrentBookTitle);
      _uploadedPdfPath = prefs.getString(_keyUploadedPdfPath);
      _uploadedPdfContent = prefs.getString(_keyUploadedPdfContent);

      if (_currentBook != null) {
        debugPrint('BookProvider: Restored book state: ${_currentBook!.title}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('BookProvider: Failed to load state: $e');
    }
  }

  /// Generate image for a block on-demand (lazy loading)
  Future<String?> generateImageForBlock(String blockId) async {
    if (_currentBook == null || _apiClient == null) return null;

    // Find the block
    LearningBlock? targetBlock;
    int chapterIndex = -1;
    int blockIndex = -1;

    for (var i = 0; i < _currentBook!.chapters.length; i++) {
      final chapter = _currentBook!.chapters[i];
      for (var j = 0; j < chapter.blocks.length; j++) {
        if (chapter.blocks[j].id == blockId) {
          targetBlock = chapter.blocks[j];
          chapterIndex = i;
          blockIndex = j;
          break;
        }
      }
      if (targetBlock != null) break;
    }

    if (targetBlock == null || targetBlock.pendingImagePrompt == null) {
      return null;
    }

    debugPrint('BookProvider: Generating lazy image for block $blockId');

    try {
      // Get book context
      final bookTitle = _currentBookTitle ?? _currentBook?.title ?? '';

      // Generate image
      final imageUrl = await _apiClient!.generateImageUrl(
        prompt: targetBlock.pendingImagePrompt!,
        style: 'anime',
        bookTitle: bookTitle,
        characterContext: '',
      );

      if (imageUrl != null && chapterIndex >= 0 && blockIndex >= 0) {
        // Update the block with the generated image
        final updatedChapters = List<Chapter>.from(_currentBook!.chapters);
        final chapter = updatedChapters[chapterIndex];
        final updatedBlocks = List<LearningBlock>.from(chapter.blocks);

        updatedBlocks[blockIndex] = LearningBlock(
          id: targetBlock.id,
          tag: targetBlock.tag,
          headline: targetBlock.headline,
          content: targetBlock.content,
          quote: targetBlock.quote,
          takeaway: targetBlock.takeaway,
          imageUrl: imageUrl,
          pendingImagePrompt: null, // Clear pending prompt
          estimatedReadTime: targetBlock.estimatedReadTime,
        );

        updatedChapters[chapterIndex] = Chapter(
          id: chapter.id,
          title: chapter.title,
          number: chapter.number,
          blocks: updatedBlocks,
        );

        _currentBook = _currentBook!.copyWith(chapters: updatedChapters);

        // Save updated state
        await saveBookState();

        notifyListeners();
        debugPrint(
          'BookProvider: Lazy image generated and saved for block $blockId',
        );
      }

      return imageUrl;
    } catch (e) {
      debugPrint('BookProvider: Failed to generate lazy image: $e');
      return null;
    }
  }

  /// Clear persisted state from SharedPreferences
  Future<void> clearPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCurrentBook);
      await prefs.remove(_keyRawChunks);
      await prefs.remove(_keyProcessedChapters);
      await prefs.remove(_keyCurrentBookId);
      await prefs.remove(_keyCurrentBookTitle);
      await prefs.remove(_keyUploadedPdfPath);
      await prefs.remove(_keyUploadedPdfContent);
      debugPrint('BookProvider: Cleared persisted state');
    } catch (e) {
      debugPrint('BookProvider: Failed to clear persisted state: $e');
    }
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
