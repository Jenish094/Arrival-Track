import { OPENROUTESERVICE_API_KEY } from "./keys";
export async function getRoute(from, to) {
    const start = `${from.lon},${from.lat}`;
    const end = `${to.lon},${to.lat}`;
    const res = await fetch(`https://api.openrouteservice.org/v2/directions/driving-car?api_key=${OPENROUTESERVICE_API_KEY}&start=${start}&end=${end}`);
    if (!res.ok)
        throw new Error("Routing failed");
    const data = await res.json();
    const coords = data.features[0].geometry.coordinates.map(([lon, lat]) => [lat, lon]);
    const duration = data.features[0].properties.segments[0].duration;
    return { coords, duration };
}
