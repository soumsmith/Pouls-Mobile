class Video {
  final String typeVideo;
  final String youtubeUrl;

  const Video({
    required this.typeVideo,
    required this.youtubeUrl,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      typeVideo: json['type_video'] ?? '',
      youtubeUrl: json['youtube_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type_video': typeVideo,
      'youtube_url': youtubeUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Video &&
        other.typeVideo == typeVideo &&
        other.youtubeUrl == youtubeUrl;
  }

  @override
  int get hashCode => typeVideo.hashCode ^ youtubeUrl.hashCode;

  @override
  String toString() => 'Video(typeVideo: $typeVideo, youtubeUrl: $youtubeUrl)';
}
