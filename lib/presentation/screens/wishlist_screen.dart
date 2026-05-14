import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../../domain/entities/course_entity.dart';
import '../blocs/wishlist_bloc.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: FutureBuilder<String?>(
        future: SecureStorage.getToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final token = snapshot.data!;
          // Dispatch LoadWishlistEvent if state is WishlistInitial
          return BlocConsumer<WishlistBloc, WishlistState>(
            listener: (context, state) {
              if (state is WishlistAddSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to wishlist!')),
                );
              } else if (state is WishlistError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              if (state is WishlistInitial) {
                // Trigger loading
                context.read<WishlistBloc>().add(LoadWishlistEvent(token));
                return const Center(child: CircularProgressIndicator());
              }
              if (state is WishlistLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              List<CourseEntity> wishlist = [];
              if (state is WishlistLoaded) {
                wishlist = state.wishlist;
              }
              return ListView.builder(
                itemCount: wishlist.length,
                itemBuilder: (context, index) {
                  final item = wishlist[index];
                  return ListTile(
                    title: Text(item.title),
                    subtitle: Text(item.description),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
