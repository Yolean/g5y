FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.24-bookworm

WORKDIR /workspace/source

COPY go.* ./
RUN go mod download

COPY . .

RUN go test ./...

ARG TARGETOS TARGETARCH
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH \
  CGO_ENABLED=0 \
  go build -o target/bin/sidecar -ldflags '-w -extldflags "-static"' ./cmd/extproc

FROM --platform=${TARGETPLATFORM:-linux/amd64} gcr.io/distroless/static-debian12:nonroot

COPY --from=0 /workspace/source/target/bin/sidecar /usr/local/bin/sidecar

ENTRYPOINT ["/usr/local/bin/sidecar"]
CMD ["--configPath","/tmp/nonexistent-to-get-default-config.yaml"]
