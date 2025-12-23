// demo/src/utils/geocode.ts
const GEOCODE_API_KEY = "04ede0df350d452c864df267a5292c82";
export async function geocodeAddress(address) {
    try {
        const res = await fetch(`https://api.geoapify.com/v1/geocode/search?text=${encodeURIComponent(address)}&limit=1&apiKey=${GEOCODE_API_KEY}`);
        if (!res.ok) {
            console.error("Geocode request failed");
            return null;
        }
        const data = await res.json();
        if (!data.features || data.features.length === 0) {
            console.warn("No geocode results for:", address);
            return null;
        }
        const { lat, lon } = data.features[0].properties;
        return [lat, lon];
    }
    catch (err) {
        console.error("Geocode error:", err);
        return null;
    }
}
