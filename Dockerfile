FROM node:22-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl ca-certificates unzip ripgrep tini openssh-server \
 && rm -rf /var/lib/apt/lists/*

# bump these to upgrade; the image only changes when they do
ARG CLAUDE_CODE_VERSION=2.1.301
ARG CODEX_VERSION=0.163.0
ARG OPENCODE_VERSION=1.19.3

RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} @openai/codex@${CODEX_VERSION} opencode-ai@${OPENCODE_VERSION} \
 && npm cache clean --force

# sshd runs as node (non-root), so it listens on 2222 and can only log in as node
COPY scripts/sshd_config /etc/ssh/mindmeld_sshd_config
COPY --chmod=755 scripts/mindmeld-start /usr/local/bin/mindmeld-start

# non-root: claude refuses --dangerously-skip-permissions as root, and herdr/bun/plugins live in $HOME
USER node
WORKDIR /home/node
ENV PATH=/home/node/.local/bin:/home/node/.bun/bin:$PATH

ARG HERDR_VERSION=0.9.5
ARG BUN_VERSION=1.4.3
ARG HERDR_WEB_UI_VERSION=0.4.11

# herdr.dev/install.sh only installs latest, so fetch the release binary directly
RUN mkdir -p .local/bin \
 && curl -fsSL -o .local/bin/herdr https://github.com/herdrdev/herdr/releases/download/v${HERDR_VERSION}/herdr-linux-x86_64 \
 && chmod +x .local/bin/herdr \
 && curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION}" \
 && herdr plugin install devswha/herdr-web-ui --ref v${HERDR_WEB_UI_VERSION} --yes

# web ui binds inside the container; publish port 7317 on the host and pair devices / set HERDR_WEB_TOKEN
ENV HOST=0.0.0.0
EXPOSE 7317

# ssh for herdr remote attach (herdr machine add ssh://node@<host>:2222); keys come from SSH_AUTHORIZED_KEYS
EXPOSE 2222

ENTRYPOINT ["tini", "--"]
CMD ["mindmeld-start"]
