FROM elixir:alpine

RUN apk --no-cache add --virtual make

# Prep Elixir deps
RUN mix local.hex --force
RUN mix archive.install --force https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez
RUN mix local.rebar --force

WORKDIR /app