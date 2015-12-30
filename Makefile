# Container parameters
NAME = wackyvik/bitbucket
VERSION = $(shell /bin/cat BITBUCKET.VERSION)
JAVA_OPTS = -Djava.io.tmpdir=/var/tmp -XX:-UseAESIntrinsics -Dcom.sun.net.ssl.checkRevocation=false
MEMORY_LIMIT = 8192
CONFIGURE_SQL_DATASOURCE = FALSE
CONFIGURE_FRONTEND = FALSE
BITBUCKET_DB_DRIVER = org.postgresql.Driver
BITBUCKET_DB_URL = jdbc:postgresql://docker0:5432/bitbucket?useUnicode=true&amp;characterEncoding=utf8
BITBUCKET_DB_USER = bitbucket
BITBUCKET_DB_PASSWORD = bitbucket
BITBUCKET_FE_NAME = bitbucket.local
BITBUCKET_FE_PORT = 443
BITBUCKET_FE_PROTO = https
CPU_LIMIT_CPUS = 3-6
CPU_LIMIT_LOAD = 100
IO_LIMIT = 500

# Calculated parameters.
VOLUMES_FROM = $(shell if [ $$(/usr/bin/docker ps -a | /bin/grep -i "$(NAME)" | /bin/wc -l) -gt 0 ]; then /bin/echo -en "--volumes-from="$$(/usr/bin/docker ps -a | /bin/grep -i "$(NAME)" | /bin/tail -n 1 | /usr/bin/awk "{print \$$1}"); fi)
SWAP_LIMIT = $(shell /bin/echo $$[$(MEMORY_LIMIT)*2])
JAVA_MEM_MAX = $(shell /bin/echo $$[$(MEMORY_LIMIT)-32+$(SWAP_LIMIT)])m
JAVA_MEM_MIN = $(shell /bin/echo $$[$(MEMORY_LIMIT)/4])m
CPU_LIMIT_LOAD_THP = $(shell /bin/echo $$[$(CPU_LIMIT_LOAD)*1000])

.PHONY: all build install

all: build install

build:
	/usr/bin/docker build -t $(NAME):$(VERSION) --rm image

install:
	/usr/bin/docker run --publish 8094:7990 --name=bitbucket-$(VERSION) $(VOLUMES_FROM)                       \
						-e CONFIGURE_SQL_DATASOURCE="$(CONFIGURE_SQL_DATASOURCE)"         \
						-e CONFIGURE_FRONTEND="$(CONFIGURE_FRONTEND)"                     \
						-e JAVA_OPTS="$(JAVA_OPTS)"                                       \
						-e JAVA_MEM_MAX="$(JAVA_MEM_MAX)"                                 \
						-e JAVA_MEM_MIN="$(JAVA_MEM_MIN)"                                 \
						-e BITBUCKET_DB_DRIVER="$(BITBUCKET_DB_DRIVER)"                   \
						-e BITBUCKET_DB_URL="$(BITBUCKET_DB_URL)"                         \
						-e BITBUCKET_DB_USER="$(BITBUCKET_DB_USER)"                       \
						-e BITBUCKET_DB_PASSWORD="$(BITBUCKET_DB_PASSWORD)"               \
						-e BITBUCKET_FE_NAME="$(BITBUCKET_FE_NAME)"                       \
						-e BITBUCKET_FE_PORT="$(BITBUCKET_FE_PORT)"                       \
						-e BITBUCKET_FE_PROTO="$(BITBUCKET_FE_PROTO)"                     \
						-m $(MEMORY_LIMIT)M --memory-swap $(JAVA_MEM_MAX)                 \
						--oom-kill-disable=false                                          \
						--cpuset-cpus=$(CPU_LIMIT_CPUS) --cpu-quota=$(CPU_LIMIT_LOAD_THP) \
						--blkio-weight=$(IO_LIMIT)                                        \
						-d wackyvik/bitbucket:$(VERSION)
