"use client";

import { useState, useMemo } from "react";
import {
  APIProvider,
  Map,
  AdvancedMarker,
  Pin,
} from "@vis.gl/react-google-maps";
import { AdminRescueMapCase, updateRescueUrgency } from "@/actions/rescues";

type RescueMapClientProps = {
  cases: AdminRescueMapCase[];
  apiKey: string;
};

export function RescueMapClient({ cases, apiKey }: RescueMapClientProps) {
  const [selectedCase, setSelectedCase] = useState<AdminRescueMapCase | null>(
    null,
  );
  const [isUpdating, setIsUpdating] = useState(false);

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
        : { lat: 39.8283, lng: -98.5795 },
    [mapCases],
  );

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
      <APIProvider apiKey={apiKey}>
        <Map
          defaultZoom={mapCases.length > 0 ? 10 : 4}
          defaultCenter={defaultCenter}
          mapId="rescue_map_id"
          className="w-full h-full"
          disableDefaultUI={true}
          zoomControl={true}
        >
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
