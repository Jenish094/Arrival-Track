import { GEOAPIFY_IP_KEY } from "./keys";

export type IpLocation = {
  lat: number;
  lon: number;
  city?: string;
  country?: string;
};

export async function getUserLocationFromIP(): Promise<IpLocation> {
  const response = await fetch(
    `https://api.geoapify.com/v1/ipinfo?apiKey=${GEOAPIFY_IP_KEY}`
  );

  if (!response.ok) {
    throw new Error("Failed to fetch IP location");
  }

  const data = await response.json();

  return {
    lat: data.location.latitude,
    lon: data.location.longitude,
    city: data.city?.name,
    country: data.country?.name
  };
}