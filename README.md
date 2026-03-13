# tada

Show celebratory particles on macOS.

## Usage

Run with no flags to launch confetti:

```bash
tada
```

Available particle mode flags:

- `--confetti` Force confetti mode.
- `--snow` Launch white snow particles that fall from the top of the screen.
- `--balloons` Launch floating balloon particles instead of confetti.
- `--fire` Launch a one-second flame burst that burns out quickly.
- `--random` Randomly choose confetti, snow, balloons, or fire for each run.

If no particle flag is provided, the default is `--confetti` behavior.

## Balloon mode details

Balloon particles are tuned differently from confetti:

- Balloons rise upward and continue off the top of the screen.
- Balloons use partially transparent colors from the confetti palette.
- Balloons include subtle radial gradients with an offset highlight for a more 3D look.
