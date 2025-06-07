# syntax=docker.io/docker/dockerfile:1.16.0@sha256:e2dd261f92e4b763d789984f6eab84be66ab4f5f08052316d8eb8f173593acf7

FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.24-bookworm
ARG SKIP_TESTS=false

WORKDIR /workspace/source

COPY go.* ./
RUN go mod download

COPY . .

RUN [ "${SKIP_TESTS}" = "true" ] || go test ./...

ARG TARGETOS TARGETARCH
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH \
  CGO_ENABLED=0 \
  go build -o target/bin/sidecar -ldflags '-w -extldflags "-static"' ./cmd/extproc

FROM --platform=${TARGETPLATFORM:-linux/amd64} gcr.io/distroless/static-debian12:nonroot

COPY --from=0 /workspace/source/target/bin/sidecar /usr/local/bin/sidecar

ENTRYPOINT ["/usr/local/bin/sidecar"]
CMD ["--configPath","/tmp/nonexistent-to-get-default-config.yaml"]
