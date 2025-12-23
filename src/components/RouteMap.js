import { jsx as _jsx, Fragment as _Fragment, jsxs as _jsxs } from "react/jsx-runtime";
import { useEffect } from "react";
import { MapContainer, TileLayer, Marker, Polyline, useMap } from "react-leaflet";
const ChangeView = ({ center }) => {
    const map = useMap();
    useEffect(() => {
        map.setView(center, map.getZoom());
    }, [center, map]);
    return null;
};
const RouteMap = ({ coords, center }) => {
    const defaultCenter = center || coords?.[0] || [48.8566, 2.3522]; // fallback to Paris because I don't like seeing errors.
    return (_jsx("div", { style: { flex: 1, height: "100%", borderRadius: "12px", overflow: "hidden" }, children: _jsxs(MapContainer, { center: defaultCenter, zoom: 5, style: { width: "100%", height: "100%" }, children: [_jsx(ChangeView, { center: defaultCenter }), _jsx(TileLayer, { url: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" }), coords && coords.length > 0 && (_jsxs(_Fragment, { children: [_jsx(Marker, { position: coords[0] }), " ", _jsx(Marker, { position: coords[coords.length - 1] }), " ", _jsx(Polyline, { positions: coords, color: "cyan" })] }))] }) }));
};
export default RouteMap;
