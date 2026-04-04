FROM ghcr.io/gethomepage/homepage:latest

LABEL org.opencontainers.image.title="droppert.dev"
LABEL org.opencontainers.image.description="Homepage dashboard for the Droppert developer tools"
LABEL org.opencontainers.image.source="https://github.com/Floris/droppert_dev"

USER root

COPY --chown=10001:10001 config/ /app/config/
COPY --chown=10001:10001 public/ /app/public/

RUN mkdir -p /app/config/logs \
    && chown -R 10001:10001 /app

USER 10001:10001

ENV HOMEPAGE_ALLOWED_HOSTS=droppert.dev,www.droppert.dev,localhost:3000,127.0.0.1:3000

EXPOSE 3000
