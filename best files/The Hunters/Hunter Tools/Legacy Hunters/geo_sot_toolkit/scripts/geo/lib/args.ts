export type Args = {
  json?: boolean;
  out?: string;
  profile?: boolean;
  quiet?: boolean;
  strict?: boolean;
  help?: boolean;
};

export function parseArgs(argv: string[]): Args {
  const out: Args = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--json") out.json = true;
    else if (a === "--profile") out.profile = true;
    else if (a === "--quiet" || a === "-q") out.quiet = true;
    else if (a === "--strict") out.strict = true;
    else if (a === "--help" || a === "-h") out.help = true;
    else if (a === "--out") out.out = argv[++i];
  }
  return out;
}
