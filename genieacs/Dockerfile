FROM node:20-bookworm-slim

WORKDIR /opt/genieacs

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl supervisor \
    && npm install -g genieacs@1.2.16 \
    && mkdir -p /var/log/genieacs /opt/genieacs/ext /var/run/supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /root/.npm

COPY supervisord.conf /etc/supervisor/conf.d/genieacs.conf

EXPOSE 7547 7557 7567 3000

HEALTHCHECK --interval=15s --timeout=10s --retries=12 --start-period=75s \
    CMD curl -fsS http://127.0.0.1:7557/devices >/dev/null || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/genieacs.conf"]
