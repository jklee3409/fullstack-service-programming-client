class Repository {
  final int id;
  final String repoFullName;
  final String repoUrl;

  Repository(
      {required this.id, required this.repoFullName, required this.repoUrl});

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      id: json['id'],
      repoFullName: json['repoFullName'],
      repoUrl: json['repoUrl'],
    );
  }
}

class CommitSummary {
  final int id;
  final String commitSha;
  final String message;
  final String authorName;
  final DateTime date;
  final String summary;

  CommitSummary({
    required this.id,
    required this.commitSha,
    required this.message,
    required this.authorName,
    required this.date,
    required this.summary,
  });

  factory CommitSummary.fromJson(Map<String, dynamic> json) {
    return CommitSummary(
      id: json['id'],
      commitSha: json['commitSha'],
      message: json['originalCommitMessage'],
      authorName: json['authorName'],
      date: DateTime.parse(json['committedDate']),
      summary: json['summary'],
    );
  }
}

class CommitDetail {
  final int id;
  final String sha;
  final String authorName;
  final String message;
  final String summary;
  final String analysisDetails;
  final List<String> files;

  CommitDetail({
    required this.id,
    required this.sha,
    required this.authorName,
    required this.message,
    required this.summary,
    required this.analysisDetails,
    required this.files,
  });

  factory CommitDetail.fromJson(Map<String, dynamic> json) {
    var fileList = (json['commitFile'] as List)
        .map((e) => e['filename'].toString())
        .toList();
    return CommitDetail(
      id: json['commitId'],
      sha: json['commitSha'],
      authorName: json['authorName'],
      message: json['originalCommitMessage'],
      summary: json['summary'],
      analysisDetails: json['analysisDetails'],
      files: fileList,
    );
  }
}
