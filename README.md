# cnp-nodejs-base

[![Build Status](https://dev.azure.com/hmcts/CNP/_apis/build/status/NodeJS%20base%20image%20build?branchName=master)](https://dev.azure.com/hmcts/CNP/_build/latest?definitionId=97&branchName=master)

- [Images list](#images-list)
- [Background](#background)
- [Sample use](#sample-use)
- [Troubleshooting](#troubleshooting)
- [Pulling base images](#pulling-base-images)
- [Building images locally](#building-images-locally)
- [Building images for sandbox](#building-images-for-sandbox)
- [License](#license)

## Supported Images list

We recommend that you use the alpine image as it is smaller and most of the time has no vulnerabilities.

| Tag                                                 | OS             | NodeJS version |
| ----------------------------------------------------| -------------- | -------------- |
| `hmctspublic.azurecr.io/base/node:20-alpine`        | Alpine         | LTS 20         |
| `hmctspublic.azurecr.io/base/node:20-bookworm-slim` | Debian bookworm| LTS 20         |

## Background

These images are based on nodeJS official ones using [LTS versions](https://github.com/nodejs/Release#release-schedule), with the addition of a specific `hmcts` user, used for consistent runtime parameters.

Here are the defaults properties you inherit from using those base images:

| Directive | Default Values                               |
| --------- | -------------------------------------------- |
| `WORKDIR` | `/opt/app`, accessible as `$WORKDIR` as well |
| `CMD`     | `["yarn", "start"]`                          |
| `USER`    | `hmcts`                                      |

_Nota Bene_:

- These images are primarily aimed at application runtimes, nothing prevents the use of other intermediate images to build your projects.
- By default when the image is initially launched it will run under the context of the `hmcts` user. However you may have to switch to the `root` user to install OS dependencies.
- The distroless nodeJS base image has been ruled out as it is still [pretty experimental](https://github.com/GoogleContainerTools/distroless/#docker)

## Sample use

```Dockerfile
### base image ###
FROM hmctspublic.azurecr.io/base/node:20-alpine as base
COPY package.json yarn.lock ./
RUN yarn install

### runtime image ###
FROM base as runtime
COPY . .
# make sure you use the hmcts user
USER hmcts
```

You can also leverage on alpine distributions to create smaller runtime images:

Simple:
```Dockerfile
# ---- Dependencies image ----
FROM hmctspublic.azurecr.io/base/node:20-alpine as base
COPY --chown=hmcts:hmcts package.json yarn.lock ./
RUN yarn install --production

# ---- Runtime image ----
FROM base as runtime
COPY . .
EXPOSE 3000
```

More complex example:
```Dockerfile
FROM hmctspublic.azurecr.io/base/node:20-alpine as base

COPY package.json yarn.lock ./

FROM base as build

USER root
RUN apk add python2 make g++
USER hmcts

RUN yarn && npm rebuild node-sass

COPY . .
RUN yarn setup && rm -r node_modules/ && yarn install --production && rm -r ~/.cache/yarn

FROM base as runtime
COPY --from=build $WORKDIR ./
USER hmcts
EXPOSE 3000
```

## Troubleshooting

#### Permission issues when I install apk/apt dependencies

Apk/apt packages installation requires the `root` user so you may switch temporarily to this user. e.g.:

```Dockerfile
### build image (Debian) ###
FROM hmctspublic.azurecr.io/base/node:20-bookworm-slim as base

USER root
RUN apt-get update && apt-get install ...
USER hmcts

COPY package.json yarn.lock ./
...
```

#### Yarn install fails because of permission issues

Depending on the post-installation steps, some script might need permissions on files owned by the root user. If this is the case, you can copy files from the host as `hmcts` user:

```Dockerfile
...
COPY --chown=hmcts:hmcts package.json yarn.lock .
...
```

## Building images locally

```shell
$ make
```

This will generate the right tags so that you can use those images to build other nodejs-based projects by HMCTS.

## Building images for sandbox

Sandbox is as its named, a _sandbox_ registry. Thus, the base images are not automatically pushed in the sandbox registry `hmctssandbox`.

However you can still push them from your workstation using the following command:

```shell
$ make sandbox
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.
