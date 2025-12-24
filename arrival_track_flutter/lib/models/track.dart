class Track {
  final String title;
  final String artist;
  final int durationSeconds;
  final String id;

  Track({
    required this.title,
    required this.artist,
    required this.durationSeconds,
    required this.id,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      title: json['name'] ?? '',
      artist: json['artists'] != null && (json['artists'] as List).isNotEmpty
          ? json['artists'][0]['name'] ?? ''
          : '',
      durationSeconds: (json['duration_ms'] ?? 0) ~/ 1000,
      id: json['id'] ?? '',
    );
  }
}

class ArrivalResult {
  final Track track;
  final int offsetSeconds;

  ArrivalResult({required this.track, required this.offsetSeconds});
}
