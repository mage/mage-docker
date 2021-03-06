###
# MAGE Docker image
#
# Feel free to add or customise the image according to your needs.
###
ARG node_version=8.2.1
ARG base_image=node:${node_version}

FROM ${base_image}
MAINTAINER Marc Trudel <mtrudel@wizcorp.jp>

# System dependencies
RUN apt-get -qq update \
      && apt-get -qq install --no-install-recommends sudo vim bash-completion libzmq3-dev \
      && apt-get clean all

# Update NPM
RUN cd /tmp \
      && npm install npm@5 \
      && rm -rf /usr/local/lib/node_modules \
      && mv node_modules /usr/local/lib && \
      npm -v

# Create an app user to run things from
RUN useradd -m app && echo "app:app" | chpasswd && adduser app sudo

# Have the app user own the app folder
RUN mkdir /usr/src/app && chown app.app /usr/src/app

# Make app user a sudoer
RUN echo "app         ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Switch current user to app
USER app

# Copy custom bashrc file
COPY .bashrc /home/app

# Environment variables
# Set EDITOR variable (for git)
ENV EDITOR=vim

# Set working directory (this will get mounted during development)
WORKDIR /usr/src/app

# Load files and install dependencies
ONBUILD ARG node_env=production
ONBUILD ARG npm_flags
ONBUILD ARG npm_loglevel=http

ONBUILD ENV NODE_ENV=${node_env}
ONBUILD ENV NPM_CONFIG_LOGLEVEL=${npm_loglevel}
ONBUILD COPY package.json /usr/src/app
ONBUILD COPY package-lock.json /usr/src/app
ONBUILD RUN npm install ${npm_flags} \
      && npm cache clean --force
ONBUILD COPY . /usr/src/app

# Stop signal
STOPSIGNAL SIGTERM

# Command to run
CMD ["npm", "run", "mage"]
