import { describe, it, expect } from "vitest";
import { calculateArrivalTrack, Track } from "../engine";

describe("Arrival Engine", () => {
  const trackA: Track = { title: "Song A", durationSeconds: 120 };
  const trackB: Track = { title: "Song B", durationSeconds: 180 };
  const trackC: Track = { title: "Song C", durationSeconds: 240 };
  const queue: Track[] = [trackB, trackC];

it("should return current track if ETA is within current song", () => {
  const result = calculateArrivalTrack(trackA, 30, queue, 50);
  expect(result.track).toEqual(trackA);
  expect(result.offsetSeconds).toBe(30 + 50);
});

it("should return next track if ETA goes beyond current song", () => {
  const result = calculateArrivalTrack(trackA, 100, queue, 50); 
  expect(result.track).toEqual(trackB);
  expect(result.offsetSeconds).toBe(30);
});


  it("should return last track if ETA exceeds queue length", () => {
    const result = calculateArrivalTrack(trackA, 0, queue, 600);
    expect(result.track).toEqual(trackC);
    expect(result.offsetSeconds).toBe(trackC.durationSeconds);
  });
});
