FROM debian:bullseye

# update system and get base packages
RUN apt-get update && \
    apt-get install -y firefox-esr curl gcc git make python python2.7-dev virtualenv libfreetype6-dev libsdl1.2debian libfdt1 libpixman-1-0 libglib2.0-dev gcc-arm-none-eabi && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# set the version of the pebble tool
ENV PEBBLE_TOOL_VERSION pebble-sdk-4.6-rc2-linux64
# set the version of pre installed
ENV PEBBLE_SDK_VERSION 4.3

# get pebble tool
RUN curl -sSL https://rebble-sdk.s3-us-west-2.amazonaws.com/${PEBBLE_TOOL_VERSION}.tar.bz2 | tar -C /opt/ -xj

# prepare python environment 
WORKDIR /opt/${PEBBLE_TOOL_VERSION}

# Makes the emu-app-config implementation pass a file instead of an argument to the browser. 
# This fixes an issue where a webpage over 128kb will fail to launch due to the MAX_ARG_STRLEN limit present in most linux kernels
COPY large_app_config.patch .

RUN /bin/bash -c " \
        patch pebble-tool/pebble_tool/util/browser.py large_app_config.patch && \
        virtualenv --python=/usr/bin/python2.7 .env && \
        source .env/bin/activate && \
        curl -sSL https://bootstrap.pypa.io/pip/2.7/get-pip.py | python && \
        pip install -r requirements.txt && \
        pip install certifi && \
        deactivate " && \
    rm -r /root/.cache/

# disable analytics & add pebble user - necesary for Arch linux hosts
RUN adduser --disabled-password --gecos "" --ingroup users pebble && \
    echo "pebble ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chmod -R 777 /opt/${PEBBLE_TOOL_VERSION} && \
    mkdir -p /home/pebble/.pebble-sdk/ && \
    chown -R pebble:users /home/pebble/.pebble-sdk && \
    touch /home/pebble/.pebble-sdk/NO_TRACKING

#switch user
USER pebble

#install nvm
ENV NODE_VERSION 10.16.2
ENV NVM_DIR /home/pebble/.nvm
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION

# set PATH
ENV PATH ${NVM_DIR}/versions/node/v${NODE_VERSION}/bin:/opt/${PEBBLE_TOOL_VERSION}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# install sdk
RUN yes | pebble sdk install latest

# set mount path
VOLUME /pebble/

#run command
WORKDIR /pebble/
ENTRYPOINT /opt/${PEBBLE_SDK_VERSION}/bin/pebble
