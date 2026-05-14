import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/progress_bloc.dart';

class LessonDetailScreen extends StatefulWidget {
  final String enrollmentId;
  final String lessonId;
  final String lessonTitle;
  final String videoUrl;
  final String token;

  const LessonDetailScreen({
    Key? key,
    required this.enrollmentId,
    required this.lessonId,
    required this.lessonTitle,
    required this.videoUrl,
    required this.token,
  }) : super(key: key);

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  int watchedDuration = 0;
  bool isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lessonTitle)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player Placeholder
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.black,
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 80,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lessonTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('45 minutes'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProgressBar(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildLessonDescription(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: watchedDuration / 45,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$watchedDuration / 45 minutes watched'),
            Text(
              '${((watchedDuration / 45) * 100).toStringAsFixed(1)}%',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              context.read<ProgressBloc>().add(
                UpdateLessonProgressEvent(
                  widget.enrollmentId,
                  widget.lessonId,
                  45,
                  widget.token,
                ),
              );
              setState(() => watchedDuration = 45);
            },
            child: const Text('Save Progress'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: !isCompleted
                ? () {
                    context.read<ProgressBloc>().add(
                      MarkLessonCompleteEvent(
                        widget.enrollmentId,
                        widget.lessonId,
                        widget.token,
                      ),
                    );
                    setState(() => isCompleted = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lesson marked as complete'),
                      ),
                    );
                  }
                : null,
            child: Text(isCompleted ? 'Completed ✓' : 'Mark Complete'),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this lesson',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'In this lesson, you\'ll learn the fundamentals of Dart programming language. We\'ll cover variables, data types, functions, and control flow. By the end of this lesson, you\'ll be able to write basic Dart programs.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'Resources',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildResourceLink('Dart Documentation', Icons.description),
        _buildResourceLink('Source Code', Icons.code),
        _buildResourceLink('Quiz', Icons.quiz),
      ],
    );
  }

  Widget _buildResourceLink(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}
