// ============================================================================
// Wonder Crayon — AI Generation Service
//
// ALL endpoints go through the unified gateway: gen.pollinations.ai
// (DeepWiki source, indexed 7 March 2026 — all legacy subdomains are proxies
//  that may return deprecation notices or 403s)
//
// Text:  POST https://gen.pollinations.ai/v1/chat/completions  (OpenAI-compat)
//        GET  https://gen.pollinations.ai/text/{prompt}        (simple fallback)
// Image: GET  https://gen.pollinations.ai/image/{prompt}
//
// Auth:  Authorization: Bearer pk_... header on EVERY request
// Models (text): openai, mistral, llama
// Models (image): flux
// ============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ── API KEYS (injected at build time via --dart-define) ──────────────────────
const String _pollinationsKey = String.fromEnvironment('POLLINATIONS_KEY');
const String _hfToken         = String.fromEnvironment('HF_TOKEN');

// ── Platform-aware request headers ───────────────────────────────────────────
// Web: browser controls Origin/UA — setting them from Dart breaks CORS.
// Android: send full headers so Cloudflare doesn't rate-limit anonymous traffic.
Map<String, String> get _baseHeaders => kIsWeb
    ? {'Accept': 'application/json, text/plain, */*'}
    : {
        'User-Agent': 'WonderCrayon/1.0 (Flutter; Android)',
        'Accept':     'application/json, text/plain, */*',
        'Origin':     'https://wondercrayon.app',
        'Referer':    'https://wondercrayon.app/',
      };

// ── Deprecation/junk response guard ──────────────────────────────────────────
// Pollinations sometimes returns a 200 OK whose entire body is a deprecation
// notice. We only reject it when the body is SHORT (< 600c) AND contains the
// telltale phrases — a real story page with a passing mention of a URL is fine.
bool _isJunkResponse(String body) {
  if (body.length > 600) return false; // real content is never this short
  final l = body.toLowerCase();
  return l.contains('important notice') ||
      l.contains('being deprecated') ||
      (l.contains('deprecated') && l.contains('please'));
}

// 1x1 white PNG — used when every image strategy fails
const String kFallbackPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVQI12NgAAIABQ'
    'AABjkB6QAAAABJRU5ErkJggg==';

bool isFallbackImage(String b64) => b64 == kFallbackPng;

// ── VisualBible — keeps art consistent across pages ───────────────────────────
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

  bool get isEmpty =>
      characterDescriptions.isEmpty && settingDescription.isEmpty;

  String get anchor => isEmpty
      ? ''
      : '$characterDescriptions, $settingDescription, $colorPalette, $moodLighting';
}

// ============================================================================
class PollinationsAI {
  int _bookSeed = 0;
  VisualBible _bible = VisualBible.empty();
  String _artStyle = 'Watercolor';

  static const Duration _textTimeout  = Duration(seconds: 90);
  static const Duration _imageTimeout = Duration(seconds: 120);

  // ── Official Pollinations text model names (from APIDOCS.md 2025) ─────────
  // These are the exact strings the API accepts. Previous sessions had wrong
  // names like 'openai-large' / 'openai-fast' which caused all text to fail.
  static const List<String> _textModels = ['openai', 'mistral', 'llama'];

