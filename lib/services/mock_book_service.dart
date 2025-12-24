import '../models/models.dart';

/// Mock book data service for hackathon demo.
/// Simulates Gemini API responses with pre-built content.
class MockBookService {
  /// Get sample public domain books
  static List<Book> getPublicDomainBooks() {
    return [_atomicHabitsDemo, _sapiensDemo, _psychologyOfMoney];
  }

  /// Simulate processing a book with Gemini
  /// In production, this would call the actual Gemini API
  static Future<Book> processBook(String bookId) async {
    // Simulate API processing delay
    await Future.delayed(const Duration(seconds: 3));

    // Return pre-built demo content
    return _atomicHabitsDemo;
  }

  /// Simulate uploading and processing a PDF
  static Future<Book> processUploadedPdf(String filePath) async {
    // Simulate upload and processing
    await Future.delayed(const Duration(seconds: 4));

    // Return demo content
    return _atomicHabitsDemo.copyWith(
      id: 'uploaded_${DateTime.now().millisecondsSinceEpoch}',
      source: BookSource.uploadedPdf,
    );
  }

  // ============================================
  // DEMO BOOK DATA
  // ============================================

  /// Atomic Habits demo - main showcase book
  static final Book _atomicHabitsDemo = Book(
    id: 'atomic_habits_001',
    title: 'Atomic Habits',
    author: 'James Clear',
    coverUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400',
    description:
        'Tiny changes, remarkable results. An easy and proven way to build good habits and break bad ones.',
    source: BookSource.publicDomain,
    addedAt: DateTime.now(),
    chapters: [
      Chapter(
        id: 'ch_1',
        title: 'The Fundamentals',
        number: 1,
        blocks: [
          const LearningBlock(
            id: 'block_1_1',
            tag: 'Key Concept',
            headline: 'The Power of Tiny Gains',
            content:
                'Improving by 1 percent isn\'t particularly notable—sometimes it isn\'t even noticeable—but it can be far more meaningful, especially in the long run.',
            quote: '"Habits are the compound interest of self-improvement."',
            takeaway:
                'Small daily adjustments compound into massive results over time. Focus on the trajectory, not the position.',
            imageUrl:
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600',
            estimatedReadTime: 120,
          ),
          const LearningBlock(
            id: 'block_1_2',
            tag: 'Core Insight',
            headline: 'The 1% Rule',
            content:
                'The difference a tiny improvement can make over time is astounding. If you can get 1 percent better each day for one year, you\'ll end up thirty-seven times better by the time you\'re done.',
            takeaway:
                'Conversely, if you get 1 percent worse each day for one year, you\'ll decline nearly down to zero.',
            estimatedReadTime: 90,
          ),
          const LearningBlock(
            id: 'block_1_3',
            tag: 'Mental Model',
            headline: 'Systems vs Goals',
            content:
                'Goals are about the results you want to achieve. Systems are about the processes that lead to those results.',
            quote:
                '"You do not rise to the level of your goals. You fall to the level of your systems."',
            takeaway:
                'If you want better results, forget about setting goals. Focus on your system instead.',
            imageUrl:
                'https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b?w=600',
            estimatedReadTime: 150,
          ),
        ],
      ),
      Chapter(
        id: 'ch_2',
        title: 'The Four Laws',
        number: 2,
        blocks: [
          const LearningBlock(
            id: 'block_2_1',
            tag: 'Framework',
            headline: 'Make It Obvious',
            content:
                'The first law of behavior change is to make it obvious. Many of our failures in performance are largely attributable to a lack of self-awareness.',
            takeaway:
                'Use implementation intentions: "I will [BEHAVIOR] at [TIME] in [LOCATION]."',
            estimatedReadTime: 120,
          ),
          const LearningBlock(
            id: 'block_2_2',
            tag: 'Framework',
            headline: 'Make It Attractive',
            content:
                'The second law of behavior change is to make it attractive. The more attractive an opportunity is, the more likely it is to become habit-forming.',
            quote:
                '"We need to make our habits attractive because it is the expectation of a rewarding experience that motivates us to act."',
            takeaway:
                'Use temptation bundling: Pair an action you want to do with an action you need to do.',
            estimatedReadTime: 110,
          ),
          const LearningBlock(
            id: 'block_2_3',
            tag: 'Framework',
            headline: 'Make It Easy',
            content:
                'The third law of behavior change is to make it easy. The most effective form of learning is practice, not planning.',
            takeaway:
                'Reduce friction for good habits. Increase friction for bad habits.',
            imageUrl:
                'https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=600',
            estimatedReadTime: 100,
          ),
          const LearningBlock(
            id: 'block_2_4',
            tag: 'Framework',
            headline: 'Make It Satisfying',
            content:
                'The fourth law of behavior change is to make it satisfying. We are more likely to repeat a behavior when the experience is satisfying.',
            quote:
                '"What is rewarded is repeated. What is punished is avoided."',
            takeaway:
                'Use reinforcement: Give yourself an immediate reward when you complete your habit.',
            estimatedReadTime: 130,
          ),
        ],
      ),
      Chapter(
        id: 'ch_3',
        title: 'Advanced Tactics',
        number: 3,
        blocks: [
          const LearningBlock(
            id: 'block_3_1',
            tag: 'Strategy',
            headline: 'Habit Stacking',
            content:
                'One of the best ways to build a new habit is to identify a current habit you already do each day and then stack your new behavior on top.',
            takeaway: 'Formula: "After [CURRENT HABIT], I will [NEW HABIT]."',
            estimatedReadTime: 90,
          ),
          const LearningBlock(
            id: 'block_3_2',
            tag: 'Strategy',
            headline: 'Environment Design',
            content:
                'Environment is the invisible hand that shapes human behavior. Despite our unique personalities, certain behaviors tend to arise again and again under certain environmental conditions.',
            takeaway:
                'Design your environment for success. Make the cues of good habits obvious in your environment.',
            imageUrl:
                'https://images.unsplash.com/photo-1497366216548-37526070297c?w=600',
            estimatedReadTime: 140,
          ),
          const LearningBlock(
            id: 'block_3_3',
            tag: 'Conclusion',
            headline: 'The Secret to Results',
            content:
                'The secret to getting results that last is to never stop making improvements. It\'s remarkable what you can build if you just don\'t stop.',
            quote:
                '"Success is not a goal to reach or a finish line to cross. It is a system to improve, an endless process to refine."',
            takeaway:
                'Small habits don\'t add up. They compound. That\'s the power of atomic habits.',
            estimatedReadTime: 100,
          ),
        ],
      ),
    ],
  );

