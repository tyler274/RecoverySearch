"use client";

import { useEffect } from "react";
import {
  Circle,
  MapContainer,
  Marker,
  Popup,
  TileLayer,
  useMap,
} from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import Link from "next/link";

// Fix Leaflet's default marker icon paths when bundled.
const icon = L.icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconRetinaUrl:
    "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
});

export interface MapMarker {
  id: string;
  slug: string;
  name: string;
  lat: number;
  lng: number;
}

export interface FacilityMapProps {
  markers: MapMarker[];
  center?: { lat: number; lng: number } | null;
  radiusKm?: number;
}

function FitBounds({ markers, center }: Omit<FacilityMapProps, "radiusKm">) {
  const map = useMap();
  useEffect(() => {
    const points: [number, number][] = markers.map((m) => [m.lat, m.lng]);
    if (center) points.push([center.lat, center.lng]);
    if (points.length === 1) {
      map.setView(points[0], 11);
    } else if (points.length > 1) {
      map.fitBounds(points, { padding: [40, 40], maxZoom: 13 });
    }
  }, [map, markers, center]);
  return null;
}

export default function FacilityMapInner({
  markers,
  center,
  radiusKm,
}: FacilityMapProps) {
  const fallbackCenter: [number, number] = center
    ? [center.lat, center.lng]
    : markers.length
      ? [markers[0].lat, markers[0].lng]
      : [39.8283, -98.5795]; // geographic center of the contiguous US

  return (
    <MapContainer
      center={fallbackCenter}
      zoom={5}
      scrollWheelZoom
      style={{ height: "100%", width: "100%" }}
    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      {center && radiusKm ? (
        <Circle
          center={[center.lat, center.lng]}
          radius={radiusKm * 1000}
          pathOptions={{ color: "#0d9488", fillOpacity: 0.08 }}
        />
      ) : null}
      {markers.map((m) => (
        <Marker key={m.id} position={[m.lat, m.lng]} icon={icon}>
          <Popup>
            <Link href={`/facilities/${m.slug}`} className="font-medium">
              {m.name}
            </Link>
          </Popup>
        </Marker>
      ))}
      <FitBounds markers={markers} center={center} />
    </MapContainer>
  );
}
