import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../../domain/entities/review_entity.dart';
import '../blocs/review_bloc.dart';

class ReviewScreen extends StatefulWidget {
  final String courseId;
  const ReviewScreen({super.key, required this.courseId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _controller = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitReview(String token) {
    if (_controller.text.trim().isEmpty) return;
    context.read<ReviewBloc>().add(
      PostReviewEvent(widget.courseId, _controller.text.trim(), _rating, token),
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: FutureBuilder<String?>(
        future: SecureStorage.getToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final token = snapshot.data!;
          return BlocConsumer<ReviewBloc, ReviewState>(
            listener: (context, state) {
              if (state is ReviewPostSuccess) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Review posted!')));
              } else if (state is ReviewError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              if (state is ReviewLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              List<ReviewEntity> reviews = [];
              if (state is ReviewLoaded) {
                reviews = state.reviews;
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return ListTile(
                          title: Text(review.comment),
                          subtitle: Text('Rating: ${review.rating}'),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Write a review...',
                            ),
                          ),
                        ),
                        DropdownButton<int>(
                          value: _rating,
                          items: List.generate(5, (i) => i + 1)
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('$e'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _rating = val ?? 5),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () => _submitReview(token),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
