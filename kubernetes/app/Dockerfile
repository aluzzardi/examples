FROM golang:1.16 AS builder
WORKDIR /go/src/app
COPY . .
RUN \
	GO111MODULE=on GOOS=linux GOARCH=amd64 \
    CGO_ENABLED=0 go build -ldflags '-s -d -w' 

FROM alpine
COPY --from=builder /go/src/app/hello-go /bin/hello-go
WORKDIR /app

ENV PORT 80

ENTRYPOINT ["/bin/hello-go"]
