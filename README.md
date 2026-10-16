# mindmeld

A Docker image that runs [herdr](https://herdr.dev/) with coding agents ([Claude Code](https://claude.com/claude-code), [Codex](https://github.com/openai/codex), [opencode](https://opencode.ai/)) and the [herdr web UI](https://github.com/devswha/herdr-web-ui), so you can drive the agents' terminals from a browser.

## Running the Deployed Image

```sh
docker run -d --name mindmeld --restart unless-stopped \
  -p 127.0.0.1:7317:7317 \
  -e HERDR_WEB_TOKEN=<token> \
  -v mindmeld-home:/home/node \
  ghcr.io/chadly/mindmeld:latest
```

Generate the token with `openssl rand -hex 16`. The web UI is then at `http://127.0.0.1:7317`. Keep the port bound to localhost: anyone who can reach it can drive the agents' terminals, so put it behind Tailscale or a reverse proxy rather than exposing it.

The first time, log in to each agent from inside the container:

```sh
docker exec -it mindmeld bash
claude    # / codex / opencode
```

Logins, herdr state, plugins and cloned projects live in the `mindmeld-home` volume (`/home/node`), so they survive restarts and image updates.

## Running Locally

```sh
cp .env.example .env    # set HERDR_WEB_TOKEN
docker compose up -d --build
```

The web UI is at `http://127.0.0.1:17317` (set `MINDMELD_PORT` to change it, since 7317 is usually taken by a host herdr). Log in to the agents with `docker compose exec mindmeld bash`. State lives in the compose project's `home` volume.

### Agent Tooling

`apm install && apm compile` generates `.claude/` and `.mcp.json` from `apm.yml`. The Firecrawl MCP server needs `FIRECRAWL_API_KEY`.
