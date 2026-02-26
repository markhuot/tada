import { $ } from "bun";
import { existsSync, mkdirSync, copyFileSync, writeFileSync } from "fs";
import { join } from "path";
import { arch } from "os";

const ROOT = import.meta.dir;
const DIST = join(ROOT, "dist");
const SWIFT_SOURCE = join(ROOT, "confetti.swift");
const CONFETTI_BINARY = join(DIST, "confetti");
const TADA_BINARY = join(DIST, "tada");

async function build() {
  // Ensure dist directory exists
  if (!existsSync(DIST)) {
    mkdirSync(DIST, { recursive: true });
  }

  // Step 1: Compile the Swift overlay
  console.log("Compiling confetti.swift...");
  const compile =
    await $`swiftc ${SWIFT_SOURCE} -o ${CONFETTI_BINARY} -framework Cocoa -framework QuartzCore -O`.quiet();

  if (compile.exitCode !== 0) {
    console.error("Failed to compile confetti.swift:");
    console.error(compile.stderr.toString());
    process.exit(1);
  }
  console.log(`  -> ${CONFETTI_BINARY}`);

  // Step 2: Build the Bun single-file executable with the confetti binary embedded
  const currentArch = arch();
  const target =
    currentArch === "arm64" ? "bun-darwin-arm64" : "bun-darwin-x64";

  console.log(`Building tada executable (${target})...`);
  const bunBuild =
    await $`bun build --compile --target=${target} ${join(ROOT, "index.ts")} --outfile ${TADA_BINARY}`.quiet();

  if (bunBuild.exitCode !== 0) {
    console.error("Failed to build tada:");
    console.error(bunBuild.stderr.toString());
    process.exit(1);
  }
  console.log(`  -> ${TADA_BINARY}`);

  // Step 3: Assemble the platform-specific npm package
  const version = process.env.PACKAGE_VERSION || "0.0.1";
  const platformPkgName = `@markhuot/tada-darwin-${currentArch}`;
  const platformPkgDir = join(DIST, `tada-darwin-${currentArch}`);
  const platformBinDir = join(platformPkgDir, "bin");

  mkdirSync(platformBinDir, { recursive: true });

  // Copy the built binary into the platform package
  copyFileSync(TADA_BINARY, join(platformBinDir, "tada"));

  // Write the platform package.json
  const platformPkg = {
    name: platformPkgName,
    version,
    description: `tada binary for macOS ${currentArch}`,
    os: ["darwin"],
    cpu: [currentArch],
    bin: {
      tada: "bin/tada",
    },
    license: "MIT",
  };
  writeFileSync(
    join(platformPkgDir, "package.json"),
    JSON.stringify(platformPkg, null, 2) + "\n"
  );

  console.log(`  -> ${platformPkgDir}`);
  console.log(`\nBuild complete!`);
  console.log(`  Run locally: ./dist/tada`);
  console.log(`  Publish:     cd ${platformPkgDir} && npm publish --access public`);
}

build();
