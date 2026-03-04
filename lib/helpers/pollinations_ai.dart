// ============================================================================
// Wonder Crayon — AI Generation Service (Chrome & Mobile Optimized)
// ============================================================================
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ── YOUR KEYS ────────────────────────────────────────────────────────────────
// Injected at build time via --dart-define (never hardcode secrets!)
// Local:  flutter run --dart-define=POLLINATIONS_KEY=pk_... --dart-define=HF_TOKEN=hf_...
// CI/CD:  defined as GitHub repository secrets
const String _pollinationsKey = String.fromEnvironment('POLLINATIONS_KEY');
const String _hfToken         = String.fromEnvironment('HF_TOKEN');

// 1x1 white PNG fallback
const String _kFallbackPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVQI12NgAAIABQ'
    'AABjkB6QAAAABJRU5ErkJggg==';

class VisualBible {
  final String characterDescriptions;
  final String settingDescription;
  final String colorPalette;
  final String moodLighting;

  const VisualBible({
    required this.characterDescriptions,
    required this.settingDescription,
    required this.colorPalette,
    required this.moodLighting,
  });

  factory VisualBible.empty() => const VisualBible(
    characterDescriptions: '',
    settingDescription: '',
    colorPalette: '',
    moodLighting: '',
  );

  bool get isEmpty => characterDescriptions.isEmpty && settingDescription.isEmpty;

  String get anchor => isEmpty ? '' : '$characterDescriptions, $settingDescription, $colorPalette, $moodLighting';
}

class PollinationsAI {
  int _bookSeed = 0;
  VisualBible _bible = VisualBible.empty();
  String _artStyle = 'Watercolor';

  // MODERN ENDPOINTS (Support CORS and Keys via Headers)
  static const String _textEndpoint = 'https://gen.pollinations.ai/v1/chat/completions';
  static const String _imageEndpoint = 'https://gen.pollinations.ai/image';

  static const _imgModels = ['flux', 'flux-realism', 'flux-anime'];
  static const _textModels = ['openai', 'gemini', 'mistral'];

  void _log(String msg, void Function(String)? onLog) {
    debugPrint('[WonderCrayon] $msg');
    onLog?.call(msg);
  }

