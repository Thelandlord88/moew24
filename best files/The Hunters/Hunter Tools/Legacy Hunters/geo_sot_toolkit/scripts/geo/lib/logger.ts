export type Level = "debug" | "info" | "warn" | "error";

export function makeLogger(quiet = false) {
  const log = (lvl: Level, ...args: any[]) => {
    if (quiet && (lvl === "info" || lvl === "debug")) return;
    const fn =
      lvl === "warn" ? console.warn :
      lvl === "error" ? console.error :
      console.log;
    fn(`[${lvl}]`, ...args);
  };

  return {
    debug: (...a: any[]) => log("debug", ...a),
    info:  (...a: any[]) => log("info",  ...a),
    warn:  (...a: any[]) => log("warn",  ...a),
    error: (...a: any[]) => log("error", ...a),
  };
}
