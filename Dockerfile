FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/New_York

RUN apt-get update && apt-get install -y \
    cmake \
    g++ \
    wget \
    unzip \
    psmisc \
    git \
    python3.7 \
    python3-dev \
    python-virtualenv \
    virtualenv \
    python-dev \
    libffi-dev \
    build-essential \
    tzdata \
    zlib1g-dev \
    libjpeg-dev

RUN cd /tmp/ && \
    wget https://github.com/jacksonliam/mjpg-streamer/archive/master.zip && \
    unzip master

RUN cd /tmp/mjpg-streamer-master/mjpg-streamer-experimental/ && \
    make && \
    make install

EXPOSE 5000

ARG tag=master

WORKDIR /opt/octoprint

#Create an octoprint user
RUN useradd -ms /bin/bash octoprint && adduser octoprint dialout
RUN chown octoprint:octoprint /opt/octoprint
USER octoprint

#This fixes issues with the volume command setting wrong permissions
RUN mkdir /home/octoprint/.octoprint

#Install Octoprint
RUN git clone --branch $tag https://github.com/OctoPrint/OctoPrint.git /opt/octoprint \
  && virtualenv --python=python3 venv \
  && ./venv/bin/pip install OctoPrint

RUN /opt/octoprint/venv/bin/python -m pip install \
    https://github.com/eyal0/OctoPrint-PrintTimeGenius/archive/master.zip \
    https://github.com/imrahil/OctoPrint-NavbarTemp/archive/master.zip \
    https://github.com/bradcfisher/OctoPrint-ExcludeRegionPlugin/archive/master.zip \
    https://github.com/thelastWallE/OctoprintKlipperPlugin/archive/master.zip \
    https://github.com/jneilliii/OctoPrint-BedLevelVisualizer/archive/master.zip

VOLUME /home/octoprint/.octoprint

### Klipper setup ###

USER root

RUN apt-get install -y sudo

COPY klippy.sudoers /etc/sudoers.d/klippy

RUN useradd -ms /bin/bash klippy

# This is to allow the install script to run without error
RUN ln -s /bin/true /bin/systemctl

USER octoprint

WORKDIR /home/octoprint

RUN git clone https://github.com/Klipper3d/klipper

RUN ./klipper/scripts/install-ubuntu-18.04.sh

USER root

#RUN echo "export LC_ALL=C.UTF-8" >> ~/.bashrc
#RUN echo "export LANG=C.UTF-8" >> ~/.bashrc

# Clean up hack for install script
RUN rm -f /bin/systemctl

COPY start.py /
COPY runklipper.py /

#ENV LC_ALL=C.utf-8
#ENV LANG=C.utf-8

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y locales \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8 
ENV LC_ALL en_US.UTF-

CMD ["/start.py"]
