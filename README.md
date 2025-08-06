# Simple CM Builds

This repository provides a simple script to automate building and installing the CM Electron application for different environments and operating systems.

## What the Script Does

- Cleans previous build artifacts and dependencies.
- Installs npm dependencies.
- Rebuilds native Electron modules.
- Runs the Electron build for the specified environment.
- Installs the generated package for your OS:
  - **Linux**: Installs the `.deb` package.
  - **macOS**: Mounts the `.dmg` and copies the app to `/Applications`.
  - **Windows**: Locates the `.exe` installer for manual installation.

## Requirements

- Node.js and npm installed.
- Sudo privileges (for Linux installation).
- Electron build dependencies.

## Installation

Follow these steps to set up the script:

1. **Clone the repository**

   ```bash
   git clone git@github.com:elenamangassmowl/simple_cm_builds.git
   cd simple_cm_builds
   ```

2. **Configure environment variables**

   Copy the example environment file and edit it to match your setup:

   ```bash
   cp .env.example .env
   # Edit .env with your preferred values
   ```

   The `.env` file contains:

   - `PROJECT_DIR`: Path to your CM project directory
   - `ENV`: Default build environment (e.g., dev, prod, test)
   - `VERSION`: Default application version

3. **Make the script executable**

   ```bash
   chmod +x simple_cm_builds.sh
   ```

## Usage



Run the build and installation script:

```bash
./simple_cm_builds.sh [-p|--prestep] [environment] [version]
```


- `-p`, `--prestep` (optional): Run cleaning and dependency steps before build (overrides PRESTEP in .env)
- `environment` (optional): Specify the build environment (`dev`, `prod`, `test`, etc.). Defaults to value in `.env` or `dev` if not provided.
- `version` (optional): Specify the application version to build and install. Defaults to value in `.env` or `5.1.0` if not provided.

**Examples:**

To build and install for the test environment with the default version:

```bash
./simple_cm_builds.sh test
```

To build and install for the prod environment with a specific version:

```bash
./simple_cm_builds.sh prod 5.2.0
```

To always run cleaning and dependency steps before build:

```bash
./simple_cm_builds.sh -p
./simple_cm_builds.sh --prestep prod 5.2.0
```

### Tip: Create an Alias (Linux/macOS)

For convenience, you can create an alias to run the script from anywhere. Add the following line to your `~/.bashrc`, `~/.zshrc`, or shell configuration file:

```bash
alias cm-build="$HOME/simple_cm_builds/simple_cm_builds.sh"
```


After reloading your shell, you can run:

```bash
cm-build [-p|--prestep] [environment] [version]
```

**Examples:**

To build and install for the test environment using the alias:

```bash
cm-build test
```

To build and install for the prod environment with a specific version using the alias:

```bash
cm-build prod 5.2.0
```

To always run cleaning and dependency steps before build using the alias:

```bash
cm-build -p
cm-build --prestep prod 5.2.0
```

This works on Linux and macOS. On Windows, you can use similar functionality with PowerShell profiles or batch files.


## Troubleshooting

- Ensure the `PROJECT_DIR` variable in the script points to your CM project directory.
- Check for errors in the terminal output for missing dependencies or build failures.

## Notes

- This script is intended for internal use and may require adaptation for other CM project structures.
- Review and update the script as needed for your specific environment or requirements.

## License

This project is licensed under the terms of the MIT License. See the `LICENSE` file for details.
