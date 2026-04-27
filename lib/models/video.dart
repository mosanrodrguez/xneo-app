class Video {
  final String id;
  final String title;
  final String? videoUrl;
  final String? thumbnail;
  final int views;
  final int likes;
  final int dislikes;
  final int duration;
  final String? category;
  final String uploaderName;
  final String? uploaderAvatar;
  final String userId;
  final DateTime uploadDate;
  final String? description;

  Video({
    required this.id,
    required this.title,
    this.videoUrl,
    this.thumbnail,
    required this.views,
    required this.likes,
    required this.dislikes,
    required this.duration,
    this.category,
    required this.uploaderName,
    this.uploaderAvatar,
    required this.userId,
    required this.uploadDate,
    this.description,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Sin título',
      videoUrl: json['videoUrl'] ?? json['video_url'],
      thumbnail: json['thumbnailUrl'] ?? json['thumbnail'],
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      dislikes: json['dislikes'] ?? 0,
      duration: json['duration'] ?? 0,
      category: json['category'],
      uploaderName: json['uploaderName'] ?? json['uploader_name'] ?? 'Usuario',
      uploaderAvatar: json['uploaderAvatar'] ?? json['uploader_avatar'],
      userId: json['userId'] ?? json['user_id'] ?? '',
      uploadDate: DateTime.tryParse(json['uploadDate'] ?? json['upload_date'] ?? '') ?? DateTime.now(),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnail,
      'views': views,
      'likes': likes,
      'dislikes': dislikes,
      'duration': duration,
      'category': category,
      'uploaderName': uploaderName,
      'uploaderAvatar': uploaderAvatar,
      'userId': userId,
      'uploadDate': uploadDate.toIso8601String(),
      'description': description,
    };
  }
}
