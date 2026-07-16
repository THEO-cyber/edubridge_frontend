import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/http_utils.dart';
import '../../core/secure_storage.dart';

const _kPrimary = Color(0xFF1A237E);

class InstructorQuizScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;

  const InstructorQuizScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<InstructorQuizScreen> createState() => _InstructorQuizScreenState();
}

class _InstructorQuizScreenState extends State<InstructorQuizScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _quiz;
  List<Map<String, dynamic>> _questions = [];
  bool _isPublished = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, String>> _headers() async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final h = await _headers();
      final res = await apiGet(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.quizForLesson(widget.lessonId)}'),
        headers: h,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final quiz = data is Map
            ? (data['data'] ?? data['quiz'] ?? data)
            : null;
        if (quiz is Map<String, dynamic>) {
          _quiz = quiz;
          _isPublished = quiz['isPublished'] == true;
          final raw = quiz['questions'] ?? [];
          _questions = List<Map<String, dynamic>>.from(raw is List ? raw : []);
        } else {
          _quiz = null;
          _questions = [];
          _isPublished = false;
        }
      } else if (res.statusCode == 404) {
        _quiz = null;
        _questions = [];
        _isPublished = false;
      } else if (res.statusCode == 400) {
        String msg = '';
        try {
          final d = jsonDecode(res.body);
          if (d is Map) msg = (d['message'] ?? '').toString().toLowerCase();
        } catch (_) {}
        // Backend returns 400 "not yet published" for instructors too — treat as
        // "quiz exists but endpoint still applies student guard". Show a draft state
        // so the instructor can still add questions once backend fixes the check.
        if (msg.contains('not yet published') || msg.contains('not published')) {
          _quiz = {'id': '', 'title': 'Quiz (Draft)', 'isPublished': false};
          _isPublished = false;
          _questions = [];
        } else {
          throw Exception(msg.isNotEmpty ? msg : 'Failed to load quiz (${res.statusCode})');
        }
      } else {
        String msg = 'Failed to load quiz (${res.statusCode})';
        try {
          final d = jsonDecode(res.body);
          if (d is Map) msg = (d['message'] ?? d['error'] ?? msg).toString();
        } catch (_) {
          if (res.body.isNotEmpty) msg = res.body;
        }
        throw Exception(msg);
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _createQuiz() async {
    final titleCtrl = TextEditingController(text: '${widget.lessonTitle} Quiz');
    final descCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: '70');
    final durationCtrl = TextEditingController(text: '30');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Quiz'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: passCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Pass % (e.g. 70)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Duration (min)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final h = await _headers();
      final res = await apiPost(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.createQuiz(widget.lessonId)}'),
        headers: h,
        body: jsonEncode({
          'title': titleCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'passingScore': int.tryParse(passCtrl.text.trim()) ?? 70,
          'timeLimit': int.tryParse(durationCtrl.text.trim()) ?? 30,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        _snack('Quiz created!', Colors.green);
        // Use the creation response directly — avoid calling _load() which
        // may return 400 while the backend instructor-guard fix is pending.
        try {
          final created = jsonDecode(res.body);
          final quiz = created is Map
              ? Map<String, dynamic>.from(
                  created['data'] ?? created['quiz'] ?? created)
              : null;
          if (quiz != null) {
            setState(() {
              _quiz = quiz;
              _isPublished = quiz['isPublished'] == true;
              final raw = quiz['questions'] ?? [];
              _questions =
                  List<Map<String, dynamic>>.from(raw is List ? raw : []);
              _loading = false;
            });
            return;
          }
        } catch (_) {}
        await _load();
      } else {
        _snackError(res.body);
      }
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  Future<void> _addQuestion() async {
    if (_quiz == null) {
      _snack('Create a quiz first', Colors.orange);
      return;
    }
    final quizId = (_quiz!['id'] ?? _quiz!['_id'] ?? '').toString();
    await _showQuestionDialog(quizId: quizId);
  }

  Future<void> _editQuestion(Map<String, dynamic> question) async {
    final questionId =
        (question['id'] ?? question['_id'] ?? '').toString();
    await _showQuestionDialog(question: question, questionId: questionId);
  }

  Future<void> _showQuestionDialog({
    String? quizId,
    Map<String, dynamic>? question,
    String? questionId,
  }) async {
    final textCtrl =
        TextEditingController(text: (question?['text'] ?? question?['question'] ?? '').toString());
    final aCtrl = TextEditingController(
        text: _optionText(question, 0));
    final bCtrl = TextEditingController(
        text: _optionText(question, 1));
    final cCtrl = TextEditingController(
        text: _optionText(question, 2));
    final dCtrl = TextEditingController(
        text: _optionText(question, 3));
    int correctIndex = _correctIndex(question);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(question == null ? 'Add Question' : 'Edit Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: textCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Question text', isDense: true),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                const Text('Options (select correct answer):',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 6),
                ...List.generate(4, (i) {
                  final ctrl = [aCtrl, bCtrl, cCtrl, dCtrl][i];
                  final label = ['A', 'B', 'C', 'D'][i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: i,
                          groupValue: correctIndex,
                          activeColor: _kPrimary,
                          onChanged: (v) => setSt(() => correctIndex = v!),
                        ),
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            decoration: InputDecoration(
                              labelText: 'Option $label',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(question == null ? 'Add' : 'Save')),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final options = [aCtrl.text.trim(), bCtrl.text.trim(), cCtrl.text.trim(), dCtrl.text.trim()];
    if (textCtrl.text.trim().isEmpty || options.any((o) => o.isEmpty)) {
      _snack('Fill in the question and all 4 options', Colors.orange);
      return;
    }

    final body = jsonEncode({
      'text': textCtrl.text.trim(),
      'options': options,
      'correctAnswer': correctIndex,
    });

    try {
      final h = await _headers();
      late final http.Response res;
      if (questionId != null && questionId.isNotEmpty) {
        // Edit existing
        res = await apiPut(
          Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.updateQuestion(questionId)}'),
          headers: h,
          body: body,
        );
      } else {
        // Add new
        res = await apiPost(
          Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.quizQuestions(quizId!)}'),
          headers: h,
          body: body,
        );
      }
      if (res.statusCode == 200 || res.statusCode == 201) {
        _snack(questionId != null ? 'Question updated!' : 'Question added!',
            Colors.green);
        try {
          final saved = jsonDecode(res.body);
          final q = saved is Map
              ? Map<String, dynamic>.from(
                  saved['data'] ?? saved['question'] ?? saved)
              : null;
          if (q != null && q['id'] != null) {
            setState(() {
              if (questionId != null && questionId.isNotEmpty) {
                _questions = _questions
                    .map((e) => (e['id'] ?? e['_id']) == questionId ? q : e)
                    .toList();
              } else {
                _questions = [..._questions, q];
              }
            });
            return;
          }
        } catch (_) {}
        await _load();
      } else {
        _snackError(res.body);
      }
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  Future<void> _deleteQuestion(Map<String, dynamic> question) async {
    final id = (question['id'] ?? question['_id'] ?? '').toString();
    if (id.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final h = await _headers();
      final res = await apiDelete(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.deleteQuestion(id)}'),
        headers: h,
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        _snack('Question deleted', Colors.green);
        setState(() => _questions =
            _questions.where((q) => (q['id'] ?? q['_id']) != id).toList());
      } else {
        _snackError(res.body);
      }
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  Future<void> _togglePublish() async {
    if (_quiz == null) return;
    final quizId = (_quiz!['id'] ?? _quiz!['_id'] ?? '').toString();
    if (quizId.isEmpty) return;

    if (_questions.isEmpty && !_isPublished) {
      _snack('Add at least one question before publishing', Colors.orange);
      return;
    }

    try {
      final h = await _headers();
      // Publish/unpublish via PATCH /quizzes/:id (the backend's real route, which
      // accepts isPublished). The old POST /quizzes/:id/publish endpoint does not
      // exist server-side and 404s on every call, so it is only kept as a fallback.
      var res = await apiPatch(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateQuiz(quizId)}'),
        headers: h,
        body: jsonEncode({'isPublished': !_isPublished}),
      );
      if (res.statusCode == 404 || res.statusCode == 405) {
        res = await apiPost(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.publishQuiz(quizId)}'),
          headers: h,
          body: jsonEncode({'isPublished': !_isPublished}),
        );
      }
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() => _isPublished = !_isPublished);
        _snack(_isPublished ? 'Quiz published! Students can now take it.' : 'Quiz unpublished.', Colors.green);
      } else {
        _snackError(res.body);
      }
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  Future<void> _viewResults() async {
    if (_quiz == null) return;
    final quizId = (_quiz!['id'] ?? _quiz!['_id'] ?? '').toString();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => _QuizResultsScreen(quizId: quizId)),
    );
  }

  String _optionText(Map<String, dynamic>? q, int index) {
    if (q == null) return '';
    final opts = q['options'];
    if (opts is List && opts.length > index) {
      final o = opts[index];
      if (o is String) return o;
      if (o is Map) return (o['text'] ?? o['value'] ?? '').toString();
    }
    return '';
  }

  int _correctIndex(Map<String, dynamic>? q) {
    if (q == null) return 0;
    final v = q['correctAnswer'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _snackError(String body) {
    String msg = 'Operation failed';
    try {
      final d = jsonDecode(body);
      if (d is Map) msg = (d['message'] ?? d['error'] ?? msg).toString();
    } catch (_) {}
    _snack(msg, Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Quiz — ${widget.lessonTitle}'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        actions: [
          if (_quiz != null) ...[
            IconButton(
              icon: Icon(_isPublished ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              tooltip: _isPublished ? 'Unpublish Quiz' : 'Publish Quiz',
              onPressed: _togglePublish,
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'View Results',
              onPressed: _viewResults,
            ),
          ],
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: _quiz == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
              onPressed: _addQuestion,
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _quiz == null
                  ? _NoQuizView(onCreate: _createQuiz)
                  : Column(
                      children: [
                        if (!_isPublished)
                          Material(
                            color: Colors.amber[50],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_off_outlined,
                                      size: 16, color: Colors.amber[800]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Draft — students cannot see this quiz yet. '
                                      'Add questions then tap the eye icon to publish.',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.amber[900]),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _togglePublish,
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.amber[800],
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(60, 32)),
                                    child: const Text('Publish',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Expanded(
                          child: _QuizView(
                            quiz: _quiz!,
                            questions: _questions,
                            onAddQuestion: _addQuestion,
                            onEditQuestion: _editQuestion,
                            onDeleteQuestion: _deleteQuestion,
                            onViewResults: _viewResults,
                          ),
                        ),
                      ],
                    ),
    );
  }
}

// ── No quiz yet ───────────────────────────────────────────────────────────────

class _NoQuizView extends StatelessWidget {
  final VoidCallback onCreate;
  const _NoQuizView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, size: 72, color: Colors.blueGrey.shade200),
            const SizedBox(height: 16),
            const Text('No quiz for this lesson yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Create a quiz to test student knowledge',
                style: TextStyle(color: Colors.blueGrey.shade400)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quiz view with questions list ─────────────────────────────────────────────

class _QuizView extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final List<Map<String, dynamic>> questions;
  final VoidCallback onAddQuestion;
  final Function(Map<String, dynamic>) onEditQuestion;
  final Function(Map<String, dynamic>) onDeleteQuestion;
  final VoidCallback onViewResults;

  const _QuizView({
    required this.quiz,
    required this.questions,
    required this.onAddQuestion,
    required this.onEditQuestion,
    required this.onDeleteQuestion,
    required this.onViewResults,
  });

  @override
  Widget build(BuildContext context) {
    final title = (quiz['title'] ?? 'Untitled Quiz').toString();
    final passing = quiz['passingScore'] ?? quiz['passScore'] ?? 70;
    final duration = quiz['timeLimit'] ?? quiz['duration'] ?? '-';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 16,
                      children: [
                        _chip(Icons.check_circle_outline,
                            'Pass: $passing%', Colors.green),
                        _chip(Icons.timer_outlined, '$duration min',
                            Colors.blue),
                        _chip(Icons.help_outline,
                            '${questions.length} questions', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onViewResults,
                icon: const Icon(Icons.bar_chart, size: 16),
                label: const Text('Results'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.help_outline,
                          size: 56, color: Colors.blueGrey.shade200),
                      const SizedBox(height: 12),
                      const Text('No questions yet'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: onAddQuestion,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white),
                        child: const Text('Add First Question'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: questions.length,
                  itemBuilder: (_, i) => _QuestionCard(
                    index: i,
                    question: questions[i],
                    onEdit: onEditQuestion,
                    onDelete: onDeleteQuestion,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> question;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onDelete;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final text =
        (question['text'] ?? question['question'] ?? 'Question').toString();
    final opts = question['options'];
    final correctIdx = question['correctAnswer'];
    final options = opts is List ? List<dynamic>.from(opts) : <dynamic>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _kPrimary,
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(text,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (v) {
                    if (v == 'edit') onEdit(question);
                    if (v == 'delete') onDelete(question);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            if (options.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...List.generate(options.length, (i) {
                final opt = options[i];
                final label = ['A', 'B', 'C', 'D'][i < 4 ? i : 0];
                final isCorrect =
                    correctIdx is int ? i == correctIdx : false;
                final optText = opt is String
                    ? opt
                    : (opt is Map
                        ? (opt['text'] ?? opt['value'] ?? '').toString()
                        : opt.toString());
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? Colors.green
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          optText,
                          style: TextStyle(
                            fontSize: 13,
                            color: isCorrect
                                ? Colors.green.shade700
                                : Colors.black87,
                            fontWeight: isCorrect
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isCorrect)
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 16),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Quiz results screen ───────────────────────────────────────────────────────

class _QuizResultsScreen extends StatefulWidget {
  final String quizId;
  const _QuizResultsScreen({required this.quizId});

  @override
  State<_QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<_QuizResultsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final res = await apiGet(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.quizResults(widget.quizId)}'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final d = data is Map ? (data['data'] ?? data) : data;
        if (d is Map) {
          _stats = Map<String, dynamic>.from(d['stats'] ?? d['summary'] ?? {});
          final list = d['results'] ?? d['attempts'] ?? [];
          _results = List<Map<String, dynamic>>.from(list is List ? list : []);
        } else if (d is List) {
          _results = List<Map<String, dynamic>>.from(d);
        }
      } else {
        throw Exception('Failed to load results (${res.statusCode})');
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Quiz Results'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? Center(child: Text(_error!))
              : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bar_chart,
                              size: 56, color: Colors.blueGrey.shade200),
                          const SizedBox(height: 12),
                          const Text('No attempts yet'),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        if (_stats.isNotEmpty) _StatsBar(stats: _stats),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _results.length,
                            itemBuilder: (_, i) =>
                                _ResultTile(result: _results[i]),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final avg = double.tryParse(
            (stats['averageScore'] ?? stats['average'] ?? 0).toString()) ??
        0;
    final total = stats['totalAttempts'] ?? stats['total'] ?? 0;
    final passed = stats['passed'] ?? stats['passCount'] ?? 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StStat(label: 'Attempts', value: total.toString()),
          _StStat(label: 'Avg Score', value: '${avg.toStringAsFixed(1)}%'),
          _StStat(label: 'Passed', value: passed.toString()),
        ],
      ),
    );
  }
}

class _StStat extends StatelessWidget {
  final String label;
  final String value;
  const _StStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20, color: _kPrimary)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final student = result['student'] ?? result['user'] ?? {};
    final name = student is Map
        ? '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'.trim()
        : 'Student';
    final score =
        double.tryParse((result['score'] ?? result['percentage'] ?? 0).toString()) ??
            0;
    final passed = result['passed'] == true || result['hasPassed'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: passed ? Colors.green.shade50 : Colors.red.shade50,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                color: passed ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name.isEmpty ? 'Unknown Student' : name),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${score.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: passed ? Colors.green : Colors.red)),
            Text(passed ? 'Passed' : 'Failed',
                style: TextStyle(
                    fontSize: 11,
                    color: passed ? Colors.green : Colors.red)),
          ],
        ),
      ),
    );
  }
}
