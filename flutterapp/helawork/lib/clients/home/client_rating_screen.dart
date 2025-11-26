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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientRatingProvider>(context, listen: false)
          .fetchEmployerRateableTasks()
          .then((_) {
        Provider.of<ClientRatingProvider>(context, listen: false);
      });
    });
  }

  void _showRatingDialog(BuildContext context, dynamic task) {
    final ratingProvider = Provider.of<ClientRatingProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (ctx) {
        return _RatingDialogContent(
          task: task,
          employerId: widget.employerId,
          ratingProvider: ratingProvider,
          blue: blue,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text("Rate Completed Work"),
        backgroundColor: blue,
        foregroundColor: white,
        centerTitle: true,
      ),
      body: Consumer<ClientRatingProvider>(
        builder: (context, provider, child) {
          final tasks = provider.tasksForRating;
          final taskCount = tasks.length;

          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Loading completed tasks...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 70, color: Colors.red),
                  const SizedBox(height: 10),
                  Text(
                    "Error Loading Tasks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: blue),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: blue),
                    onPressed: () {
                      Provider.of<ClientRatingProvider>(context, listen: false)
                          .fetchEmployerRateableTasks();
                    },
                    child: const Text("Try Again", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          if (taskCount == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_turned_in, size: 70, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text(
                    "No Completed Tasks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "You don't have any completed tasks ready for rating.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: blue),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Back to Tasks", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: blue.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Rate Freelancer Performance",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rate freelancers based on their work quality, communication, and professionalism",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: taskCount,
                  itemBuilder: (context, index) {
                    if (index < 0 || index >= taskCount) {
                      return _buildErrorCard("Invalid task data at index $index");
                    }
                    
                    final task = tasks[index];
                    
                    if (task == null) {
                      return _buildErrorCard("Task data is null at index $index");
                    }
                    
                    return _buildTaskCard(task);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    final freelancerName = task['freelancer']?['username'] ?? 
                          task['assigned_user']?['username'] ?? 
                          task['contract']?['freelancer']?['username'] ?? 
                          'Unknown Freelancer';
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task['title'] ?? 'Untitled Task',
              style: TextStyle(
                color: blue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task['description'] ?? 'No description provided',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: blue.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: blue,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Completed by: $freelancerName",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  onPressed: () => _showRatingDialog(context, task),
                  child: const Text(
                    "Rate Work",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingDialogContent extends StatefulWidget {
  final dynamic task;
  final int employerId;
  final ClientRatingProvider ratingProvider;
  final Color blue;

  const _RatingDialogContent({
    required this.task,
    required this.employerId,
    required this.ratingProvider,
    required this.blue,
  });

  @override
  State<_RatingDialogContent> createState() => _RatingDialogContentState();
}

class _RatingDialogContentState extends State<_RatingDialogContent> {
  int selectedRating = 3;
  final TextEditingController reviewController = TextEditingController();
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final freelancerName = widget.task['freelancer']?['username'] ?? 
                          widget.task['assigned_user']?['username'] ?? 
                          widget.task['contract']?['freelancer']?['username'] ?? 
                          'the freelancer';
    final freelancerId = widget.task['freelancer']?['id'] ?? 
                        widget.task['assigned_user']?['id'] ?? 
                        widget.task['contract']?['freelancer']?['id'];
    final taskId = widget.task['id'] ?? widget.task['task_id'];
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text("Rate Work Quality", style: TextStyle(color: widget.blue)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.task['title'] ?? 'Task',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Completed by: $freelancerName",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            const Text(
              "How would you rate the quality of work?",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    size: 32,
                    color: index < selectedRating ? Colors.amber : Colors.grey,
                  ),
                  onPressed: isSubmitting ? null : () {
                    setState(() {
                      selectedRating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 10),
            Text(
              "$selectedRating / 5 Stars",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              "Additional Feedback (Optional):",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reviewController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Share your experience with this freelancer...",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              enabled: !isSubmitting,
            ),
            if (isSubmitting) ...[
              const SizedBox(height: 15),
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text("Submitting your rating...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.blue),
          onPressed: isSubmitting ? null : () => _submitRating(freelancerId, taskId),
          child: Text(
            isSubmitting ? "Submitting..." : "Submit Rating",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Future<void> _submitRating(int? freelancerId, int? taskId) async {
    if (freelancerId == null || taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Could not identify freelancer or task"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await widget.ratingProvider.submitEmployerRating(
        taskId: taskId,
        freelancerId: freelancerId,
        score: selectedRating,
        review: reviewController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Rating submitted successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit rating: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }
}