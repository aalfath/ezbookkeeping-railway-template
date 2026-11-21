# ezBookkeeping for Railway
# Upstream: https://github.com/mayswind/ezbookkeeping (MIT)
FROM mayswind/ezbookkeeping:2.1.1@sha256:584e4d7f6fc1642773e840b56296f8782912e3bb17abfe3c49097508b198cdb7

USER root
# su-exec drops from root to the app user after the start script fixes volume ownership
RUN apk add --no-cache su-exec
COPY --chmod=755 railway-start.sh /railway-start.sh

EXPOSE 8080
ENTRYPOINT ["/railway-start.sh"]
