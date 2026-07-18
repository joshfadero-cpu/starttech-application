# ---------- Build stage ----------
FROM golang:1.25-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o /app/muchtodo ./cmd/api

# ---------- Runtime stage ----------
FROM alpine:3.20

RUN apk add --no-cache wget ca-certificates && \
    addgroup -S app && adduser -S app -G app

WORKDIR /home/app

COPY --from=builder /app/muchtodo .

USER app

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --quiet --output-document=/dev/null http://localhost:8080/health || exit 1

ENTRYPOINT ["./muchtodo"]
