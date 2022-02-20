# use balenalib/raspberry-pi-debian:buster  for Raspberry 1, Zero, Zero W
# use balenalib/armv7hf-debian:buster for Raspberry 2,3,4
FROM balenalib/armv7hf-debian:buster

#dynamic build arguments coming from the /hooks/build file
ARG BUILD_DATE
ARG VCS_REF

#metadata labels
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/schreinerman/docker-arm-openmediavault" \
      org.label-schema.vcs-ref=$VCS_REF

#version
ENV IOEXPERT_DOCKER_ARM_OPENMEDIAVAULT_VERSION 1.0.0

#labeling
LABEL maintainer="info@io-expert.com" \
      version=$IOEXPERT_DOCKER_ARM_OPENMEDIAVAULT_VERSION \
      description="Docker ARM Openmediavault"

ENV VERSION $IOEXPERT_DOCKER_ARM_OPENMEDIAVAULT_VERSION

#copy init.d files
COPY "./init.d/*" /etc/init.d/

RUN [ "cross-build-start" ]

#init atitude
RUN apt-get update  \
    && apt-get install wget \
    && wget https://archive.raspbian.org/raspbian.public.key -O - | apt-key add - \
    && echo 'deb http://raspbian.raspberrypi.org/raspbian/ stretch main contrib non-free rpi' | tee -a /etc/apt/sources.list \
    && wget -O - http://archive.raspberrypi.org/debian/raspberrypi.gpg.key | apt-key add - \
    && echo 'deb http://archive.raspberrypi.org/debian/ stretch main ui' | tee -a /etc/apt/sources.list.d/raspi.list \
    && apt-get update

#install requirements
RUN apt-get install php

# Workaround for resolvconf issue
RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections

# Add OMV repo
RUN echo "deb http://packages.openmediavault.org/public usul main" | tee -a /etc/apt/sources.list.d/openmediavault.list && \
  wget -O - http://packages.openmediavault.org/public/archive.key | apt-key add -

# Install OMV
RUN apt-get update && apt-get install openmediavault

# Install OMV Extras
# RUN wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | bash

#clean-up
RUN rm -rf /tmp/* \
 && apt remove git \
 && apt autoremove \
 && apt upgrade \
 && rm -rf /var/lib/apt/lists/*
 
RUN [ "cross-build-end" ]

EXPOSE 22 80 443

# Persistence volume:
VOLUME ["/data"]

# Keep settings thru update
VOLUME ["/etc/openmediavault"]

# Command
CMD ["/bin/bash"]
