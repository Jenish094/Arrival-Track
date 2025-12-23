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
    currentTrackPositionSeconds: number,
    queue: Track[],
    etaSeconds: number ): ArrivalResult {
        let remainingTime = etaSeconds;
        const currentRemaining = currentTrack.durationSeconds = currentTrackPositionSeconds;
        if (remainingTime < currentRemaining) {
            return {
                track: currentTrack,
                offsetSeconds: currentTrackPositionSeconds + remainingTime
            };
            }
            remainingTime -= currentRemaining;

            for (const track of queue) {
                if (remainingTime < track.durationSeconds) {
                    return {
                        track,
                        offsetSeconds: remainingTime
                    };
                }
                remainingTime -= track.durationSeconds;
                }

                const lastTtrack = queue[queue.length - 1];
                return {
                    track: lastTtrack,
                    offsetSeconds: lastTtrack.durationSeconds
                };
            }