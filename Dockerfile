FROM golang:1.12.9 as builder

RUN curl -L https://github.com/golang/dep/releases/download/v0.5.0/dep-linux-amd64 -o /usr/local/bin/dep \
    && chmod +x /usr/local/bin/dep \
    && go get honnef.co/go/tools/cmd/staticcheck

RUN mkdir -p /go/src/github.com/mikewl/etcd-operator

WORKDIR /go/src/github.com/mikewl/etcd-operator

ADD Gopkg.* /go/src/github.com/mikewl/etcd-operator/

RUN mkdir _output
RUN dep ensure -v --vendor-only

ADD . /go/src/github.com/mikewl/etcd-operator/

# make sure again with the source code this time
RUN dep ensure -v

RUN hack/build/operator/build
RUN hack/build/backup-operator/build
RUN hack/build/restore-operator/build

# Extract binaries from builder and pack into alpine
FROM alpine:3.9

RUN apk add --no-cache ca-certificates

COPY --from=builder /go/src/github.com/mikewl/etcd-operator/_output/bin/etcd-backup-operator /usr/local/bin/etcd-backup-operator
COPY --from=builder /go/src/github.com/mikewl/etcd-operator/_output/bin/etcd-restore-operator /usr/local/bin/etcd-restore-operator
COPY --from=builder /go/src/github.com/mikewl/etcd-operator/_output/bin/etcd-operator /usr/local/bin/etcd-operator

RUN adduser -D etcd-operator
USER etcd-operator
