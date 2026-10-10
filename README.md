# Bambuddy Remote (Garmin Connect IQ)

Watch app to remote-control a [Bambuddy](https://github.com/maziggy/bambuddy) server:
a **glance** (running job + ETA, "N in queue"), view the print queue, **start** (select/tap) and **stop** (hold menu) items.

## Setup
1. Install the Connect IQ SDK + VS Code "Monkey C" extension.
2. In Bambuddy: Settings -> API Keys, create a key.
3. Open `garmin-bambuddy/` in VS Code, run "Monkey C: Edit Set Up" / Build, pick a device.
   Set `serverUrl` and `apiKey` in the app settings (Garmin Connect / simulator).
4. Generate a developer key before building (`Monkey C: Generate a Developer Key`).

## API used (unverified against a live server, from Bambuddy source)
- Auth: `X-API-Key` header
- `GET /api/v1/queue/` (glance uses `printing` + `pending` items; ETA = `started_at` + `print_time_seconds`)
- `POST /api/v1/queue/{id}/start`, `POST /api/v1/queue/{id}/stop`

## Known TODOs
- Glance ETA is an estimate; use `/printers/{id}/status` for live remaining time. Needs Connect IQ API 4.0+.
- The watch reaches the server via the phone; the server must be reachable from the phone
  (HTTPS or LAN). Plain HTTP may be blocked on some devices - use HTTPS/reverse proxy if so.
- Not compiled here (no SDK in this environment); expect minor type-check fixes.
- Replace placeholder launcher icon; add glance view, confirm dialogs, printer status.
