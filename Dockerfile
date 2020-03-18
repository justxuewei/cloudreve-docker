FROM lsiobase/alpine:3.11

ENV PUID=1000
ENV PGID=1000
ENV TZ="Asia/Shanghai"

LABEL MAINTAINER="Xavier Niu"

WORKDIR /cloudreve

ADD cloudreve ./

RUN echo ">>>>>> update dependencies <<<<<<" \
    && apk update && apk add tzdata \
    && echo ">>>>>> set up timezone <<<<<<" \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && echo ">>>>>> clean up <<<<<<" \
    && apk del tzdata \
    && mv ./cloudreve ./main \
    && chmod +x ./main

VOLUME ["/cloudreve/uploads", "/downloads","/cloudreve/conf.ini", "/cloudreve/cloudreve.db"]

EXPOSE 5212

ENTRYPOINT ["./main"]
