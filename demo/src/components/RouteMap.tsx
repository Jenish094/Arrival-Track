import React, { useEffect } from "react";
import { MapContainer, TileLayer, Marker, Polyline, useMap } from "react-leaflet";

interface Props {
  coords?: [number, number][];
  center?: [number, number];
}

const ChangeView: React.FC<{ center: [number, number] }> = ({ center }) => {
  const map = useMap();
  useEffect(() => {
    map.setView(center, map.getZoom());
  }, [center, map]);
  return null;
};

const RouteMap: React.FC<Props> = ({ coords, center }) => {
  const defaultCenter = center || coords?.[0] || [48.8566, 2.3522]; // fallback to Paris because I don't like seeing errors.
  return (
    <div style={{ flex: 1, height: "100%", borderRadius: "12px", overflow: "hidden" }}>
      <MapContainer center={defaultCenter} zoom={5} style={{ width: "100%", height: "100%" }}>
        <ChangeView center={defaultCenter} />
        <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
        {coords && coords.length > 0 && (
          <>
            <Marker position={coords[0]} /> {/* Start marker */}
            <Marker position={coords[coords.length - 1]} /> {/* End marker */}
            <Polyline positions={coords} color="cyan" />
          </>
        )}
      </MapContainer>
    </div>
  );
};

export default RouteMap;
