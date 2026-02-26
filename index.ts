import confettiBinaryPath from "./dist/confetti" with { type: "file" };
import { writeFileSync, unlinkSync, chmodSync } from "fs";
import { tmpdir } from "os";
import { join } from "path";

async function main() {
  const tmpPath = join(tmpdir(), `tada-confetti-${process.pid}`);

  try {
    // Read the embedded binary and write it to a temp location
    const bytes = await Bun.file(confettiBinaryPath).arrayBuffer();
    writeFileSync(tmpPath, new Uint8Array(bytes));
    chmodSync(tmpPath, 0o755);

    // Run the confetti overlay
    const run = Bun.spawn([tmpPath], {
      stdout: "inherit",
      stderr: "inherit",
    });

    await run.exited;
  } finally {
    try {
      unlinkSync(tmpPath);
    } catch {}
  }
}

main();
