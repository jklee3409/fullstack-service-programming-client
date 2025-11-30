import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import 'commit_detail_screen.dart';

class CommitListScreen extends StatefulWidget {
  final Repository repository;
  const CommitListScreen({super.key, required this.repository});

  @override
  State<CommitListScreen> createState() => _CommitListScreenState();
}

class _CommitListScreenState extends State<CommitListScreen> {
  List<dynamic> _groupedCommits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCommits();
  }

  Future<void> _fetchCommits() async {
    final api = Provider.of<AppProvider>(context, listen: false).api;
    try {
      final data = await api.getCommits(widget.repository.id, 0);
      setState(() {
        _groupedCommits = data['groups'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101922),
        title: Text(widget.repository.repoFullName,
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _groupedCommits.length,
              itemBuilder: (context, index) {
                final group = _groupedCommits[index];
                final date = DateTime.parse(group['date']);
                final commits = (group['commits'] as List)
                    .map((e) => CommitSummary.fromJson(e))
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        DateFormat.yMMMMd().format(date),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...commits.map((commit) => _buildCommitCard(commit)),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCommitCard(CommitSummary commit) {
    return Card(
      color: const Color(0xFF101922),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommitDetailScreen(commitId: commit.id),
              ));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(commit.message,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                commit.summary,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.grey,
                      child: Text(commit.authorName[0])),
                  const SizedBox(width: 8),
                  Text(commit.authorName,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const Spacer(),
                  Text(commit.commitSha.substring(0, 7),
                      style: const TextStyle(
                          color: Color(0xFF137FEC), fontSize: 12)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
