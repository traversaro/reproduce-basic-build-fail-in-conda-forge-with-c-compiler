FROM ghcr.io/prefix-dev/pixi:0.82.1 AS pixi

FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates make \
    && rm -rf /var/lib/apt/lists/*
COPY --from=pixi /usr/local/bin/pixi /usr/local/bin/pixi
WORKDIR /reproducer
COPY . .
RUN pixi install --locked
ENTRYPOINT ["sh", "scripts/container-test.sh"]
CMD ["test"]
