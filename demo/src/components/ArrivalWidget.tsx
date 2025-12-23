import React, { useState, useEffect } from "react";
import { Track } from "../types/track";
import { getTravelTime, getAddressSuggestions } from "../api/ors";

// setlist for demo app because its a demo. doesn't fetch from music apps
const demoTracks: Track[] = [
  { title: "Song A", durationSeconds: 180 },
  { title: "Song B", durationSeconds: 240 },
  { title: "Song C", durationSeconds: 200 },
];

export const ArrivalWidget = () => {
  const [origin, setOrigin] = useState("");
  const [destination, setDestination] = useState("");
  const [originSuggestions, setOriginSuggestions] = useState<string[]>([]);
  const [destinationSuggestions, setDestinationSuggestions] = useState<string[]>([]);
  const [arrival, setArrival] = useState<Track | null>(null);
  const [arrivalOffset, setArrivalOffset] = useState(0);

  const handleOriginChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value;
    setOrigin(val);
    if (val.length > 2) {
      const suggestions = await getAddressSuggestions(val);
      setOriginSuggestions(suggestions);
    } else {
      setOriginSuggestions([]);
    }
  };

  const handleDestinationChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value;
    setDestination(val);
    if (val.length > 2) {
      const suggestions = await getAddressSuggestions(val);
      setDestinationSuggestions(suggestions);
    } else {
      setDestinationSuggestions([]);
    }
  };

  const calculateArrival = async () => {
    const travelTime = await getTravelTime(origin, destination); //seconds


    let remaining = travelTime;
    let track: Track | null = null;
    let offset = 0;

    for (const t of demoTracks) {
      if (remaining <= t.durationSeconds) {
        track = t;
        offset = remaining;
        break;
      }
      remaining -= t.durationSeconds;
    }

    if (!track) {
      track = demoTracks[demoTracks.length - 1];
      offset = track.durationSeconds;
    }

    setArrival(track);
    setArrivalOffset(offset);
  };

  return (
    <div style={{ padding: 20 }}>
      <h2>Arrival Track Demo</h2>

      <div>
        <label>Origin: </label>
        <input value={origin} onChange={handleOriginChange} />
        <ul>
          {originSuggestions.map((s, i) => (
            <li key={i} onClick={() => setOrigin(s)}>{s}</li>
          ))}
        </ul>
      </div>

      <div>
        <label>Destination: </label>
        <input value={destination} onChange={handleDestinationChange} />
        <ul>
          {destinationSuggestions.map((s, i) => (
            <li key={i} onClick={() => setDestination(s)}>{s}</li>
          ))}
        </ul>
      </div>

      <button onClick={calculateArrival}>Calculate Arrival Track</button>

      {arrival && (
        <p>
          You will be {arrivalOffset}s into "{arrival.title}" when you arrive.
        </p>
      )}
    </div>
  );
};
