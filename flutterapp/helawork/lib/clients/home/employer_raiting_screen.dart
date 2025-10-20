import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helawork/clients/provider/employer_rating_provider.dart';

class EmployerRatingsScreen extends StatefulWidget {
  final String token;

  const EmployerRatingsScreen({super.key, required this.token});

  @override
  State<EmployerRatingsScreen> createState() => _EmployerRatingsScreenState();
}

class _EmployerRatingsScreenState extends State<EmployerRatingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployerRatingProvider>(context, listen: false)
          .fetchRatings(widget.token as int);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmployerRatingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employer Ratings'),
        backgroundColor: Colors.blueAccent,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Text('Error: ${provider.errorMessage}'))
              : provider.ratings.isEmpty
                  ? const Center(child: Text('No ratings yet'))
                  : ListView.builder(
                      itemCount: provider.ratings.length,
                      itemBuilder: (context, index) {
                        final rating = provider.ratings[index];
                        return ListTile(
                          leading: const Icon(Icons.star, color: Colors.amber),
                          title: Text('Score: ${rating['score']}'),
                          subtitle: Text(rating['review'] ?? 'No review'),
                        );
                      },
                    ),
    );
  }
}
