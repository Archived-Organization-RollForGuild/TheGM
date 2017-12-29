FROM buildpack-deps:jessie
MAINTAINER The Roll For Guild team "founder@rollforguild.com"

ARG RELEASE=master

ENV HOME /root
ENV MIX_ENV prod
ENV PORT 4000
ENV REPLACE_OS_VARS true

ENV APP_ROOT /opt/app
ENV APP_NAME thegm

RUN mkdir -p ${APP_ROOT}

RUN wget --quiet https://s3.amazonaws.com/thegm/releases/${RELEASE}.tar.gz
RUN tar -xf ${RELEASE}.tar.gz -C ${APP_ROOT}
RUN rm -rf ${RELEASE}.tar.gz
RUN chmod 550 ${APP_ROOT}/bin/${APP_NAME}

WORKDIR ${APP_ROOT}

EXPOSE $PORT

ENTRYPOINT ["bin/thegm", "foreground"]
