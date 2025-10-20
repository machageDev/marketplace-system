// employer_ratings_screen.dart
import 'package:flutter/material.dart';
import 'package:helawork/clients/provider/employer_rating_provider.dart';
import 'package:provider/provider.dart';

class EmployerRatingsScreen extends StatelessWidget {
  final String token;

  const EmployerRatingsScreen({required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Ratings')),
      body: FutureBuilder(
        future: Provider.of<EmployerRatingProvider>(context, listen: false)
            .loadRatings(token),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final ratings = Provider.of<EmployerRatingProvider>(context).ratings;
          if (ratings.isEmpty) {
            return const Center(child: Text('No ratings yet.'));
          }
          return ListView.builder(
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              final r = ratings[index];
              return ListTile(
                title: Text('${r['freelancer_name']} rated you ⭐${r['score']}'),
                subtitle: Text(r['review'] ?? 'No review'),
                trailing: Text(r['task_title']),
              );
            },
          );
        },
      ),
    );
  }
}
