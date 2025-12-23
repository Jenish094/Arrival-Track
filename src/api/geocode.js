import { GEOAPIFY_AUTOCOMPLETE_KEY } from "./keys";
export async function suggestAddresses(query) {
    if (!query)
        return [];
    const res = await fetch(`https://api.geoapify.com/v1/geocode/autocomplete?text=${encodeURIComponent(query)}&limit=5&apiKey=${GEOAPIFY_AUTOCOMPLETE_KEY}`);
    if (!res.ok)
        return [];
    const data = await res.json();
    return data.features.map((f) => ({
        label: f.properties.formatted,
        lat: f.properties.lat,
        lon: f.properties.lon
    }));
}
