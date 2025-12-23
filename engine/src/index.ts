// the actual program
// I know some TypeScript from school but im still getting to the more complex aspects so mind the code

import { calculateArrivalTrack, Track } from "./engine";

// will later be replaced with fetched data from API's
const currentTrack: Track = {
    title: "Eyeless",
    durationSeconds: 236
};

const currentPositionSeconds = 45;

const queue: Track[] = [
    { title: "Domination", durationSeconds: 305 },
    { title: "Bring Me to Life", durationSeconds: 235 },
    { title: "Blackened", durationSeconds: 366 }
];

const etaSeconds = 12 * 60; //12 mins

const result = calculateArrivalTrack(
    currentTrack,
    currentPositionSeconds,
    queue,
    etaSeconds
);

//print
console.log(`ETA: ${Math.floor(etaSeconds / 60)} minutes`);
console.log(`You'll arrive ${result.offsetSeconds} seconds into "${result.track.title}"`);