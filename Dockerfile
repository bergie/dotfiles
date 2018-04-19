FROM ubuntu:latest

# Locales
RUN apt-get update && apt-get install -y locales
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# Common packages
RUN apt-get update && apt-get install -y \
      build-essential \
      software-properties-common \
      tzdata \
      psmisc \
      curl \
      git \
      wget \
      tmux \
      vim \
      zsh \
      ledger \
      mosh \
      ruby \
      ruby-dev \
      mosquitto \
      mosquitto-clients

# Install Node.js LTS
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs

# Install Ansible
RUN apt-add-repository ppa:ansible/ansible && apt-get update && apt-get install -y ansible

# Install Travis CLI and Bundler
RUN gem install travis bundler --no-rdoc --no-ri

# Install Heroku toolbelt
RUN wget -qO- https://cli-assets.heroku.com/install-ubuntu.sh | sh

# Install oh-my-zsh
RUN chsh -s /usr/bin/zsh
RUN curl -L http://install.ohmyz.sh | sh || true

# Set up timezone
ENV TZ 'Europe/Berlin'
RUN echo $TZ > /etc/timezone && \
    rm /etc/localtime && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Set up dotfiles
COPY ./zsh/* /root/
COPY ./vim/ /root/
COPY ./git/* /root/

# Set up volumes
WORKDIR /projects
VOLUME /projects
VOLUME /keys

# Enable colors
ENV TERM=xterm-256color

CMD ["tmux"]
