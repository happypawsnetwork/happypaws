"use client";

import { useState, useMemo, useEffect, useCallback } from "react";
import {
  APIProvider,
  Map,
  AdvancedMarker,
  Pin,
  useMap,
} from "@vis.gl/react-google-maps";
import { Locate, Loader2 } from "lucide-react";
import { AdminRescueMapCase, updateRescueUrgency } from "@/actions/rescues";

type RescueMapClientProps = {
  cases: AdminRescueMapCase[];
  apiKey: string;
};

type CameraTarget = {
  lat: number;
  lng: number;
  zoom?: number;
  key?: number;
};

// Smoothly moves the map camera when target coordinates change
function MapController({ target }: { target: CameraTarget | null }) {
  const map = useMap();

  useEffect(() => {
    if (!map || !target) return;
    map.panTo({ lat: target.lat, lng: target.lng });
    if (target.zoom !== undefined) {
      map.setZoom(target.zoom);
    }
  }, [map, target]);

  return null;
}

export function RescueMapClient({ cases, apiKey }: RescueMapClientProps) {
  const [selectedCase, setSelectedCase] = useState<AdminRescueMapCase | null>(
    null,
  );
  const [isUpdating, setIsUpdating] = useState(false);
  const [userLocation, setUserLocation] = useState<{
    lat: number;
    lng: number;
  } | null>(null);
  const [cameraTarget, setCameraTarget] = useState<CameraTarget | null>(null);
  const [isLocating, setIsLocating] = useState(false);

  // Filter cases that actually have location data
  const mapCases = useMemo(
    () => cases.filter((c) => c.latitude != null && c.longitude != null),
    [cases],
  );

  // Default to a central location if no cases, else use the first case
  const defaultCenter = useMemo(
    () =>
      mapCases.length > 0
        ? { lat: mapCases[0].latitude!, lng: mapCases[0].longitude! }
        : { lat: 7.8731, lng: 80.7718 },
    [mapCases],
  );

  // Request browser geolocation to focus the map on the user's area
  const requestUserLocation = useCallback((isManual = false) => {
    if (typeof window === "undefined" || !("geolocation" in navigator)) {
      return;
    }

    setIsLocating(true);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const coords = {
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        };
        setUserLocation(coords);
        setCameraTarget({ ...coords, zoom: 12, key: Date.now() });
        setIsLocating(false);
      },
      (error) => {
        // Fall back gracefully to existing cases if permission is denied
        console.warn(
          "Geolocation request denied or unavailable:",
          error.message,
        );
        setIsLocating(false);
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: isManual ? 0 : 60000,
      },
    );
  }, []);

  // Ask for location permission on visit
  useEffect(() => {
    requestUserLocation();
  }, [requestUserLocation]);

  const getUrgencyColor = (level: string | null) => {
    switch (level?.toLowerCase()) {
      case "critical":
        return "#ef4444"; // red-500
      case "moderate":
        return "#f59e0b"; // amber-500
      case "low":
        return "#22c55e"; // green-500
      default:
        return "#94a3b8"; // slate-400
    }
  };

  const handleUrgencyUpdate = async (level: string) => {
    if (!selectedCase) return;
    setIsUpdating(true);
    try {
      const result = await updateRescueUrgency(selectedCase.id, level);
      if (result.success) {
        // Optimistically update the selected case
        setSelectedCase({ ...selectedCase, urgencyLevel: level });
      } else {
        console.error("Failed to update urgency:", result.error);
      }
    } catch (error) {
      console.error(error);
    } finally {
      setIsUpdating(false);
    }
  };

  return (
    <div className="w-full h-full relative flex rounded-xl overflow-hidden border border-slate-200">
      <div className="absolute top-4 left-4 z-10">
        <button
          type="button"
          onClick={() => requestUserLocation(true)}
          disabled={isLocating}
          className="flex items-center gap-2 px-3 py-2 bg-white hover:bg-slate-50 text-slate-700 text-xs font-medium rounded-lg shadow-md border border-slate-200 transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-60"
          aria-label="Focus my location"
        >
          {isLocating ? (
            <Loader2 className="h-4 w-4 animate-spin text-blue-600" />
          ) : (
            <Locate className="h-4 w-4 text-blue-600" />
          )}
          <span>{isLocating ? "Locating..." : "My location"}</span>
        </button>
      </div>

      <APIProvider apiKey={apiKey}>
        <Map
          defaultZoom={mapCases.length > 0 ? 10 : 4}
          defaultCenter={defaultCenter}
          mapId="rescue_map_id"
          className="w-full h-full"
          disableDefaultUI={true}
          zoomControl={true}
        >
          <MapController target={cameraTarget} />

          {/* Current user location indicator */}
          {userLocation && (
            <AdvancedMarker
              position={userLocation}
              title="Your location"
              zIndex={1000}
            >
              <div className="relative flex items-center justify-center">
                <span className="absolute h-7 w-7 rounded-full bg-blue-500/30 animate-ping" />
                <span className="relative flex h-4 w-4 rounded-full border-2 border-white bg-blue-600 shadow-md ring-2 ring-blue-500/50" />
              </div>
            </AdvancedMarker>
          )}

          {mapCases.map((c) => (
            <AdvancedMarker
              key={c.id}
              position={{ lat: c.latitude!, lng: c.longitude! }}
              onClick={() => setSelectedCase(c)}
            >
              <Pin
                background={getUrgencyColor(c.urgencyLevel)}
                borderColor="#ffffff"
                glyphColor="#ffffff"
              />
            </AdvancedMarker>
          ))}
        </Map>
      </APIProvider>

      {selectedCase && (
        <div className="absolute top-4 right-4 w-80 bg-white rounded-lg shadow-xl border border-slate-200 p-4 z-10 flex flex-col max-h-[calc(100%-2rem)] overflow-y-auto">
          <div className="flex justify-between items-start mb-2">
            <h3 className="font-semibold text-slate-900 leading-tight">
              {selectedCase.title}
            </h3>
            <button
              onClick={() => setSelectedCase(null)}
              className="text-slate-400 hover:text-slate-600 focus:outline-none"
              aria-label="Close"
            >
              &times;
            </button>
          </div>

          <div className="text-sm text-slate-600 mb-4 space-y-1">
            <p>
              <span className="font-medium text-slate-700">Animal:</span>{" "}
              {selectedCase.animalName || "Unknown"} (
              {selectedCase.animalSpecies || "Unknown"})
            </p>
            <p>
              <span className="font-medium text-slate-700">Status:</span>{" "}
              {selectedCase.status}
            </p>
            {selectedCase.locationLabel && (
              <p>
                <span className="font-medium text-slate-700">Location:</span>{" "}
                {selectedCase.locationLabel}
              </p>
            )}
            <div className="mt-2 pt-2 border-t border-slate-100">
              <p className="font-medium text-slate-700 mb-1">
                AI Triage Reason:
              </p>
              <p className="italic text-xs text-slate-500">
                {selectedCase.aiTriageReason || "No reasoning provided."}
              </p>
            </div>
          </div>

          <div className="mt-auto">
            <p className="text-sm font-medium text-slate-700 mb-2">
              Update Urgency
            </p>
            <div className="flex gap-2">
              {["Critical", "Moderate", "Low"].map((level) => (
                <button
                  key={level}
                  disabled={isUpdating}
                  onClick={() => handleUrgencyUpdate(level)}
                  className={`flex-1 py-1.5 text-xs font-medium rounded-md border transition-colors ${
                    selectedCase.urgencyLevel?.toLowerCase() ===
                    level.toLowerCase()
                      ? "bg-slate-800 text-white border-slate-800"
                      : "bg-white text-slate-700 border-slate-200 hover:bg-slate-50"
                  } disabled:opacity-50 disabled:cursor-not-allowed flex justify-center items-center`}
                >
                  {
                    isUpdating &&
                      selectedCase.urgencyLevel?.toLowerCase() !==
                        level.toLowerCase() &&
                      false /* simplify loader */
                  }
                  {level}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
