FROM node:12.13.1-buster
LABEL maintainer="https://gitlab.com/timstallinger"
WORKDIR /altv

# Build args are defined in docker-compose.yml
ARG SERVER_NAME
ARG SERVER_DESCRIPTION
ARG SERVER_PLAYERS
ARG SERVER_ANNOUNCE
ARG SERVER_TOKEN
ARG SERVER_WEBSITE
ARG SERVER_LANGUAGE
ARG SERVER_DEBUG
ARG SERVER_STREAMINGDISTANCE
ARG SERVER_PASSWORD
ARG ALTV_VERSION
ARG SSH_KEY
ARG GIT_LINK
ARG BRANCH

# Install from Repo
RUN apt-get update && apt-get install -y git
RUN mkdir /root/.ssh/
RUN echo "${SSH_KEY}" > /root/.ssh/id_rsa
RUN chmod 400 ~/.ssh/id_rsa
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan gitlab.com >> /root/.ssh/known_hosts
RUN mkdir git
RUN chown 82:82 git/
RUN git clone ${GIT_LINK} git && cd git/
COPY . /altv/git
RUN cd git && git checkout ${ARG BRANCH}
RUN cd .. && mkdir server && cd server

# Install Alt:V
RUN bash -c 'mkdir {data,modules,resources-data}' && \
    wget -nv --show-progress --progress=bar:force:noscroll -P . https://cdn.altv.mp/node-module/${ALTV_VERSION}/x64_linux/update.json && \
    wget -nv --show-progress --progress=bar:force:noscroll -P . https://cdn.altv.mp/server/${ALTV_VERSION}/x64_linux/altv-server && chmod +x altv-server && \
    wget -nv --show-progress --progress=bar:force:noscroll -P modules/ https://cdn.altv.mp/node-module/${ALTV_VERSION}/x64_linux/modules/libnode-module.so && \
    wget -nv --show-progress --progress=bar:force:noscroll -P . https://cdn.altv.mp/node-module/${ALTV_VERSION}/x64_linux/libnode.so.72 && \
    wget -nv --show-progress --progress=bar:force:noscroll -P data/ https://cdn.altv.mp/server/${ALTV_VERSION}/x64_linux/data/vehmodels.bin && \
    wget -nv --show-progress --progress=bar:force:noscroll -P data/ https://cdn.altv.mp/server/${ALTV_VERSION}/x64_linux/data/vehmods.bin && \
    wget -nv --show-progress --progress=bar:force:noscroll -P . https://cdn.altv.mp/others/start.sh && chmod +x start.sh

# AltV configuration
RUN echo '\
name: '$SERVER_NAME'\n\
host: 0.0.0.0\n\
port: 7788\n\
players: '$SERVER_PLAYERS'\n\
announce: '$SERVER_ANNOUNCE'\n\
gamemode: XTREAM-V\n\
website: '$SERVER_WEBSITE'\n\
language: '$SERVER_LANGUAGE'\n\
description: '$SERVER_DESCRIPTION'\n\
modules: [ node-module ]\n\
resources: [ freeroam ]\n\
token: '$SERVER_TOKEN'\n\
debug: '$SERVER_DEBUG'\n\
streamingDistance: '$SERVER_STREAMINGDISTANCE'\n\
password: '$SERVER_PASSWORD'\n\
' > server.cfg
RUN cat server.cfg

#BUILD TYPESCRIPT
RUN cd /altv/git/ && npm install && node start
RUN cp -avr /altv/git/client /altv/resources/freeroam/ && cp -av /altv/git/resource.cfg /altv/resources/freeroam/ && cp /altv/git/package.json /altv/
RUN npm install


# Don't write to log file - let Docker log-driver handle it
# Remove private ssh key
RUN ln -s /dev/null server.log
RUN rm /root/.ssh/id_rsa

# Start AltV Server
USER 0
#ENTRYPOINT ["/bin/bash"]
ENTRYPOINT ["/altv/start.sh"]
CMD ["bash"]