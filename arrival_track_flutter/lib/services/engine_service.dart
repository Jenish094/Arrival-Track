import '../models/track.dart';

class EngineService {
  static ArrivalResult calculateArrivalTrack(
    Track currentTrack,
    int currentPosition,
    List<Track> queue,
    int etaSeconds,
  ) {
    var remainingTime = etaSeconds;
    var currentTrackRemaining = currentTrack.durationSeconds - currentPosition;

    if (remainingTime <= currentTrackRemaining) {
      return ArrivalResult(
        track: currentTrack,
        offsetSeconds: currentPosition + remainingTime,
      );
    }

    remainingTime -= currentTrackRemaining;

    for (var track in queue) {
      if (remainingTime <= track.durationSeconds) {
        return ArrivalResult(
          track: track,
          offsetSeconds: remainingTime,
        );
      }
      remainingTime -= track.durationSeconds;
    }

    // If we run out of tracks, return the last track in queue
    return ArrivalResult(
      track: queue.isNotEmpty ? queue.last : currentTrack,
      offsetSeconds: queue.isNotEmpty ? queue.last.durationSeconds : currentTrack.durationSeconds,
    );
  }
}
