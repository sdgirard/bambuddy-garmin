# Bambuddy Remote (Garmin Connect IQ)

Watch app to remote-control a [Bambuddy](https://github.com/maziggy/bambuddy) server:
a **glance** (running job + ETA, "N in queue"), view the print queue; select/menu opens actions: **Start next** (confirms "plate cleared", acks the plate, starts the next job), start/stop item.

## Setup
1. Install the Connect IQ SDK + VS Code "Monkey C" extension.
2. In Bambuddy: Settings -> API Keys, create a key.
3. Open this folder in VS Code, run "Monkey C: Edit Set Up" / Build, pick a device.
   Set `serverUrl` and `apiKey` in the app settings (Garmin Connect / simulator).
4. Generate a developer key before building (`Monkey C: Generate a Developer Key`).

## Development setup
1. Install [VS Code](https://code.visualstudio.com/) and open this folder. Accept the recommended
   **Monkey C** extension (`garmin.monkey-c`, listed in `.vscode/extensions.json`).
2. Run **Monkey C: Verify Installation** from the command palette (Ctrl/Cmd+Shift+P). It opens the
   Connect IQ SDK Manager; sign in with a Garmin account, accept the license, and download the latest SDK
   plus the devices you target (see `manifest.xml`).
3. Run **Monkey C: Generate a Developer Key** once and keep the key out of git (`developer_key*` is ignored).
4. Press F5 ("Run App (simulator)" in `.vscode/launch.json`) to build and start the simulator.
   Change `device` in `launch.json` to your watch model. Use the simulator menu to view the glance
   and to set the app settings (server URL, API key) via **Settings -> Edit Application.Properties**.
5. To run on a real watch: **Monkey C: Build for Device**, then copy the `.prg` to `GARMIN/APPS` on the
   watch over USB.

A dev container is not used: the SDK Manager and simulator are GUI tools that need a Garmin login.
CI (headless build) could be added later.

## API used (unverified against a live server, from Bambuddy source)
- Auth: `X-API-Key` header
- `GET /api/v1/queue/` (glance uses `printing` + `pending` items; ETA = `started_at` + `print_time_seconds`)
- `POST /api/v1/queue/{id}/start`, `POST /api/v1/queue/{id}/stop`

## Known TODOs
- Glance ETA uses live `remaining_time` (minutes, assumed) from `/printers/{id}/status`, falling back to `started_at` + `print_time_seconds`. Needs Connect IQ API 4.0+.
- The watch reaches the server via the phone; the server must be reachable from the phone
  (HTTPS or LAN). Plain HTTP may be blocked on some devices - use HTTPS/reverse proxy if so.
- Not compiled here (no SDK in this environment); expect minor type-check fixes.
- Replace placeholder launcher icon; add glance view, confirm dialogs, printer status.

## "Start next" flow (printer in the basement)
Confirm dialog -> `GET /printers/{id}/status` -> if `awaiting_plate_clear`: `POST /printers/{id}/clear-plate`
-> if the item is `manual_start`: `POST /queue/{id}/start` (otherwise the scheduler starts it).
API key needs the "clear plate" printer permission. Items with no assigned printer are not supported yet.
