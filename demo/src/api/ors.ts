const ORS_API_KEY = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6Ijc4ODFmZDlkNzNjOTQ2MWZhMDRkNmM4ZDA4ZmYxMTI4IiwiaCI6Im11cm11cjY0In0";

// find travel time in seconds
export const getTravelTime = async (origin: string, destination: string): Promise<number> => {
  const url = `https://api.openrouteservice.org/v2/directions/driving-car?api_key=${ORS_API_KEY}&start=${encodeURIComponent(origin)}&end=${encodeURIComponent(destination)}`;
  
  try {
    const response = await fetch(url);
    const data = await response.json();
    
    // ORS returns travel time in seconds at data.features[0].properties.summary.duration
    return data.features?.[0]?.properties?.summary?.duration || 600; //10 min fallback
  } catch (err) {
    console.error(err);
    return 600;
  }
};

// autocomplete suggestions for addresses
export const getAddressSuggestions = async (input: string): Promise<string[]> => {
  const url = `https://api.openrouteservice.org/geocode/autocomplete?api_key=${ORS_API_KEY}&text=${encodeURIComponent(input)}&size=5`;
  
  try {
    const res = await fetch(url);
    const data = await res.json();
    return data.features?.map((f: any) => f.properties.label) || [];
  } catch (err) {
    console.error(err);
    return [];
  }
};
