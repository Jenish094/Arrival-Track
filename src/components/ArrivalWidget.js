import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useState, useEffect } from "react";
import AddressInput from "./AddressInput";
import RouteMap from "./RouteMap";
import { getUserLocationFromIP } from "../api/ip";
import { getRoute } from "../api/routing";
import { suggestAddresses } from "../api/geocode";
import { playlist } from "../data/playlist";
const ArrivalWidget = () => {
    const [origin, setOrigin] = useState("");
    const [destination, setDestination] = useState("");
    const [originCoords, setOriginCoords] = useState(null);
    const [destinationCoords, setDestinationCoords] = useState(null);
    const [coords, setCoords] = useState([]);
    const [eta, setEta] = useState(null);
    const [currentTrack, setCurrentTrack] = useState(null);
    const [offsetSeconds, setOffsetSeconds] = useState(0);
    const [mapCenter, setMapCenter] = useState([48.8566, 2.3522]);
    useEffect(() => {
        getUserLocationFromIP().then((loc) => setMapCenter([loc.lat, loc.lon]));
    }, []);
    const geocode = async (addr) => {
        const suggestions = await suggestAddresses(addr);
        if (suggestions.length > 0) {
            const first = suggestions[0];
            return [first.lat, first.lon];
        }
        return null;
    };
    const calculate = async () => {
        if (!origin || !destination)
            return;
        const oCoords = await geocode(origin);
        const dCoords = await geocode(destination);
        if (!oCoords || !dCoords)
            return;
        setOriginCoords(oCoords);
        setDestinationCoords(dCoords);
        const { coords: routeCoords, duration } = await getRoute({ lat: oCoords[0], lon: oCoords[1] }, { lat: dCoords[0], lon: dCoords[1] });
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
    return (_jsxs("div", { style: {
            display: "flex",
            height: "100vh",
            width: "100vw",
            background: "#111",
            color: "white",
            padding: "2rem",
            gap: "2rem",
        }, children: [_jsxs("div", { style: { width: "400px", display: "flex", flexDirection: "column" }, children: [_jsx(AddressInput, { label: "Origin", value: origin, onChange: setOrigin }), _jsx(AddressInput, { label: "Destination", value: destination, onChange: setDestination }), _jsx("button", { onClick: calculate, style: {
                            padding: "1rem",
                            background: "cyan",
                            color: "#111",
                            border: "none",
                            borderRadius: "8px",
                            fontWeight: "bold",
                            cursor: "pointer",
                            marginTop: "1rem",
                        }, children: "Calculate" }), eta !== null && currentTrack && (_jsxs("div", { style: { marginTop: "2rem", lineHeight: "1.5rem" }, children: [_jsxs("div", { children: ["ETA: ", Math.floor(eta / 60), " mins ", eta % 60, " secs"] }), _jsxs("div", { children: ["You'll be on track: ", _jsx("strong", { children: currentTrack.title }), " at ", offsetSeconds, " seconds"] })] }))] }), _jsx(RouteMap, { coords: coords, center: mapCenter })] }));
};
export default ArrivalWidget;
