// Using a function-based config prevents lint-staged from chunking matched files into
// parallel batches. dotnet format and flutter analyze do not support concurrent execution
// against the same project, so receiving all files in a single function call is required.
export default {
  "apps/web/**/*.{ts,tsx,js,jsx}": (files) => [
    `prettier --write ${files.join(" ")}`,
    `apps/web/node_modules/.bin/eslint --fix --no-warn-ignored --config apps/web/eslint.config.mjs ${files.join(" ")}`,
    "pnpm --filter web lint",
    "pnpm --filter web typecheck",
  ],

  "apps/api/**/*.cs": (files) => [
    // Pass all staged C# files in one invocation to avoid build lock contention.
    `dotnet format apps/api/HappyPaws.slnx --include ${files.join(" ")}`,
  ],

  "apps/mobile/**/*.dart": (files) => [
    // Format each file individually, then run a single project-wide analysis.
    `dart format ${files.join(" ")}`,
    "flutter analyze apps/mobile --no-fatal-warnings --no-fatal-infos",
  ],
};
