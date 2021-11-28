FROM golang:1.16-alpine as builder

ARG CLOUDREVE_VERSION="3.4.1"

WORKDIR /ProjectCloudreve

RUN apk update \
    && apk add git yarn build-base gcc abuild binutils binutils-doc gcc-doc

RUN git clone --recurse-submodules https://github.com/cloudreve/Cloudreve.git

RUN cd ./Cloudreve/assets \
    && yarn install --network-timeout 1000000 \
    && yarn run build

RUN cd ./Cloudreve \
    && go get github.com/rakyll/statik \
    && statik -src=assets/build/ -include=*.html,*.js,*.json,*.css,*.png,*.svg,*.ico -f \
    && git checkout ${CLOUDREVE_VERSION} \
    && export COMMIT_SHA=$(git rev-parse --short HEAD) \
    && go build -a -o cloudreve-main -ldflags " -X 'github.com/HFO4/cloudreve/pkg/conf.BackendVersion=$CLOUDREVE_VERSION' -X 'github.com/HFO4/cloudreve/pkg/conf.LastCommit=$COMMIT_SHA'"

FROM lsiobase/alpine:3.13

ENV PUID=1000
ENV PGID=1000
ENV TZ="Asia/Shanghai"

LABEL MAINTAINER="Xavier Niu"

WORKDIR /cloudreve

COPY --from=builder /ProjectCloudreve/Cloudreve/cloudreve-main /cloudreve/

VOLUME ["/cloudreve/uploads", "/downloads", "/cloudreve/avatar", "/cloudreve/config", "/cloudreve/db"]

RUN echo ">>>>>> update dependencies" \
    && apk update \
    && apk add tzdata \
    && echo ">>>>>> set up timezone" \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && echo ">>>>>> fix cloudreve-main premission" \
    && chmod +x /cloudreve/cloudreve-main

EXPOSE 5212

ENTRYPOINT ["./cloudreve-main", "-c", "/cloudreve/config/conf.ini"]