  /// Sapiens demo book
  static final Book _sapiensDemo = Book(
    id: 'sapiens_001',
    title: 'Sapiens',
    author: 'Yuval Noah Harari',
    coverUrl:
        'https://images.unsplash.com/photo-1532012197267-da84d127e765?w=400',
    description:
        'A Brief History of Humankind - exploring the cognitive, agricultural, and scientific revolutions.',
    source: BookSource.publicDomain,
    addedAt: DateTime.now().subtract(const Duration(days: 2)),
    chapters: [
      Chapter(
        id: 'sapiens_ch_1',
        title: 'The Cognitive Revolution',
        number: 1,
        blocks: [
          const LearningBlock(
            id: 'sapiens_block_1_1',
            tag: 'History',
            headline: 'The Rise of Homo Sapiens',
            content:
                'About 70,000 years ago, organisms belonging to the species Homo sapiens started to form even more elaborate structures called cultures.',
            takeaway:
                'The Cognitive Revolution marks the beginning of human history as we know it.',
            estimatedReadTime: 120,
          ),
        ],
      ),
    ],
  );

  /// Psychology of Money demo
  static final Book _psychologyOfMoney = Book(
    id: 'psychology_money_001',
    title: 'The Psychology of Money',
    author: 'Morgan Housel',
    coverUrl: 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400',
    description: 'Timeless lessons on wealth, greed, and happiness.',
    source: BookSource.publicDomain,
    addedAt: DateTime.now().subtract(const Duration(days: 5)),
    chapters: [
      Chapter(
        id: 'money_ch_1',
        title: 'No One\'s Crazy',
        number: 1,
        blocks: [
          const LearningBlock(
            id: 'money_block_1_1',
            tag: 'Perspective',
            headline: 'Your Personal Money History',
            content:
                'Your personal experiences with money make up maybe 0.00000001% of what\'s happened in the world, but maybe 80% of how you think the world works.',
            quote:
                '"Spending money to show people how much money you have is the fastest way to have less money."',
            takeaway:
                'Everyone has a unique relationship with money based on their experiences.',
            estimatedReadTime: 100,
          ),
        ],
      ),
    ],
  );
}
