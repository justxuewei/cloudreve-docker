# Cloudreve Docker

![](https://img.shields.io/github/workflow/status/xavier-niu/cloudreve-docker/Publish%20Docker) ![](https://img.shields.io/badge/cloudreve-3.3.2-brightgreen) ![](https://img.shields.io/docker/image-size/xavierniu/cloudreve/latest) ![](https://img.shields.io/docker/pulls/xavierniu/cloudreve) ![](https://img.shields.io/badge/maintainer-xavierniu-lightgrey)

优势

- 基于最新的[Cloudreve V3](https://github.com/cloudreve/Cloudreve)
- 长期维护
- 镜像体积小
- 纯净安装，无多余组件
- 支持多种架构(amd64, arm64, arm32/v7)
- 简易安装
- 内含详细的Cloudreve+Nginx+Aria2部署教程

## 开始

目录

- `<PATH TO uploads>`:上传目录，如`/sharedfolders`
- `<PATH TO config>`: 配置文件夹，如`/dockercnf/cloudreve/config`
- `<PATH TO db>`: 数据库文件夹，如`/dockercnf/cloudreve/db`
- `<PATH TO avatar>`: 头像文件夹，如`/dockercnf/cloudreve/avatar`

创建配置文件夹

```bash
mkdir -p <PATH TO config>
```

创建配置文件`vim <PATH TO config>/conf.ini `（*该配置文件针对SQLite数据库，如需使用MySQL等数据库，请参见cloudreve官方文档*）

```ini
# conf.ini
[Database]
DBFile = /cloudreve/db/cloudreve.db
```

启动cloudreve容器

```bash
docker run -d \
  --name cloudreve \
  -e TZ="Asia/Shanghai" \ # optional
  -p 5212:5212 \
  --restart=unless-stopped \
  -v <PATH TO uploads>:/cloudreve/uploads \
  -v <PATH TO config>:/cloudreve/config \
  -v <PATH TO db>:/cloudreve/db \
  -v <PATH TO avatar>:/cloudreve/avatar \
  xavierniu/cloudreve
```

说明

- 首次启动后请执行`docker logs -f cloudreve`获取初始密码
- `TZ`设置时区，默认值为`Asia/Shanghai`

其他教程

- 如果你想使用Nginx作为反向代理服务器，或者使用Aira2作为离线下载服务，请参阅[Cloudreve Docker - NAC](https://github.com/xavier-niu/cloudreve-docker/blob/master/README-NAC.md)
- 如果你希望通过docker-compose的方式启动服务，请参阅[Cloudreve Docker - Docker Compose](https://github.com/xavier-niu/cloudreve-docker/blob/master/README-DOCKER-COMPOSE.md)

## 升级

首先请暂停并移除正在运行的容器并从DockerHub拉取最新的镜像

```bash
docker stop cloudreve \
  && docker rm cloudreve \
  && docker pull xavierniu/cloudreve
```

重复上面的运行步骤再次启动容器即可。
