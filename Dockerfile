FROM golang:1.12.9 as builder


RUN mkdir -p /etcd-operator

WORKDIR /etcd-operator


RUN mkdir _output

ADD . /etcd-operator/

RUN hack/build/operator/build
RUN hack/build/backup-operator/build
RUN hack/build/restore-operator/build

# Extract binaries from builder and pack into alpine
FROM alpine:3.9

RUN apk add --no-cache ca-certificates

COPY --from=builder /etcd-operator/_output/bin/etcd-backup-operator /usr/local/bin/etcd-backup-operator
COPY --from=builder /etcd-operator/_output/bin/etcd-restore-operator /usr/local/bin/etcd-restore-operator
COPY --from=builder /etcd-operator/_output/bin/etcd-operator /usr/local/bin/etcd-operator

RUN adduser -D etcd-operator
USER etcd-operator
