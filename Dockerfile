# syntax=docker/dockerfile:1
ARG GO_VERSION=1.20
ARG GOLANGCI_LINT_VERSION=v1.52

#From which image we want to build. This is basically our environment.
FROM golang:${GO_VERSION}-alpine AS setup

# Still need to better understand the BUILDPLATFORM usage
# FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS setup

# Creates an app directory to hold your app’s source code
WORKDIR /go/src

# To prevent links to libc on Linux when networking is used in Go
ENV CGO_ENABLED=0

RUN --mount=type=cache,target=/go/pkg/mod/ \
    # Effectively tracks changes within your go.mod and go.sum files
    --mount=type=bind,source=go.sum,target=go.sum \
    --mount=type=bind,source=go.mod,target=go.mod \
    # Resolve project dependencies
    go mod download -x

# ----------------------------------------------------------------
FROM setup as build-dev
RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,target=. \
    go build -o /go/bin/app-dev app.go

# ----------------------------------------------------------------
FROM setup as build-multiarch

# Win64
ENV GOOS=windows GOARCH=amd64
RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,target=. \
    go build -o /go/bin/app-${GOOS}-${GOARCH}.exe app.go

# Win32
ENV GOOS=windows GOARCH=386
RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,target=. \
    go build -o /go/bin/app-${GOOS}-${GOARCH}.exe app.go

# Linux 64-bit
ENV GOOS=linux GOARCH=amd64
RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,target=. \
    go build -o /go/bin/app-${GOOS}-${GOARCH} app.go

# Linux 32-bit
ENV GOOS=linux GOARCH=386
RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,target=. \
    go build -o /go/bin/app-${GOOS}-${GOARCH} app.go

# Apple Silicon
ENV GOOS=darwin GOARCH=arm64
RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,target=. \
    go build -o /go/bin/app-${GOOS}-${GOARCH} app.go

# MacOS 64-bit
ENV GOOS=darwin GOARCH=amd64
RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,target=. \
    go build -o /go/bin/app-${GOOS}-${GOARCH} app.go

# MacOS 32-bit (Note the _ after GOOS used for filename only. It happens because it can't compile MacOS 386 with GOOS defined)
ENV GOOS_=darwin GOARCH=386 GOOS=
RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,target=. \
    go build -o /go/bin/app-${GOOS_}-${GOARCH} app.go

# ----------------------------------------------------------------
FROM build-dev AS client

WORKDIR /go/bin

# Add go user and group so that the Docker process doesn't run as root
RUN addgroup -S golang \
    && adduser -S -u 10000 -g golang golang
USER golang

COPY --chown=golang:golang .env .
COPY --chown=golang:golang --from=build-dev /go/bin/ .

# ----------------------------------------------------------------
FROM scratch AS binaries

COPY --from=build-dev /go/bin/ .
COPY --from=build-multiarch /go/bin/ .

# ----------------------------------------------------------------
# TEST / LINT
FROM golangci/golangci-lint:${GOLANGCI_LINT_VERSION} as lint

WORKDIR /test
RUN --mount=type=bind,target=. \
    golangci-lint run