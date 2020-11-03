# ---- Build Stage ----
FROM elixir:1.10.3-alpine AS app_builder

# Install build dependencies
# hadolint ignore=DL3018
RUN apk add --no-cache git build-base nodejs npm python

# Prepare build dir
RUN mkdir /app
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ARG ENV=dev
ARG VERSION=docker_default
ENV MIX_ENV=${ENV} TERM=xterm LANG=C.UTF-8 \
    # Disable Elixir code reload
    DEBUG_ERRORS=false CODE_RELOADER=false

# Install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get
RUN mix deps.compile

# Build assets
COPY assets/css assets/css
COPY assets/js assets/js
COPY assets/scss assets/scss
COPY assets/static assets/static
COPY assets/.babelrc assets/.babelrc
COPY assets/package-lock.json assets/package-lock.json
COPY assets/package.json assets/package.json
COPY assets/webpack.config.js assets/webpack.config.js

# hadolint ignore=DL3003
RUN cd assets && npm install && npm run deploy
RUN mix phx.digest

# Build project
COPY priv priv
COPY lib lib
RUN mix compile

# Build release
COPY rel rel
RUN mix release

# ---- Application Stage ----
# DO NOT use alpine 3.10.x Elixir is not working with musl 1.1.22: https://bugs.alpinelinux.org/issues/9983
FROM alpine:3.9.4 AS app

# Set environment variables
ARG ENV=dev
ENV MIX_ENV=${ENV} TERM=xterm LANG=C.UTF-8

# Install app dependencies
# hadolint ignore=DL3018
RUN apk add --no-cache gnupg bash openssl postgresql-client file

# Prepare the app dir
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# Copy bin files
COPY bin ./bin

# Copy RSA KEYS
COPY rsa_keys ./rsa_keys

# Copy over the build artifact from the previous step
COPY --from=app_builder /app/_build .
RUN ln -s ${ENV}/rel/framework _release

EXPOSE 4000

# Run the release
CMD ["./bin/server-up.sh"]
