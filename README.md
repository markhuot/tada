# tada

Show celebratory particles on macOS.

## Usage

Run with no flags to launch confetti:

```bash
tada
```

Available particle mode flags:

- `--confetti` Force confetti mode.
- `--balloons` Launch floating balloon particles instead of confetti.
- `--random` Randomly choose confetti or balloons for each run.

If no particle flag is provided, the default is `--confetti` behavior.

## Balloon mode details

Balloon particles are tuned differently from confetti:

- Balloons rise upward and continue off the top of the screen.
- Balloons use partially transparent colors from the confetti palette.
- Balloons include subtle radial gradients with an offset highlight for a more 3D look.
