import 'package:flutter/material.dart';
import 'package:helawork/clients/provider/rating_provider.dart';
import 'package:provider/provider.dart';


class ClientRatingScreen extends StatefulWidget {
  final int employerId;
  const ClientRatingScreen({super.key, required this.employerId});

  @override
  State<ClientRatingScreen> createState() => _ClientRatingScreenState();
}

class _ClientRatingScreenState extends State<ClientRatingScreen> {
  final Color blue = const Color(0xFF007BFF);
  final Color white = Colors.white;

  @override
  void initState() {
    super.initState();
    Provider.of<ClientRatingProvider>(context, listen: false)
        .fetchTasks(widget.employerId);
  }

  void _showRatingDialog(BuildContext context, dynamic task) {
    final ratingProvider = Provider.of<ClientRatingProvider>(context, listen: false);
    int selectedRating = 3;
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Rate Freelancer", style: TextStyle(color: blue)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(task['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      color: index < selectedRating ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedRating = index + 1;
                      });
                      (ctx as Element).markNeedsBuild();
                    },
                  );
                }),
              ),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Leave a review (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: blue),
              onPressed: () async {
                final success = await ratingProvider.submitRating(
                  taskId: task['task_id'],
                  freelancerId: task['assigned_user']['id'],
                  employerId: widget.employerId,
                  score: selectedRating,
                  review: reviewController.text,
                );

                if (success && mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Rating submitted successfully")),
                  );
                }
              },
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text("Rate Freelancer"),
        backgroundColor: blue,
        foregroundColor: white,
        centerTitle: true,
      ),
      body: Consumer<ClientRatingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 70, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text(
                    "No Tasks Available for Rating",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  const Text("You don't have any completed tasks to rate."),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: blue),
                    onPressed: () {},
                    child: const Text("Back to Tasks", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.tasks.length,
            itemBuilder: (context, index) {
              final task = provider.tasks[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(task['title'], style: TextStyle(color: blue, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text("Freelancer: ${task['assigned_user']['username']}",
                          style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showRatingDialog(context, task),
                    child: const Text("Rate", style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
