import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/ai/scanbite_ai_gateway.dart';

class AiFoodQuestionScreen extends StatefulWidget {
  const AiFoodQuestionScreen({super.key});

  @override
  State<AiFoodQuestionScreen> createState() => _AiFoodQuestionScreenState();
}

class _AiFoodQuestionScreenState extends State<AiFoodQuestionScreen> {
  final TextEditingController _controller = TextEditingController();

  String _question = '';
  String _response = '';
  bool _loading = false;

  Future<void> _askQuestion() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _loading = true;
      _question = question;
      _response = '';
    });

    try {
      final prompt = '''
You are ScanBite's AI food assistant.

Answer this food question in plain English only:
"$question"

IMPORTANT:
- Do not return JSON
- Do not use code blocks
- Do not use braces { }
- Write like a friendly nutrition guide
- Use bullet points
- Keep it short and clear
- Do not give medical advice

End with one simple recommendation.
''';

      final aiResponse = await ScanBiteAIGateway.text(prompt: prompt);

      setState(() {
        _response = _cleanAiResponse(aiResponse);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _response = 'Unable to get answer right now. Please try again.';
        _loading = false;
      });
    }
  }

  // 🔥 CLEAN + FORMAT AI RESPONSE
  String _cleanAiResponse(String raw) {
    String text = raw.trim();

    text = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    try {
      final decoded = jsonDecode(text);

      final buffer = StringBuffer();

      void format(dynamic value) {
        if (value is Map) {
          value.forEach((key, val) {
            final cleanKey = key
                .toString()
                .replaceAll('_', ' ')
                .replaceAll('-', ' ');

            if (val is Map || val is List) {
              buffer.writeln('\n${_capitalize(cleanKey)}:');
              format(val);
            } else {
              buffer.writeln('• ${_capitalize(cleanKey)}: $val');
            }
          });
        } else if (value is List) {
          for (final item in value) {
            if (item is Map || item is List) {
              format(item);
            } else {
              buffer.writeln('• $item');
            }
          }
        }
      }

      format(decoded);

      return buffer.toString().trim();
    } catch (_) {
      return text;
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  void _quickAsk(String question) {
    _controller.text = question;
    _askQuestion();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? AppConstants.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF3),
      appBar: AppBar(
        title: const Text('Ask AI About Nutrition'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ask about ingredients, calories, or nutrition information?',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Rice nutrition facts?'),
                      onPressed:
                      _loading ? null : () => _quickAsk('Is rice healthy?'),
                    ),
                    ActionChip(
                      label: const Text('Pizza nutrition estimate?'),
                      onPressed:
                      _loading ? null : () => _quickAsk('Pizza nutrition estimate?'),
                    ),
                    ActionChip(
                      label: const Text('Foods with lower calorie estimates'),
                      onPressed: _loading
                          ? null
                          : () => _quickAsk(
                          'Examples of lower calorie foods'),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _askQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Ask AI'),
                  ),
                ),

                const SizedBox(height: 20),

                if (_question.isNotEmpty)
                  _bubble(_question, true),

                if (_loading)
                  _bubble('Thinking...', false),

                if (_response.isNotEmpty)
                  _bubble(_response, false),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Educational information only. Not medical advice.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}