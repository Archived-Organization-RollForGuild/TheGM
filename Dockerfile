FROM elixir:alpine

# RUN apt-get install gcc make libc-dev libgcc

# Install Argon2
# RUN apk --no-cache add --virtual build-dependencies g++ make ca-certificates openssl\
#     && wget https://github.com/P-H-C/phc-winner-argon2/archive/20161029.tar.gz -O /tmp/argon2.tar.gz\
#     && tar zxvf /tmp/argon2.tar.gz -C /tmp && rm /tmp/argon2.tar.gz\
#     && mkdir -p /usr/src && mv /tmp/phc-winner-argon2-20161029 /usr/src/argon2\
#     && cd /usr/src/argon2\
#     && make && make bench && make test && make install\
#     && install bench /usr/bin\
#     && apk del build-dependencies

# Prep Elixir deps
RUN mix local.hex --force
RUN mix archive.install --force https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez
RUN mix local.rebar --force

WORKDIR /app