# Node.js stage for multi-stage build
FROM node:24-bookworm-slim AS node

FROM ubuntu:26.04
ARG DEBIAN_FRONTEND=noninteractive

# Locales and timezone
RUN apt-get update && apt-get install -y \
      locales \
      tzdata && \
  echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
  locale-gen --purge "en_US.UTF-8" && \
  dpkg-reconfigure --frontend=noninteractive locales && \
  update-locale LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8" LANGUAGE="en_US.UTF-8" && \
  echo "Etc/UTC" > /etc/timezone && \
  rm /etc/localtime && \
  ln -snf /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
  dpkg-reconfigure -f noninteractive tzdata && \
  rm -rf /var/lib/apt/lists/*

ENV LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8" LANGUAGE="en_US.UTF-8"

# Common packages
RUN apt-get update && apt-get install -y \
      build-essential \
      software-properties-common \
      psmisc \
      curl \
      git \
      wget \
      tmux \
      neovim \
      starship \
      fish \
      ledger \
      mosh \
      ruby \
      ruby-dev \
      python3-pip \
      mosquitto \
      mosquitto-clients \
      postgresql-client \
      jq \
      rsync \
      ansible && \
  rm -rf /var/lib/apt/lists/*

# Install Reticulum and dacar for rngit
RUN pip3 install --break-system-packages RNS dacar

# Install Node.js from multi-stage build
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Install pi coding agent
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# Install Bundler
RUN gem install bundler --no-document

# Create non-root user
RUN useradd -m -s /usr/bin/fish -u 1000 bergie

# Set up dotfiles
COPY --chown=bergie:bergie ./fish/* /home/bergie/.config/fish/
COPY --chown=bergie:bergie ./nvim/ /home/bergie/.config/nvim/
COPY --chown=bergie:bergie ./git/* /home/bergie/
COPY --chown=bergie:bergie ./pi/.pi/agent/AGENTS.md /home/bergie/.pi/agent/AGENTS.md
COPY --chown=bergie:bergie ./pi/.pi/agent/settings.json /home/bergie/.pi/agent/settings.json

# Preinstall pi packages so the image works out of the box
RUN pi install npm:pi-glm-usage && \
    pi install npm:pi-rngit-work-document-skill

# Switch to non-root user
USER bergie
WORKDIR /projects
VOLUME /projects
VOLUME /keys

# Enable colors
ENV TERM=xterm-256color

CMD ["tmux"]
