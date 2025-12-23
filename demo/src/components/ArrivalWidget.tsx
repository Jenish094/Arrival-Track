import React, { useState, useEffect } from "react";
import AddressInput from "./AddressInput";
import RouteMap from "./RouteMap";
import { getUserLocationFromIP } from "../api/ip";
import { getRoute } from "../api/routing";
import { suggestAddresses } from "../api/geocode";
import { playlist, Track } from "../data/playlist";

const ArrivalWidget: React.FC = () => {
  const [origin, setOrigin] = useState("");
  const [destination, setDestination] = useState("");
  const [originCoords, setOriginCoords] = useState<[number, number] | null>(null);
  const [destinationCoords, setDestinationCoords] = useState<[number, number] | null>(null);
  const [coords, setCoords] = useState<[number, number][]>([]);
  const [eta, setEta] = useState<number | null>(null);
  const [currentTrack, setCurrentTrack] = useState<Track | null>(null);
  const [offsetSeconds, setOffsetSeconds] = useState<number>(0);
  const [mapCenter, setMapCenter] = useState<[number, number]>([48.8566, 2.3522]);

  useEffect(() => {
    getUserLocationFromIP().then((loc) => setMapCenter([loc.lat, loc.lon]));
  }, []);

  const geocode = async (addr: string) => {
    const suggestions = await suggestAddresses(addr);
    if (suggestions.length > 0) {
      const first = suggestions[0];
      return [first.lat, first.lon] as [number, number];
    }
    return null;
  };

  const calculate = async () => {
    if (!origin || !destination) return;

    const oCoords = await geocode(origin);
    const dCoords = await geocode(destination);
    if (!oCoords || !dCoords) return;

    setOriginCoords(oCoords);
    setDestinationCoords(dCoords);

    const { coords: routeCoords, duration } = await getRoute(
      { lat: oCoords[0], lon: oCoords[1] },
      { lat: dCoords[0], lon: dCoords[1] }
    );

    setCoords(routeCoords);
    setEta(duration);

    let total = 0;
    for (const track of playlist) {
      if (total + track.durationSeconds >= duration) {
        setCurrentTrack(track);
        setOffsetSeconds(duration - total);
        return;
      }
      total += track.durationSeconds;
    }
    setCurrentTrack(playlist[playlist.length - 1]);
    setOffsetSeconds(duration - total);
  };

  return (
    <div
      style={{
        display: "flex",
        height: "100vh",
        width: "100vw",
        background: "#111",
        color: "white",
        padding: "2rem",
        gap: "2rem",
      }}
    >
      <div style={{ width: "400px", display: "flex", flexDirection: "column" }}>
        <AddressInput label="Origin" value={origin} onChange={setOrigin} />
        <AddressInput label="Destination" value={destination} onChange={setDestination} />
        <button
          onClick={calculate}
          style={{
            padding: "1rem",
            background: "cyan",
            color: "#111",
            border: "none",
            borderRadius: "8px",
            fontWeight: "bold",
            cursor: "pointer",
            marginTop: "1rem",
          }}
        >
          Calculate
        </button>

        {eta !== null && currentTrack && (
          <div style={{ marginTop: "2rem", lineHeight: "1.5rem" }}>
            <div>ETA: {Math.floor(eta / 60)} mins {eta % 60} secs</div>
            <div>
              You'll be on track: <strong>{currentTrack.title}</strong> at {offsetSeconds} seconds
            </div>
          </div>
        )}
      </div>

      <RouteMap coords={coords} center={mapCenter} />
    </div>
  );
};

export default ArrivalWidget;
