class VideoModel {
  final int id;
  final String title;
  final String videoUrl;
  final String thumbnailUrl;
  final String username;
  final String pictureUrl;

  VideoModel({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.username,
    required this.pictureUrl,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'],
      title: json['title'] ?? '',
      videoUrl: json['video_link'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      username: json['username'] ?? '',
      pictureUrl: json['picture_url'] ?? '',
    );
  }
}
