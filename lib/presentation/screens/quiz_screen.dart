import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/quiz_remote_data_source.dart';

class QuizScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;

  const QuizScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _ds = QuizRemoteDataSource();
  String? _token;
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _quiz;
  Map<String, dynamic>? _attempt;
  Map<String, dynamic>? _result;

  // answers: questionId -> answer
  final Map<String, String> _answers = {};
  int _currentIndex = 0;
  bool _submitted = false;
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _token = await SecureStorage.getToken();
    if (_token == null) {
      setState(() {
        _error = 'Not authenticated';
        _loading = false;
      });
      return;
    }
    try {
      final quiz = await _ds.getQuizForLesson(widget.lessonId, _token!);
      if (quiz == null) {
        setState(() {
          _error = 'No quiz for this lesson';
          _loading = false;
        });
        return;
      }
      setState(() {
        _quiz = quiz;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _startQuiz() async {
    setState(() => _loading = true);
    try {
      final attempt = await _ds.startQuiz(_quiz!['id'], _token!);
      _stopwatch.start();
      setState(() {
        _attempt = attempt;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    _stopwatch.stop();
    final questions = (_attempt?['questions'] as List?) ?? [];
    final answers = questions.map((q) {
      return {
        'questionId': q['id'],
        'answer': _answers[q['id']] ?? '',
      };
    }).toList();

    setState(() => _loading = true);
    try {
      final result = await _ds.submitAttempt(
        _attempt!['id'],
        List<Map<String, dynamic>>.from(answers),
        _stopwatch.elapsed.inSeconds,
        _token!,
      );
      setState(() {
        _result = result;
        _submitted = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<dynamic> get _questions => (_attempt?['questions'] as List?) ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz — ${widget.lessonTitle}',
            overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _submitted
                  ? _buildResult()
                  : _attempt == null
                      ? _buildIntro()
                      : _buildQuestion(),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.blueGrey),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back')),
            ],
          ),
        ),
      );

  Widget _buildIntro() {
    final title = _quiz?['title'] ?? 'Quiz';
    final passingScore = _quiz?['passingScore'] ?? 70;
    final timeLimit = _quiz?['timeLimit'];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz, size: 64, color: Color(0xFF1A237E)),
            const SizedBox(height: 24),
            Text(title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            _infoRow(Icons.stars, 'Passing score: $passingScore%'),
            if (timeLimit != null)
              _infoRow(Icons.timer, 'Time limit: $timeLimit min'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start Quiz', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(color: Colors.blueGrey.shade700)),
          ],
        ),
      );

  Widget _buildQuestion() {
    if (_questions.isEmpty) {
      return const Center(child: Text('No questions in this quiz.'));
    }
    final q = _questions[_currentIndex];
    final qId = q['id'] as String;
    final questionText = q['questionText'] ?? '';
    final questionType = q['questionType'] ?? 'multiple_choice';
    final options = (q['options'] as List?) ?? [];
    final total = _questions.length;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: (_currentIndex + 1) / total,
          backgroundColor: Colors.grey.shade200,
          color: const Color(0xFF1A237E),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${_currentIndex + 1} of $total',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              Text('${_answers.length}/$total answered',
                  style: TextStyle(color: Colors.blueGrey.shade500)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withValues(alpha:0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF1A237E).withValues(alpha:0.2)),
                  ),
                  child: Text(questionText,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
                if (questionType == 'true_false')
                  ...[true, false].map((val) => _buildOptionTile(
                      qId, val.toString(), val ? 'True' : 'False'))
                else if (questionType == 'multiple_choice')
                  ...options.map((opt) =>
                      _buildOptionTile(qId, opt['id'], opt['text']))
                else
                  _buildShortAnswerField(qId),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_currentIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentIndex--),
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentIndex > 0) const SizedBox(width: 12),
              Expanded(
                child: _currentIndex < total - 1
                    ? ElevatedButton(
                        onPressed: () => setState(() => _currentIndex++),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white),
                        child: const Text('Next'),
                      )
                    : ElevatedButton(
                        onPressed: _answers.length < total ? null : _submit,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white),
                        child: const Text('Submit Quiz'),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile(String qId, String value, String label) {
    final selected = _answers[qId] == value;
    return GestureDetector(
      onTap: () => setState(() => _answers[qId] = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1A237E).withValues(alpha:0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF1A237E) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFF1A237E) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          ],
        ),
      ),
    );
  }

  Widget _buildShortAnswerField(String qId) => TextField(
        onChanged: (v) => setState(() => _answers[qId] = v),
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Type your answer here...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
      );

  Widget _buildResult() {
    final score = _result?['score'] ?? 0;
    final passed = _result?['passed'] ?? false;
    final correct = _result?['correctAnswers'] ?? 0;
    final total = _result?['totalQuestions'] ?? _questions.length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              passed ? Icons.emoji_events : Icons.replay,
              size: 80,
              color: passed ? Colors.amber : Colors.blueGrey,
            ),
            const SizedBox(height: 20),
            Text(
              passed ? 'You Passed! 🎉' : 'Keep Trying!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: passed ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text('$correct / $total correct',
                style:
                    TextStyle(fontSize: 16, color: Colors.blueGrey.shade600)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Lesson'),
                  ),
                ),
                if (!passed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _attempt = null;
                          _result = null;
                          _submitted = false;
                          _answers.clear();
                          _currentIndex = 0;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white),
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
