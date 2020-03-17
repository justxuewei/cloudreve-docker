FROM lsiobase/alpine:3.11

ARG GOLANG_VERSION=1.14

ENV PUID=1000
ENV PGID=1000
ENV TZ="Asia/Shanghai"

ENV GOPATH="$HOME/go"
ENV PATH="${PATH}:/usr/local/go/bin:$GOPATH/bin"

LABEL MAINTAINER="Xavier Niu"

RUN \
    echo ">>>>>> update dependencies <<<<<<" \
    && apk update && apk add tzdata git yarn build-base gcc abuild binutils binutils-doc gcc-doc \
    && echo ">>>>>> set up timezone <<<<<<" \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && wget -O golang.tar.gz https://dl.google.com/go/go${GOLANG_VERSION}.linux-amd64.tar.gz \
    && mkdir /lib64 \
    && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 \
    && tar -C /usr/local -xzf golang.tar.gz \
    && echo ">>>>>> clone Cloudreve from git <<<<<<" \
    && git clone --recurse-submodules https://github.com/cloudreve/Cloudreve.git \
    && cd Cloudreve \
    && echo ">>>>>> build Cloudreve <<<<<<" \
    && cd assets \
    && yarn install \
    && yarn run build \
    && cd .. \
    && go get github.com/rakyll/statik \
    && statik -src=assets/build/ -include=*.html,*.js,*.json,*.css,*.png,*.svg,*.ico -f \
    && export COMMIT_SHA=$(git rev-parse --short HEAD) \
    && export VERSION=$(git describe --tags) \
    && go build -a -o cloudreve -ldflags " -X 'github.com/HFO4/cloudreve/pkg/conf.BackendVersion=$VERSION' -X 'github.com/HFO4/cloudreve/pkg/conf.LastCommit=$COMMIT_SHA'" \
    && mkdir /cloudreve \
    && mv ./cloudreve /cloudreve/main \
    && echo ">>>>>> clean up <<<<<<" \
    && apk del tzdata git yarn build-base gcc abuild binutils binutils-doc gcc-doc \
    && rm -rf /usr/local/go /Cloudreve

VOLUME ["/cloudreve/uploads", "/cloudreve/conf.ini", "/cloudreve/cloudreve.db"]

EXPOSE 5212

ENTRYPOINT ["/cloudreve/main"]
