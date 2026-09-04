import { getRescueMapCases } from "@/actions/rescues";
import { RescueMapClient } from "@/components/admin/RescueMapClient";

export const dynamic = "force-dynamic";

export default async function RescueMapPage() {
  const cases = await getRescueMapCases();
  const apiKey = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY;

  return (
    <div className="w-full h-[calc(100vh-6rem)] mx-auto flex flex-col">
      <div className="mb-6 shrink-0">
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 font-outfit">
          Rescue map
        </h1>
        <p className="text-slate-500 mt-1 text-sm">
          Live tracking of ongoing emergency rescues and available drivers.
        </p>
      </div>

      <div className="flex-1 min-h-0">
        {apiKey ? (
          <RescueMapClient cases={cases} apiKey={apiKey} />
        ) : (
          <div className="w-full h-full flex items-center justify-center bg-slate-100 rounded-xl border border-slate-200">
            <p className="text-slate-500">
              Google Maps API key is not configured.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
