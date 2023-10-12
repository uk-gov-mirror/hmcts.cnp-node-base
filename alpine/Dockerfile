ARG NODE_VERSION=20
FROM hmctspublic.azurecr.io/imported/library/node:$NODE_VERSION-alpine

ENV APP_USER=hmcts \
  WORKDIR=/opt/app

WORKDIR ${WORKDIR}

# Always install the latest package versions for this
# hadolint ignore=DL3018
RUN apk update && apk --no-cache add shadow \
  && userdel node \
  && apk del shadow \
  && addgroup -g 1000 -S $APP_USER \
  && adduser -u 1000 -S $APP_USER -G $APP_USER \
  && chown -R $APP_USER:$APP_USER /opt/app

USER hmcts
CMD ["yarn", "start"]
