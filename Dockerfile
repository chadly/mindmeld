FROM node:22-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl ca-certificates unzip ripgrep tini \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code @openai/codex opencode-ai \
 && npm cache clean --force

# non-root: claude refuses --dangerously-skip-permissions as root, and herdr/bun/plugins live in $HOME
USER node
WORKDIR /home/node
ENV PATH=/home/node/.local/bin:/home/node/.bun/bin:$PATH

RUN curl -fsSL https://herdr.dev/install.sh | sh \
 && curl -fsSL https://bun.sh/install | bash \
 && herdr plugin install devswha/herdr-web-ui --yes

# web ui binds inside the container; publish it as 127.0.0.1:7317 on the host and pair devices / set HERDR_WEB_TOKEN
ENV HOST=0.0.0.0
EXPOSE 7317

ENTRYPOINT ["tini", "--"]
CMD ["herdr", "server"]