  void _log(String msg, void Function(String)? onLog) {
    debugPrint('[WonderCrayon] $msg');
    onLog?.call(msg);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SESSION INIT
  // ──────────────────────────────────────────────────────────────────────────
  void initBookSession({String premise = '', String artStyle = 'Watercolor'}) {
    _bookSeed = Random().nextInt(999999999);
    _artStyle = artStyle;
    _bible    = VisualBible.empty();
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('[WonderCrayon] Session started — seed: $_bookSeed');
    debugPrint('[WonderCrayon] POLLINATIONS_KEY: '
        '${_pollinationsKey.isNotEmpty ? "SET ✅" : "EMPTY — free tier"}');
    debugPrint('[WonderCrayon] HF_TOKEN: '
        '${_hfToken.isNotEmpty ? "SET ✅" : "EMPTY"}');
    debugPrint('[WonderCrayon] Platform: ${kIsWeb ? "WEB" : "NATIVE"}');
    debugPrint('═══════════════════════════════════════════════════════════');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TEXT GENERATION
  // POST /openai first (avoids URL length limits), then GET as fallback.
  // ──────────────────────────────────────────────────────────────────────────
  Future<String?> _generateText({
    required String systemPrompt,
    required String userPrompt,
    bool jsonMode = false,
    void Function(String)? onLog,
  }) async {
    final post = await _tryTextPost(
        systemPrompt: systemPrompt, userPrompt: userPrompt,
        jsonMode: jsonMode, onLog: onLog);
    if (post != null) return post;

    final get = await _tryTextGet(
        systemPrompt: systemPrompt, userPrompt: userPrompt,
        jsonMode: jsonMode, onLog: onLog);
    if (get != null) return get;

    _log('❌ All text strategies failed.', onLog);
    return null;
  }

  // POST https://gen.pollinations.ai/v1/chat/completions
  Future<String?> _tryTextPost({
    required String systemPrompt,
    required String userPrompt,
    bool jsonMode = false,
    void Function(String)? onLog,
  }) async {
    for (final model in _textModels) {
      _log('⏳ POST /v1/chat/completions model=$model…', onLog);
      final client = http.Client();
      try {
        final payload = {
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user',   'content': userPrompt},
          ],
          'seed': _bookSeed,
          if (jsonMode) 'response_format': {'type': 'json_object'},
        };

        final headers = {
          ..._baseHeaders,
          'Content-Type': 'application/json',
          if (_pollinationsKey.isNotEmpty)
            'Authorization': 'Bearer $_pollinationsKey',
        };

        final res = await client
            .post(Uri.parse('https://gen.pollinations.ai/v1/chat/completions'),
                headers: headers, body: jsonEncode(payload))
            .timeout(_textTimeout);

        _log('📡 POST $model → ${res.statusCode} (${res.body.length}c)', onLog);

        if (res.statusCode == 200) {
          // Log first 200 chars of body so we can see what we're getting
          final preview = res.body.substring(0, min(200, res.body.length));
          _log('📄 POST $model body preview: $preview', onLog);

          if (_isJunkResponse(res.body)) {
            _log('⚠️ $model: junk/deprecation response — skip', onLog);
            continue;
          }
          try {
            final json = jsonDecode(res.body);
            final content =
                json['choices']?[0]?['message']?['content']?.toString();
            if (content != null && content.trim().isNotEmpty) {
              _log('✅ POST $model success (${content.length}c)', onLog);
              return content.trim();
            }
            _log('⚠️ POST $model: choices empty or missing', onLog);
          } catch (e) {
            _log('⚠️ POST $model JSON parse error: $e', onLog);
          }
          // Plain-text fallback if JSON parse failed
          if (res.body.trim().length > 20) {
            _log('✅ POST $model success (plain text)', onLog);
            return res.body.trim();
          }
        } else if (res.statusCode == 429) {
          _log('⚠️ $model rate-limited (429) — waiting 8s', onLog);
          await Future.delayed(const Duration(seconds: 8));
        } else {
          final snip = res.body.substring(0, min(200, res.body.length));
          _log('⚠️ POST $model HTTP ${res.statusCode}: $snip', onLog);
        }
      } catch (e) {
        _log('⚠️ POST $model exception: $e', onLog);
      } finally {
        client.close();
      }
    }
    return null;
  }

  // GET https://gen.pollinations.ai/text/{prompt}
  Future<String?> _tryTextGet({
    required String systemPrompt,
    required String userPrompt,
    bool jsonMode = false,
    void Function(String)? onLog,
  }) async {
    final user   = userPrompt.length   > 400 ? userPrompt.substring(0, 400)   : userPrompt;
    final system = systemPrompt.length > 300 ? systemPrompt.substring(0, 300) : systemPrompt;

    for (final model in _textModels.take(2)) {
      _log('⏳ GET text model=$model…', onLog);
      final client = http.Client();
      try {
        final uri = Uri.https('gen.pollinations.ai', '/text/$user', {
          'model': model,
          'seed':  '$_bookSeed',
          'system': system,
          if (jsonMode) 'json': 'true',
        });

        final headers = {
          ..._baseHeaders,
          if (_pollinationsKey.isNotEmpty)
            'Authorization': 'Bearer $_pollinationsKey',
        };

        final res = await client
            .get(uri, headers: headers)
            .timeout(_textTimeout);

        _log('📡 GET $model → ${res.statusCode} (${res.body.length}c)', onLog);

        if (res.statusCode == 200) {
          // Always log a preview so we can debug rejection reasons
          final preview = res.body.substring(0, min(200, res.body.length));
          _log('📄 GET $model body preview: $preview', onLog);

          if (_isJunkResponse(res.body)) {
            _log('⚠️ GET $model: junk response — skip', onLog);
            continue;
          }
          if (res.body.trim().length > 10) {
            _log('✅ GET $model success (${res.body.trim().length}c)', onLog);
            return res.body.trim();
          }
          _log('⚠️ GET $model: body too short', onLog);
        } else if (res.statusCode == 429) {
          _log('⚠️ GET $model rate-limited (429) — waiting 8s', onLog);
          await Future.delayed(const Duration(seconds: 8));
        } else {
          final snip = res.body.substring(0, min(200, res.body.length));
          _log('⚠️ GET $model HTTP ${res.statusCode}: $snip', onLog);
        }
      } catch (e) {
        _log('⚠️ GET $model exception: $e', onLog);
      } finally {
        client.close();
      }
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VISUAL BIBLE
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> buildVisualBible(String premise, String title,
      {void Function(String)? onLog}) async {
    if (premise.isEmpty) return;
    _log('📖 Building visual bible…', onLog);

    final response = await _generateText(
      systemPrompt:
          'You are a book art director. Respond ONLY with a JSON '
          'object with keys: "characters", "setting", "colorPalette", '
          '"moodLighting". One short descriptive sentence each.',
      userPrompt: 'Premise: $premise. Title: $title.',
      jsonMode: true,
      onLog: onLog,
    );

    if (response != null) {
      final parsed = _tryParseJson(response);
      if (parsed != null) {
        _bible = VisualBible(
          characterDescriptions: (parsed['characters'] ?? '').toString(),
          settingDescription:    (parsed['setting']    ?? '').toString(),
          colorPalette:          (parsed['colorPalette']?? '').toString(),
          moodLighting:          (parsed['moodLighting'] ?? '').toString(),
        );
        _log('✅ Visual Bible ready', onLog);
        return;
      }
    }
    _log('⚠️ Visual bible skipped — continuing without it', onLog);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STORY TEXT
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<String>> generateStoryText(
      String prompt, int numPages, String title,
      {void Function(String)? onLog}) async {
    _log('✍️ Generating story ($numPages pages)…', onLog);

    final response = await _generateText(
      systemPrompt:
          'You are a creative story writer for a general audience. Write a story in '
          'exactly $numPages parts. Separate each part ONLY with ||| '
          '(three pipe characters). Do NOT number the parts. '
          'Do NOT include a title, heading, byline, or any preamble — '
          'begin IMMEDIATELY with the first story part.',
      userPrompt: 'Title: "$title". Story about: $prompt.',
      onLog: onLog,
    );

    if (response != null) {
      final parts = _splitStoryText(response, numPages);
      if (parts.length >= numPages) {
        _log('✅ Got ${parts.length} pages', onLog);
        return parts.sublist(0, numPages);
      }
      while (parts.length < numPages) parts.add('And so the magic continued…');
      return parts;
    }

    return List.generate(numPages, (i) => 'The adventure continued on page ${i + 1}…');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // IMAGE GENERATION
  // GET https://image.pollinations.ai/prompt/{prompt}
  // ──────────────────────────────────────────────────────────────────────────
  Future<String> generateImage(
    String pageText,
    String artStyle, {
    int pageIndex = 0,
    int totalPages = 1,
    void Function(String)? onLog,
  }) async {
    final seed   = _bookSeed + (pageIndex * 7);
    final prompt = _buildImagePrompt(pageText);

    _log('🎨 Image ${pageIndex + 1}/$totalPages | prompt: '
        '${prompt.substring(0, min(60, prompt.length))}…', onLog);

    // Try 768×512 first, then 512×512 if that fails
    for (final size in [
      {'w': 768, 'h': 512},
      {'w': 512, 'h': 512},
    ]) {
      final result = await _tryImagePollinations(
          prompt, seed, size['w']!, size['h']!, onLog);
      if (result != null) return result;
    }

    // HuggingFace fallback (only if token set)
    if (_hfToken.isNotEmpty) {
      final hf = await _tryHF(prompt, seed, onLog);
      if (hf != null) return hf;
    }

    _log('❌ All image strategies failed — using placeholder', onLog);
    return kFallbackPng;
  }

  Future<String?> _tryImagePollinations(
      String prompt, int seed, int w, int h,
      void Function(String)? onLog) async {
    final client = http.Client();
    try {
      // Canonical image endpoint (DeepWiki, indexed 7 March 2026):
      //   GET https://gen.pollinations.ai/image/{prompt}
      // Auth: pk_ keys must be sent as Bearer header — "lack Turnstile protection"
      // means they bypass the Cloudflare challenge only when properly authenticated.
      final encodedPrompt = Uri.encodeComponent(prompt);
      final queryParams = <String, String>{
        'seed':    '$seed',
        'width':   '$w',
        'height':  '$h',
        'nologo':  'true',
        'enhance': 'false',
        'model':   'flux',
      };

      final uri = Uri.parse(
        'https://gen.pollinations.ai/image/$encodedPrompt'
        '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}',
      );
      _log('⏳ GET image ${w}×${h}…', onLog);

      final res = await client.get(uri, headers: {
        ..._baseHeaders,
        'Accept': 'image/jpeg,image/png,image/*,*/*',
        // pk_ keys bypass Turnstile only when sent as Bearer header
        if (_pollinationsKey.isNotEmpty)
          'Authorization': 'Bearer $_pollinationsKey',
      }).timeout(_imageTimeout);

      final ct = res.headers['content-type'] ?? '';
      if (res.statusCode == 200 &&
          ct.contains('image/') &&
          res.bodyBytes.length > 1000) {
        _log('✅ Image ${w}×${h} OK (${res.bodyBytes.length} bytes)', onLog);
        return base64Encode(res.bodyBytes);
      }

      if (res.statusCode == 429) {
        _log('⚠️ Image rate-limited (429) — waiting 10s', onLog);
        await Future.delayed(const Duration(seconds: 10));
      } else {
        final snip = res.body.length > 100 ? res.body.substring(0, 100) : res.body;
        _log('⚠️ Image ${w}×${h} → ${res.statusCode} ct=$ct | $snip', onLog);
      }
    } catch (e) {
      _log('⚠️ Image ${w}×${h} exception: $e', onLog);
    } finally {
      client.close();
    }
    return null;
  }

  Future<String?> _tryHF(
      String prompt, int seed, void Function(String)? onLog) async {
    // HuggingFace Inference API does NOT send CORS headers → always fails in browser.
    // Skip entirely on web; only attempt on native (Android/iOS/desktop).
    if (kIsWeb) {
      _log('⚠️ HF skipped on web (CORS not supported)', onLog);
      return null;
    }
    const models = [
      'black-forest-labs/FLUX.1-schnell',
      'stabilityai/stable-diffusion-xl-base-1.0',
    ];
    for (final model in models) {
      final client = http.Client();
      try {
        _log('⏳ HF $model…', onLog);
        final res = await client
            .post(
              Uri.parse('https://api-inference.huggingface.co/models/$model'),
              headers: {
                ..._baseHeaders,
                'Authorization': 'Bearer $_hfToken',
                'Content-Type':  'application/json',
              },
              body: jsonEncode({'inputs': prompt, 'parameters': {'seed': seed}}),
            )
            .timeout(const Duration(seconds: 60));

        if (res.statusCode == 200 && res.bodyBytes.length > 1000) {
          _log('✅ HF $model OK (${res.bodyBytes.length} bytes)', onLog);
          return base64Encode(res.bodyBytes);
        }
        _log('⚠️ HF $model → ${res.statusCode}', onLog);
      } catch (e) {
        _log('⚠️ HF $model exception: $e', onLog);
      } finally {
        client.close();
      }
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────────────────
  String _buildImagePrompt(String pageText) {
    final style  = _stylePrefix(_artStyle);
    final anchor = _bible.anchor;
    // Keep under 400 chars — safe for Android URL limits and Pollinations
    final text = pageText.length > 180 ? pageText.substring(0, 180) : pageText;
    final suffix = 'book illustration, high quality, no text, no words';
    final raw = anchor.isNotEmpty
        ? '$style, $anchor, $text, $suffix'
        : '$style, $text, $suffix';
    return raw.length > 400 ? raw.substring(0, 400) : raw;
  }

  String _stylePrefix(String s) => switch (s) {
    'Watercolor'  => 'soft watercolor painting, paper texture, ink outlines',
    'Comic Book'  => 'vibrant comic book art, clean lines, cel shaded',
    'Oil Painting'=> 'classic oil painting, thick brushstrokes, rich colors',
    'Claymation'  => 'handcrafted claymation, plasticine texture',
    _             => 'detailed digital illustration',
  };

  List<String> _splitStoryText(String response, int numPages) {
    // Try ||| first
    var parts = response.split('|||').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.length >= numPages) return parts;

    // Numbered headings
    final numbered = RegExp(
        r'(?:^|\n)\s*(?:\*{0,2})(?:Part|Page|Chapter)?\s*\d+[.:\)]\s*(?:\*{0,2})\s*',
        caseSensitive: false);
    if (numbered.hasMatch(response)) {
      parts = response.split(numbered).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.length >= numPages) return parts;
    }

    // Double newlines
    parts = response.split(RegExp(r'\n\s*\n')).map((s) => s.trim()).where((s) => s.length > 20).toList();
    if (parts.length >= numPages) return parts;

    // Sentence split
    final sentences = response.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.trim().isNotEmpty).toList();
    if (sentences.length >= numPages) {
      final per = (sentences.length / numPages).ceil();
      parts = List.generate(numPages, (i) {
        final start = i * per;
        final end = min((i + 1) * per, sentences.length);
        return start < sentences.length ? sentences.sublist(start, end).join(' ') : '';
      }).where((s) => s.isNotEmpty).toList();
      if (parts.length >= numPages) return parts;
    }

    return [response.trim()];
  }

  Map<String, dynamic>? _tryParseJson(String raw) {
    try {
      var s = raw.trim();
      if (s.startsWith('```')) {
        s = s.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll(RegExp(r'\n?```$'), '').trim();
      }
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
