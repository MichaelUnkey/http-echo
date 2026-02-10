# Copyright IBM Corp. 2016, 2024
# SPDX-License-Identifier: MPL-2.0

# Build stage
FROM golang:1.21-alpine AS builder

# TARGETOS and TARGETARCH are set automatically when --platform is provided.
ARG TARGETOS=linux
ARG TARGETARCH=amd64
ARG PRODUCT_VERSION
ARG PRODUCT_REVISION
ARG PRODUCT_REVISION_TIME

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum* ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build \
    -a \
    -o=http-echo \
    -ldflags="-s -w \
      -X 'github.com/hashicorp/http-echo/version.Version=${PRODUCT_VERSION}' \
      -X 'github.com/hashicorp/http-echo/version.GitCommit=${PRODUCT_REVISION}' \
      -X 'github.com/hashicorp/http-echo/version.Timestamp=${PRODUCT_REVISION_TIME}'" \
    -trimpath \
    -buildvcs=false

# Runtime stage
FROM gcr.io/distroless/static-debian12:nonroot AS default

ARG PRODUCT_VERSION
ARG BIN_NAME=http-echo
ENV PRODUCT_NAME=$BIN_NAME

LABEL name="http-echo" \
      maintainer="HashiCorp Consul Team <consul@hashicorp.com>" \
      vendor="HashiCorp" \
      version=$PRODUCT_VERSION \
      release=$PRODUCT_VERSION \
      licenses="MPL-2.0" \
      summary="A test webserver that echos a response. You know, for kids."

# Copy binary from builder
COPY --from=builder /build/http-echo /http-echo

# Copy license
COPY LICENSE /usr/share/doc/$PRODUCT_NAME/LICENSE.txt

# For now must be 8080
EXPOSE 8080/tcp

ENV ECHO_TEXT="hello-world"

ENTRYPOINT ["/http-echo"]
