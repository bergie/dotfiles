FROM ubuntu:latest

# Locales
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
RUN apt-get update && apt-get install -y locales && locale-gen en_US.UTF-8

# Common packages
RUN apt-get update && apt-get install -y \
      build-essential \
      curl \
      git \
      wget \
      tmux \
      vim \
      zsh \
      mosquitto \
      mosquitto-clients

# Install Node.js LTS
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs

# Install oh-my-zsh
RUN chsh -s /usr/bin/zsh
RUN curl -L http://install.ohmyz.sh | sh || true

# Set up dotfiles
COPY ./zsh/* /root/
COPY ./vim/ /root/
COPY ./git/* /root/

# Set up volumes
WORKDIR /projects
VOLUME /projects
VOLUME /keys

CMD ["tmux"]
