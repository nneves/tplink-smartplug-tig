# build
FROM golang:1.8-stretch AS build
WORKDIR /go/src/apikey-generator
ADD . .
# RUN go get -d -v ./...
RUN go build -v ./...

# create image
FROM alpine:latest
COPY --from=build /go/src/apikey-generator/apikey-generator /usr/local/bin
ENTRYPOINT [ "/usr/local/bin/apikey-generator" ]