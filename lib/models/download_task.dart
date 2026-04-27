enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
}

class DownloadTask {
  final String id;
  final String videoId;
  final String title;
  final String? thumbnail;
  final String url;
  final String? filePath;
  final int totalSize;
  final int downloadedSize;
  final double speed;
  final int progress;
  final DownloadStatus status;

  DownloadTask({
    required this.id,
    required this.videoId,
    required this.title,
    this.thumbnail,
    required this.url,
    this.filePath,
    this.totalSize = 0,
    this.downloadedSize = 0,
    this.speed = 0.0,
    this.progress = 0,
    this.status = DownloadStatus.pending,
  });

  DownloadTask copyWith({
    String? id,
    String? videoId,
    String? title,
    String? thumbnail,
    String? url,
    String? filePath,
    int? totalSize,
    int? downloadedSize,
    double? speed,
    int? progress,
    DownloadStatus? status,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      totalSize: totalSize ?? this.totalSize,
      downloadedSize: downloadedSize ?? this.downloadedSize,
      speed: speed ?? this.speed,
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }
}
