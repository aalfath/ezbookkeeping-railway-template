# ezBookkeeping for Railway
# Upstream: https://github.com/mayswind/ezbookkeeping (MIT)
FROM mayswind/ezbookkeeping:2.1.1@sha256:584e4d7f6fc1642773e840b56296f8782912e3bb17abfe3c49097508b198cdb7

# Start as root so the start script can fix the volume's ownership,
# then it drops to the image's non-root user (uid 1000) with busybox su.
USER root
COPY --chmod=755 railway-start.sh /railway-start.sh

EXPOSE 8080
ENTRYPOINT ["/railway-start.sh"]
