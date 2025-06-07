# syntax=docker.io/docker/dockerfile:1.16.0@sha256:e2dd261f92e4b763d789984f6eab84be66ab4f5f08052316d8eb8f173593acf7

FROM --platform=${BUILDPLATFORM:-linux/amd64} quay.io/keycloak/keycloak:26.2.4@sha256:4a81762677f8911c6266e3dea57a2d78fa17bd63408debbf23afd8cc46fe256e \
  as builder

# https://www.keycloak.org/server/all-config
ENV \
  KC_DB=mariadb \
  KC_TRANSACTION_XA_ENABLED=false \
  QUARKUS_TRANSACTION_MANAGER_ENABLE_RECOVERY=false \
  \
  KC_HTTP_ENABLED=true \
  KC_HTTP_RELATIVE_PATH="/auth" \
  KC_HOSTNAME_STRICT=false \
  KC_PROXY_HEADERS=xforwarded \
  \
  KC_FEATURES=persistent-user-sessions,user-event-metrics \
  KC_FEATURES_DISABLED=authorization,ciba,client-policies,device-flow,impersonation,kerberos,par,step-up-authentication,web-authn,admin-fine-grained-authz,client-secret-rotation,dpop,multi-site,recovery-codes,scripts,token-exchange,update-email \
  \
  KC_CACHE=ispn \
  KC_CACHE_STACK=kubernetes

WORKDIR /opt/keycloak

# https://www.keycloak.org/server/caching#_exposing_metrics_from_caches
RUN sed -i 's|<cache-container name="keycloak">|<cache-container name="keycloak" statistics="true">|' conf/cache-ispn.xml && grep 'statistics="true"' conf/cache-ispn.xml
RUN /opt/keycloak/bin/kc.sh build \
  --health-enabled=true \
  --metrics-enabled=true
RUN /opt/keycloak/bin/kc.sh show-config

RUN mkdir /tmp/emptydir

# TODO unwrap the entrypoint script, it only adds obscurity
# RUN sed -i '2i set -x' /opt/keycloak/bin/kc.sh

FROM --platform=${TARGETPLATFORM:-linux/amd64} ghcr.io/yolean/java:bfeb6be46eb6e26486539bb4abffa70269c80b89
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Duplicate from build, because for example "Strict hostname" config didn't propagate
ENV \
  KC_DB=mariadb \
  KC_TRANSACTION_XA_ENABLED=false \
  QUARKUS_TRANSACTION_MANAGER_ENABLE_RECOVERY=false \
  \
  KC_HTTP_ENABLED=true \
  KC_HTTP_RELATIVE_PATH="/auth" \
  KC_HOSTNAME_STRICT=false \
  KC_PROXY_HEADERS=xforwarded \
  \
  KC_FEATURES=persistent-user-sessions,user-event-metrics \
  KC_FEATURES_DISABLED=authorization,ciba,client-policies,device-flow,impersonation,kerberos,par,step-up-authentication,web-authn,admin-fine-grained-authz,client-secret-rotation,dpop,multi-site,recovery-codes,scripts,token-exchange,update-email \
  \
  KC_CACHE=ispn \
  KC_CACHE_STACK=kubernetes

# # change these values to point to a running db
# ENV KC_DB_URL=
# ENV KC_DB_USERNAME=
# ENV KC_DB_PASSWORD=
# ENV KC_HOSTNAME=localhost
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]

COPY --from=builder --chown=65532:65534 /tmp/emptydir /opt/keycloak/data/h2
COPY --from=builder --chown=65532:65534 /tmp/emptydir /opt/keycloak/data/tmp
