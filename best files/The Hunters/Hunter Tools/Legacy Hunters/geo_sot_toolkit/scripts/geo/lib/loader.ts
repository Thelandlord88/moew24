export type GeoRuntime = {
  clusters(): Promise<any[]> | any[];
  adjacency(): Promise<Record<string,string[]>> | Record<string,string[]>;
};

export async function loadGeoRuntime(): Promise<{ rt: GeoRuntime; runtimeFallback: boolean }> {
  try {
    const mod = await import("../../src/lib/geoCompat.runtime.js");
    return { rt: (mod as unknown as GeoRuntime), runtimeFallback: false };
  } catch {
    const alt = await import("../../src/lib/geoCompat.js");
    return { rt: (alt as unknown as GeoRuntime), runtimeFallback: true };
  }
}
