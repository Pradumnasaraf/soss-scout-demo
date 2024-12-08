FROM golang:1.23-alpine AS builder
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o /app .

FROM alpine:3.17.6 AS final
# FROM alpine:3.12.5
# FROM alpine:3.21.0
EXPOSE 8080
COPY --from=builder /app /bin/app
CMD ["bin/app"]
