import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../../domain/entities/course_entity.dart';
import '../blocs/wishlist_bloc.dart';
import '../blocs/enrollment_bloc_provider.dart';
import 'course_detail_screen.dart';

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await SecureStorage.getToken();
    if (mounted) {
      setState(() => _token = token);
      if (token != null && token.isNotEmpty) {
        context.read<WishlistBloc>().add(LoadWishlistEvent(token));
      }
    }
  }

  Future<void> _refresh() async {
    final token = await SecureStorage.getToken();
    if (token != null && token.isNotEmpty && mounted) {
      setState(() => _token = token);
      context.read<WishlistBloc>().add(LoadWishlistEvent(token));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 140,
              backgroundColor: _kNavy,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kNavy, _kBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'My Wishlist',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Courses saved for later',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            BlocBuilder<WishlistBloc, WishlistState>(
              builder: (context, state) {
                // Guest — the wishlist needs an account. Show a login prompt
                // instead of an endless spinner (the load never fires without a token).
                if (_token == null || _token!.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text('Log in to see your wishlist',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context)
                                  .pushNamed('/user-login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kNavy,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Login'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                if (state is WishlistInitial || state is WishlistLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: _kNavy)),
                  );
                }

                if (state is WishlistError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refresh,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kNavy,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (state is WishlistLoaded) {
                  if (state.wishlist.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_border,
                                  size: 72,
                                  color: Colors.blueGrey.shade200),
                              const SizedBox(height: 20),
                              const Text(
                                'Your wishlist is empty',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Browse courses and save your favourites here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.blueGrey.shade400,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _WishlistCard(
                          course: state.wishlist[index],
                          token: _token ?? '',
                        ),
                        childCount: state.wishlist.length,
                      ),
                    ),
                  );
                }

                return const SliverFillRemaining(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final CourseEntity course;
  final String token;

  const _WishlistCard({required this.course, required this.token});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                        ? Image.network(
                            course.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                ),
                const SizedBox(width: 12),
                // Course info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (course.instructorName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          course.instructorName!,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Star rating row
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < course.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 14,
                            color: Colors.amber,
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        course.isFree
                            ? 'Free'
                            : 'FCFA ${course.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: course.isFree ? Colors.green : _kBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Bottom action row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => EnrollmentBlocProvider(
                          child: CourseDetailScreen(
                            courseId: course.id,
                            title: course.title,
                            description: course.description,
                            imageUrl: course.imageUrl,
                            price: course.price,
                          ),
                        ),
                      ));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kNavy,
                      side: const BorderSide(color: _kNavy),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'View Course',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove from wishlist',
                  onPressed: () {
                    context.read<WishlistBloc>().add(
                          RemoveFromWishlistEvent(course.id, token),
                        );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavy, _kBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.menu_book, color: Colors.white, size: 32),
      ),
    );
  }
}
