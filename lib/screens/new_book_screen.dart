// ============================================================================
// New Book Screen — with live debug log panel and onLog callback wired up
// ============================================================================

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:animated_background/animated_background.dart';
import '../providers/book_provider.dart';
import '../providers/settings_provider.dart';
import '../helpers/pollinations_ai.dart';
import '../models/book.dart';
import 'story_book_screen.dart';

class NewBookScreen extends StatefulWidget {
  static const routeName = '/new-book';
  const NewBookScreen({super.key});

  @override
  State<NewBookScreen> createState() => _NewBookScreenState();
}

class _NewBookScreenState extends State<NewBookScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _promptController = TextEditingController();

  bool _isGenerating = false;
  String _generatingStatus = '';
  double _progress = 0;
  int _numPages = 3;
  String _selectedArtStyle = 'Watercolor';
  bool _useCustomPageText = false;

  // Live debug log shown inside the loading overlay so you can see
  // exactly what's happening without opening Chrome DevTools.
  final List<String> _debugLogs = [];
  final ScrollController _logScrollController = ScrollController();

  final List<String> _artStyles = [
    'Watercolor',
    'Comic Book',
    'Oil Painting',
    'Claymation',
  ];

  List<TextEditingController> _pageControllers = [];

  @override
  void initState() {
    super.initState();
    _rebuildPageControllers();
  }

  void _rebuildPageControllers() {
    final oldTexts = _pageControllers.map((c) => c.text).toList();
    for (var c in _pageControllers) {
      c.dispose();
    }
    _pageControllers = List.generate(_numPages, (i) {
      return TextEditingController(
        text: i < oldTexts.length ? oldTexts[i] : '',
      );
    });
  }

  // Called by PollinationsAI for every log message.
  // Adds to the visible list and auto-scrolls to bottom.
  void _addLog(String msg) {
    if (!mounted) return;
    setState(() {
      _debugLogs.add(msg);
    });
    // Auto-scroll to latest log entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _promptController.dispose();
    _logScrollController.dispose();
    for (var c in _pageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Create a New Book',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: _isGenerating ? null : () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBackground(
                vsync: this,
                behaviour: RandomParticleBehaviour(
                  options: ParticleOptions(
                    baseColor: settingsProvider.particleColor,
                    particleCount: 60,
                    spawnMinSpeed: 10,
                    spawnMaxSpeed: 50,
                    spawnMinRadius: 1,
                    spawnMaxRadius: 3,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        settingsProvider.primaryGradientStart,
                        settingsProvider.primaryGradientEnd,
                        const Color(0xFF764ba2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Form content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _titleController,
                        label: 'Book Title',
                        icon: Icons.auto_stories,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please enter a title'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _authorController,
                        label: 'Author Name',
                        icon: Icons.person_outline,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please enter an author name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _promptController,
                        label: 'Story Premise',
                        icon: Icons.auto_awesome,
                        hint: 'e.g. A detective who can taste lies...',
                        maxLines: 3,
                        validator: (val) {
                          if (!_useCustomPageText &&
                              (val == null || val.trim().isEmpty)) {
                            return 'Please enter a story idea';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Settings card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF667eea)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.tune,
                                      color: Color(0xFF667eea)),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Settings',
                                  style: TextStyle(
                                    color: Color(0xFF2D3436),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              initialValue: _numPages,
                              decoration: InputDecoration(
                                labelText: 'Number of pages',
                                labelStyle:
                                const TextStyle(color: Colors.black54),
                                filled: true,
                                fillColor: const Color(0xFFF5F6FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Color(0xFF2D3436)),
                              items: [2, 3, 4, 5, 6, 7, 8, 9, 10]
                                  .map((e) => DropdownMenuItem<int>(
                                value: e,
                                child: Text('$e pages'),
                              ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _numPages = val;
                                    _rebuildPageControllers();
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedArtStyle,
                              decoration: InputDecoration(
                                labelText: 'Art Style',
                                labelStyle:
                                const TextStyle(color: Colors.black54),
                                filled: true,
                                fillColor: const Color(0xFFF5F6FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.palette,
                                    color: Color(0xFF667eea)),
                              ),
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Color(0xFF2D3436)),
                              items: _artStyles
                                  .map((s) => DropdownMenuItem<String>(
                                value: s,
                                child: Text(s),
                              ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedArtStyle = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Custom per-page text toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF667eea)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.edit_note,
                                        color: Color(0xFF667eea)),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Write Each Page Manually',
                                      style: TextStyle(
                                        color: Color(0xFF2D3436),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _useCustomPageText
                                      ? 'You write the text for each page.'
                                      : 'AI will generate page text from your premise.',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              value: _useCustomPageText,
                              activeThumbColor: const Color(0xFF667eea),
                              onChanged: (val) {
                                setState(() => _useCustomPageText = val);
                              },
                            ),
                            if (_useCustomPageText) ...[
                              const SizedBox(height: 16),
                              ...List.generate(_numPages, (i) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextFormField(
                                    controller: _pageControllers[i],
                                    maxLines: 3,
                                    style: const TextStyle(
                                      color: Color(0xFF2D3436),
                                      fontSize: 15,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Page ${i + 1}',
                                      hintText:
                                      'What happens on page ${i + 1}?',
                                      labelStyle: const TextStyle(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500),
                                      hintStyle: const TextStyle(
                                          color: Colors.black38),
                                      filled: true,
                                      fillColor: const Color(0xFFF5F6FA),
                                      prefixIcon: Padding(
                                        padding:
                                        const EdgeInsets.only(bottom: 40),
                                        child: CircleAvatar(
                                          radius: 14,
                                          backgroundColor:
                                          const Color(0xFF667eea),
                                          child: Text(
                                            '${i + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF667eea),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    validator: (val) =>
                                    val == null || val.trim().isEmpty
                                        ? 'Please enter text for page ${i + 1}'
                                        : null,
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Generate button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667eea)
                                  .withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isGenerating ? null : _generateBook,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome,
                                  color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                _useCustomPageText
                                    ? 'Generate AI Illustrations'
                                    : 'Generate My Book',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Loading overlay with live debug log ────────────────────────────
          if (_isGenerating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.92),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Crafting your story…',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _progress > 0 ? _progress : null,
                            minHeight: 8,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF667eea)),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Status line
                        Text(
                          _generatingStatus,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This can take 2–8 minutes. Your story is worth the wait! ✨',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Live debug log panel
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF667eea)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Panel header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF667eea)
                                        .withValues(alpha: 0.2),
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(11)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.terminal,
                                          color: Color(0xFF667eea), size: 14),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Live Log',
                                        style: TextStyle(
                                          color: Color(0xFF667eea),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${_debugLogs.length} messages',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.4),
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          final text = _debugLogs.join('\n');
                                          await Clipboard.setData(
                                              ClipboardData(text: text));
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                              content: Text(
                                                  '✅ Logs copied to clipboard!'),
                                              duration: Duration(seconds: 2),
                                              backgroundColor:
                                              Color(0xFF00B894),
                                            ));
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF667eea)
                                                .withValues(alpha: 0.3),
                                            borderRadius:
                                            BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Copy',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Scrollable log entries
                                Expanded(
                                  child: ListView.builder(
                                    controller: _logScrollController,
                                    padding: const EdgeInsets.all(10),
                                    itemCount: _debugLogs.length,
                                    itemBuilder: (context, index) {
                                      final msg = _debugLogs[index];
                                      // Color-code by prefix
                                      Color msgColor = Colors.white70;
                                      if (msg.startsWith('✅')) {
                                        msgColor = const Color(0xFF00B894);
                                      } else if (msg.startsWith('❌') ||
                                          msg.contains('failed') ||
                                          msg.contains('exception')) {
                                        msgColor = const Color(0xFFE17055);
                                      } else if (msg.startsWith('⚠️')) {
                                        msgColor = const Color(0xFFfdcb6e);
                                      } else if (msg.startsWith('⏳')) {
                                        msgColor = const Color(0xFF74b9ff);
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 3),
                                        child: Text(
                                          msg,
                                          style: TextStyle(
                                            color: msgColor,
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                            height: 1.4,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Also visible in Chrome DevTools → Console (F12)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================================
  // GENERATE BOOK
  // ============================================================================

  Future<void> _generateBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _generatingStatus = 'Starting up the magic…';
      _progress = 0;
      _debugLogs.clear();
    });

    try {
      final bookProvider =
      Provider.of<BookProvider>(context, listen: false);
      final pollinationsAI = PollinationsAI();

      pollinationsAI.initBookSession(
        premise: _promptController.text.trim(),
        artStyle: _selectedArtStyle,
      );

      setState(() {
        _generatingStatus = 'Designing your characters and world…';
        _progress = 0.05;
      });
      await pollinationsAI.buildVisualBible(
        _promptController.text.trim(),
        _titleController.text.trim(),
        onLog: _addLog,
      );

      final newBookId = const Uuid().v4();
      final stylePrompt = '$_selectedArtStyle style, illustrated story';

      List<BookPage> pages;

      if (_useCustomPageText) {
        pages = List<BookPage>.generate(_numPages, (i) {
          return BookPage(
            pageNumber: i + 1,
            textContent: _pageControllers[i].text.trim(),
            imagePath: '',
            isImageGenerated: false,
          );
        });
      } else {
        setState(() {
          _generatingStatus = 'Writing your story…';
          _progress = 0.1;
        });

        final storyTexts = await pollinationsAI.generateStoryText(
          _promptController.text.trim(),
          _numPages,
          _titleController.text.trim(),
          onLog: _addLog,
        );

        pages = List<BookPage>.generate(_numPages, (i) {
          return BookPage(
            pageNumber: i + 1,
            textContent: storyTexts[i],
            imagePath: '',
            isImageGenerated: false,
          );
        });
      }

      // Generate all images
      for (int i = 0; i < pages.length; i++) {
        setState(() {
          _generatingStatus =
          'Painting illustration ${i + 1} of ${pages.length}…';
          _progress = 0.15 + (i + 1) / pages.length * 0.85;
        });

        try {
          final imageBase64 = await pollinationsAI.generateImage(
            pages[i].textContent,
            _selectedArtStyle,
            pageIndex: i,
            totalPages: pages.length,
            onLog: _addLog,
          );
          pages[i].imagePath = imageBase64;
          pages[i].isImageGenerated = true;
        } catch (e) {
          _addLog('❌ Image ${i + 1} exception: $e');
        }
      }

      String coverImage = '';
      for (var p in pages) {
        if (p.isImageGenerated && p.imagePath.isNotEmpty) {
          coverImage = p.imagePath;
          break;
        }
      }

      final newBook = Book(
        id: newBookId,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        createdAt: DateTime.now(),
        prompt: _useCustomPageText
            ? pages.map((p) => p.textContent).join(' | ')
            : _promptController.text.trim(),
        stylePrompt: stylePrompt,
        pages: pages,
        coverImagePath: coverImage,
        artStyle: _selectedArtStyle,
      );

      await bookProvider.addBook(newBook);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StoryBookScreen(book: newBook),
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Fatal error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Color(0xFF2D3436), fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
              color: Colors.black54, fontWeight: FontWeight.w500),
          hintStyle: const TextStyle(color: Colors.black38),
          prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF667eea),
              width: 2,
            ),
          ),
        ),
        validator: validator,
      ),
    );
  }
}