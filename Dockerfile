FROM ubuntu:latest
ARG DEBIAN_FRONTEND=noninteractive

# Locales, timezone, and common packages
RUN apt-get update && apt-get install -y \
      locales \
      tzdata && \
  echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
  locale-gen --purge "en_US.UTF-8" && \
  dpkg-reconfigure --frontend=noninteractive locales && \
  echo "Etc/UTC" > /etc/timezone && \
  rm /etc/localtime && \
  ln -snf /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
  dpkg-reconfigure -f noninteractive tzdata && \
  rm -rf /var/lib/apt/lists/*

ENV LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8" LANGUAGE="en_US.UTF-8"

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
  locale-gen --purge $LANG && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=$LANG LC_ALL=$LC_ALL LANGUAGE=$LANGUAGE

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
      mosquitto \
      mosquitto-clients \
      postgresql-client \
      jq \
      rsync \
      ansible && \
  rm -rf /var/lib/apt/lists/*

# Install Node.js LTS
RUN curl -sL https://deb.nodesource.com/setup_24.x | bash -
RUN apt-get install -y nodejs

# Install pi coding agent
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# Install Bundler
RUN gem install bundler --no-document

# Set fish as the default shell
RUN chsh -s /usr/bin/fish



# Set up dotfiles
COPY ./fish/* /root/
COPY ./nvim/ /root/
COPY ./git/* /root/
COPY ./pi/.pi/agent/AGENTS.md /root/.pi/agent/AGENTS.md
COPY ./pi/.pi/agent/settings.json /root/.pi/agent/settings.json

# Preinstall pi packages so the image works out of the box
RUN pi install npm:pi-glm-usage && \
    pi install npm:pi-rngit-work-document-skill

# Set up volumes
WORKDIR /projects
VOLUME /projects
VOLUME /keys

# Enable colors
ENV TERM=xterm-256color

CMD ["tmux"]