  // ── AUTH HEADERS (Critical for Web & Android) ───────────────────────────────
  Map<String, String> _headers({bool isImage = false}) {
    final h = <String, String>{};
    if (!isImage) h['Content-Type'] = 'application/json';
    if (_pollinationsKey.isNotEmpty) h['Authorization'] = 'Bearer $_pollinationsKey';
    return h;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SESSION
  // ──────────────────────────────────────────────────────────────────────────

  void initBookSession({String premise = '', String artStyle = 'Watercolor'}) {
    _bookSeed = Random().nextInt(999999999);
    _artStyle = artStyle;
    _bible = VisualBible.empty();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TEXT GENERATION (Visual Bible & Story)
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> buildVisualBible(String premise, String title, {void Function(String)? onLog}) async {
    if (premise.isEmpty) return;
    _log('Building visual bible...', onLog);

    final systemPrompt = 'Respond ONLY with a JSON object. Keys: "characters", "setting", "colorPalette", "moodLighting". One descriptive sentence each.';
    final userPrompt = 'Premise: $premise. Title: $title.';

    final response = await _postText(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      model: 'openai',
      jsonMode: true,
      onLog: onLog,
    );

    if (response != null) {
      final parsed = _tryParseJson(response);
      if (parsed != null) {
        _bible = VisualBible(
          characterDescriptions: parsed['characters'] ?? '',
          settingDescription: parsed['setting'] ?? '',
          colorPalette: parsed['colorPalette'] ?? '',
          moodLighting: parsed['moodLighting'] ?? '',
        );
        _log('✅ Visual Bible ready.', onLog);
      }
    }
  }

  Future<List<String>> generateStoryText(String prompt, int numPages, String title, {void Function(String)? onLog}) async {
    _log('Generating story text...', onLog);
    final systemPrompt = 'Write a children\'s story in exactly $numPages parts. Use descriptive sensory language. Separate parts ONLY with |||.';
    final userPrompt = 'Title: $title. Story about: $prompt.';

    final response = await _postText(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      model: 'openai',
      onLog: onLog,
    );

    if (response != null) {
      final parts = response.split('|||').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.length >= numPages) return parts.sublist(0, numPages);
      _log('⚠️ Only got ${parts.length} pages, filling in...', onLog);
      while(parts.length < numPages) parts.add("And so the magic continued...");
      return parts;
    }
    return List.generate(numPages, (i) => "The adventure continued on page ${i+1}...");
  }

  Future<String?> _postText({
    required String systemPrompt,
    required String userPrompt,
    required String model,
    bool jsonMode = false,
    void Function(String)? onLog,
  }) async {
    try {
      final body = {
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt}
        ],
        'seed': _bookSeed,
        if (jsonMode) 'response_format': {'type': 'json_object'}
      };

      final res = await http.post(
        Uri.parse(_textEndpoint),
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 45));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['choices'][0]['message']['content'];
      }
      _log('❌ Text API Error: ${res.statusCode}', onLog);
    } catch (e) {
      _log('❌ Text Request Error: $e', onLog);
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // IMAGE GENERATION
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> generateImage(String pageText, String artStyle, {int pageIndex = 0, int totalPages = 1, void Function(String)? onLog}) async {
    final seed = _bookSeed + (pageIndex * 7);
    final prompt = _buildImagePrompt(pageText);

    _log('Generating image ${pageIndex + 1}/$totalPages...', onLog);

    // Primary: Pollinations (Authenticated)
    for (final model in _imgModels) {
      try {
        final uri = Uri.parse('$_imageEndpoint/${Uri.encodeComponent(prompt)}?model=$model&seed=$seed&width=1024&height=768&nologo=true');

        // Passing key via header works for BOTH web and mobile now
        final res = await http.get(uri, headers: _headers(isImage: true))
            .timeout(const Duration(seconds: 60));

        if (res.statusCode == 200 && res.bodyBytes.length > 1000) {
          _log('✅ Image success with $model', onLog);
          return base64Encode(res.bodyBytes);
        }
      } catch (e) {
        _log('⚠️ $model failed: $e', onLog);
      }
    }

    // Secondary: HuggingFace Fallback (using your HF Token)
    if (_hfToken.isNotEmpty) {
      _log('Trying HuggingFace fallback...', onLog);
      final hfResult = await _tryHF(prompt, seed, onLog);
      if (hfResult != null) return hfResult;
    }

    return _generatePlaceholder(artStyle);
  }

  Future<String?> _tryHF(String prompt, int seed, void Function(String)? onLog) async {
    try {
      // Using Flux-Schnell on HuggingFace Inference API
      final uri = Uri.parse('https://api-inference.huggingface.co/models/black-forest-labs/FLUX.1-schnell');
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_hfToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {'seed': seed},
        }),
      ).timeout(const Duration(seconds: 45));

      if (res.statusCode == 200) return base64Encode(res.bodyBytes);
    } catch (e) {
      _log('❌ HF Error: $e', onLog);
    }
    return null;
  }

  String _buildImagePrompt(String pageText) {
    final style = _stylePrefix(_artStyle);
    final anchor = _bible.anchor;
    return '$style, $anchor, scene: $pageText, high quality, children\'s book illustration, no text';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  String _stylePrefix(String artStyle) => switch (artStyle) {
    'Watercolor' => 'Soft watercolor painting, paper texture, ink outlines',
    'Comic Book' => 'Vibrant comic book art, clean lines, cel shaded',
    'Oil Painting' => 'Classic oil painting, thick brushstrokes, rich colors',
    'Claymation' => 'Handcrafted claymation, plasticine texture, studio lighting',
    _ => 'Detailed digital illustration, 4k'
  };

  Map<String, dynamic>? _tryParseJson(String raw) {
    try {
      final cleaned = raw.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) { return null; }
  }

  String _generatePlaceholder(String artStyle) => _kFallbackPng;
}