// Engine

export interface Track {
  title: string;
  durationSeconds: number;
}

export interface ArrivalResult {
  track: Track;
  offsetSeconds: number;
}

export function calculateArrivalTrack(
  currentTrack: Track,
  currentPosition: number,
  queue: Track[],
  etaSeconds: number
): ArrivalResult {
  let remainingTime = etaSeconds;
  let offset: number;


  const currentRemaining = currentTrack.durationSeconds - currentPosition;

  if (remainingTime < currentRemaining) {
    offset = currentPosition + remainingTime;
    return { track: currentTrack, offsetSeconds: offset };
  }

  remainingTime -= currentRemaining;

  for (const track of queue) {
    if (remainingTime < track.durationSeconds) {
      offset = remainingTime;
      return { track, offsetSeconds: offset };
    }
    remainingTime -= track.durationSeconds;
  }

  // return last track if eta exceeds the length of the qeueue
  const lastTrack = queue[queue.length - 1] || currentTrack;
  return { track: lastTrack, offsetSeconds: lastTrack.durationSeconds };
}
