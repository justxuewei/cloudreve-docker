# Cloudreve Docker

此Docker镜像由Xavier Niu维护，基于：

- lsiobase/alpine:3.11
- cloudreve: 3.0.0-beta3
- golang: 1.14

## Cloudreve

Cloudreve能助您以最低的成本快速搭建公私兼备的网盘系统。

官方网站：https://cloudreve.org

Github：https://github.com/cloudreve/Cloudreve

## 运行

使用Docker运行

```bash
docker run --name cloudreve \
  -e PUID=1000 \ # optional
  -e PGID=1000 \ # optional
  -e TZ="Asia/Shanghai" \ # optional
  -p 5212:5212 \ 
  --restart=unless-stopped \
  -v <PATH TO UPLOADS>:/cloudreve/uploads \
  -v <PATH TO conf.ini>:/cloudreve/conf.ini \
  -v <PATH TO cloudreve.db>:/cloudreve/cloudreve.db \
  xavierniu/cloudreve
```

Environment Variables

- PUID以及PGID的使用方法以及为什么使用参见: [Understanding PUID and PGID](https://docs.linuxserver.io/general/understanding-puid-and-pgid)
- `TZ`设置时区，默认值为`Asia/Shanghai`

Volumes

- `<PATH TO UPLOADS>`:本机上传目录
- `<PATH TO conf.ini>`: 配置文件
- ` <PATH TO cloudreve.db>`: 数据库文件

