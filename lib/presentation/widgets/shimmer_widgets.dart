import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

const _kBase = Color(0xFFE0E0E0);
const _kHighlight = Color(0xFFF5F5F5);

// ── Primitive ─────────────────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

Widget _shimmer(Widget child) => Shimmer.fromColors(
      baseColor: _kBase,
      highlightColor: _kHighlight,
      child: child,
    );

// ── Course card skeleton (matches CourseCard layout) ──────────────────────────

class CourseCardSkeleton extends StatelessWidget {
  const CourseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(height: 160, radius: 16),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(height: 16),
                  const SizedBox(height: 8),
                  ShimmerBox(height: 12, width: MediaQuery.of(context).size.width * 0.55),
                  const SizedBox(height: 12),
                  Row(children: [
                    const ShimmerBox(width: 60, height: 10),
                    const SizedBox(width: 12),
                    const ShimmerBox(width: 60, height: 10),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lesson card skeleton ───────────────────────────────────────────────────────

class LessonCardSkeleton extends StatelessWidget {
  const LessonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const ShimmerBox(width: 52, height: 52, radius: 10),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(height: 14),
                  const SizedBox(height: 8),
                  ShimmerBox(
                      height: 11,
                      width: MediaQuery.of(context).size.width * 0.45),
                  const SizedBox(height: 8),
                  const ShimmerBox(height: 10, width: 80),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const ShimmerBox(width: 28, height: 28, radius: 14),
          ],
        ),
      ),
    );
  }
}

// ── Generic list-row skeleton (for sessions, payouts, users, etc.) ────────────

class ListRowSkeleton extends StatelessWidget {
  const ListRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const ShimmerBox(width: 44, height: 44, radius: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(height: 14),
                  const SizedBox(height: 7),
                  ShimmerBox(
                      height: 11,
                      width: MediaQuery.of(context).size.width * 0.4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat-card grid skeleton (for dashboards) ──────────────────────────────────

class StatCardGridSkeleton extends StatelessWidget {
  final int count;
  const StatCardGridSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: count,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ShimmerBox(width: 32, height: 32, radius: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const ShimmerBox(height: 18, width: 60),
                  const SizedBox(height: 5),
                  const ShimmerBox(height: 11, width: 80),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Convenience wrappers ──────────────────────────────────────────────────────

class CourseListSkeleton extends StatelessWidget {
  final int count;
  const CourseListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: count,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (_, __) => const CourseCardSkeleton(),
      );
}

class LessonListSkeleton extends StatelessWidget {
  final int count;
  const LessonListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: count,
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, __) => const LessonCardSkeleton(),
      );
}

class GenericListSkeleton extends StatelessWidget {
  final int count;
  const GenericListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: count,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (_, __) => const ListRowSkeleton(),
      );
}
