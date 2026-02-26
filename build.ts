import { $ } from "bun";
import { existsSync, mkdirSync, copyFileSync, writeFileSync, chmodSync } from "fs";
import { join } from "path";
import { arch } from "os";

const ROOT = import.meta.dir;
const DIST = join(ROOT, "dist");
const SWIFT_SOURCE = join(ROOT, "confetti.swift");
const CONFETTI_BINARY = join(DIST, "confetti");
const TADA_BINARY = join(DIST, "tada");

// Allow cross-compilation via TARGET_ARCH env var (e.g. "x64" on an arm64 host)
const targetArch = process.env.TARGET_ARCH || arch();

async function build() {
  // Ensure dist directory exists
  if (!existsSync(DIST)) {
    mkdirSync(DIST, { recursive: true });
  }

  // Step 1: Compile the Swift overlay
  const swiftTarget =
    targetArch === "arm64"
      ? "arm64-apple-macosx13.0"
      : "x86_64-apple-macosx13.0";

  console.log(`Compiling confetti.swift (target: ${swiftTarget})...`);
  const compile =
    await $`swiftc ${SWIFT_SOURCE} -o ${CONFETTI_BINARY} -target ${swiftTarget} -framework Cocoa -framework QuartzCore -O`.quiet();

  if (compile.exitCode !== 0) {
    console.error("Failed to compile confetti.swift:");
    console.error(compile.stderr.toString());
    process.exit(1);
  }
  console.log(`  -> ${CONFETTI_BINARY}`);

  // Step 2: Build the Bun single-file executable with the confetti binary embedded
  const bunTarget = `bun-darwin-${targetArch}`;

  console.log(`Building tada executable (${bunTarget})...`);
  const bunBuild =
    await $`bun build --compile --target=${bunTarget} ${join(ROOT, "index.ts")} --outfile ${TADA_BINARY}`.quiet();

  if (bunBuild.exitCode !== 0) {
    console.error("Failed to build tada:");
    console.error(bunBuild.stderr.toString());
    process.exit(1);
  }
  console.log(`  -> ${TADA_BINARY}`);

  // Step 3: Assemble the platform-specific npm package
  const version = process.env.PACKAGE_VERSION || "0.0.1";
  const platformPkgName = `@markhuot/tada-darwin-${targetArch}`;
  const platformPkgDir = join(DIST, `tada-darwin-${targetArch}`);
  const platformBinDir = join(platformPkgDir, "bin");

  mkdirSync(platformBinDir, { recursive: true });

  // Copy the built binary into the platform package and ensure it's executable
  const platformBinaryPath = join(platformBinDir, "tada");
  copyFileSync(TADA_BINARY, platformBinaryPath);
  chmodSync(platformBinaryPath, 0o755);

  // Write the platform package.json
  const platformPkg = {
    name: platformPkgName,
    version,
    description: `tada binary for macOS ${targetArch}`,
    repository: {
      type: "git",
      url: "https://github.com/markhuot/tada.git",
    },
    os: ["darwin"],
    cpu: [targetArch],
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
