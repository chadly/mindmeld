# Web UI unreachable on port 7317

_Investigated 2026-10-16 on apollo (`/opt/stacks/mindmeld`)._

## Symptom

`http://apollo:7317/` timed out even though the `mindmeld` container was running.

## Causes

There were two separate problems.

### 1. Container not recreated after the port change

`compose.yaml` had been changed from `"127.0.0.1:7317:7317"` to `7317:7317`, but the running container was never recreated. It was still bound to `127.0.0.1:7317`, so nothing outside the host could reach it.

Check with:

```sh
docker ps --filter name=mindmeld --format '{{.Ports}}'
```

Fix: `docker compose up -d` in the stack directory.

### 2. Stale web UI supervisor lock in the `home` volume

Nothing was listening on 7317 inside the container. The `herdr-web-ui` plugin failed at startup with:

```
error: A managed server is already running for this checkout and port.
```

The plugin's supervisor (`server/supervisor.ts`) writes its PID to:

```
~/.config/herdr-web-ui/updates/<hash>/supervisor.lock/pid
```

This lock lives in the persisted `home` volume. On startup the plugin treats the lock as active if *any* process has that PID (`process.kill(pid, 0)`). Each new container numbers its processes from 1 again, so the recorded PID (70 in this case) can belong to an unrelated process at startup. When that happens, the plugin refuses to start.

Diagnose with:

```sh
cd ~/.config/herdr/plugins/github-installations/devswha.herdr-web-ui-*/*/checkout
sh scripts/with-bun.sh scripts/plugin.ts status   # prints "down" and the startup error
find ~ -path '*supervisor.lock/pid' -exec cat {} \;
```

Fix right away by deleting the lock and starting the plugin:

```sh
rm -rf ~/.config/herdr-web-ui/updates/*/supervisor.lock
sh scripts/with-bun.sh scripts/plugin.ts start
```

## Preventing a recurrence

This can happen on any container restart. The lock is only meaningful for the container that created it, so it is safe to delete before herdr starts. Change the `CMD` in the Dockerfile (or set `command:` in compose) to:

```sh
sh -c 'rm -rf ~/.config/herdr-web-ui/updates/*/supervisor.lock; exec herdr server'
```

The better long-term fix belongs in the plugin itself (devswha/herdr-web-ui): it should check that the PID is actually its own supervisor, not just that some process has it.
