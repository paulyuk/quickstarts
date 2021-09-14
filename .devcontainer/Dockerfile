# ------------------------------------------------------------
# Copyright (c) Microsoft Corporation and Dapr Contributors.
# Licensed under the MIT License.
# ------------------------------------------------------------

FROM mcr.microsoft.com/vscode/devcontainers/python:dev-3.9-bullseye
# Copy custom first notice message.
COPY first-run-notice.txt /tmp/staging/
RUN sudo mv -f /tmp/staging/first-run-notice.txt /usr/local/etc/vscode-dev-containers/ \
    && sudo rm -rf /tmp/staging

# Install minikube
RUN MINIKUBE_URL="https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64" \
    && sudo curl -sSL -o /usr/local/bin/minikube "${MINIKUBE_URL}" \
    && sudo chmod 0755 /usr/local/bin/minikube \
    && MINIKUBE_SHA256=$(curl -sSL "${MINIKUBE_URL}.sha256") \
    && echo "${MINIKUBE_SHA256} */usr/local/bin/minikube" | sha256sum -c -

# Install Dapr CLI
RUN wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash

# Install mechanical-markdown for quickstart validations
RUN pip install mechanical-markdown

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"
# [Option] Enable non-root Docker access in container
ARG ENABLE_NONROOT_DOCKER="true"
# [Option] Use the OSS Moby Engine instead of the licensed Docker Engine
ARG USE_MOBY="true"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your
# own dependencies. A user of "automatic" attempts to reuse an user ID if one already exists.
ARG USERNAME=automatic
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    # Use Docker script from script library to set things up
    && /bin/bash /tmp/library-scripts/docker-in-docker-debian.sh "${ENABLE_NONROOT_DOCKER}" "${USERNAME}" "${USE_MOBY}" \
    # Clean up
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/
    
VOLUME [ "/var/lib/docker" ]

# Install openjdk11 for Java apps
ENV INSTALL_PATH /usr/lib/jvm
RUN wget https://aka.ms/download-jdk/microsoft-jdk-16.0.2.7.1-linux-aarch64.tar.gz
RUN mkdir "${INSTALL_PATH}" \
    && tar xzf microsoft-jdk-16.0.2.7.1-linux-aarch64.tar.gz -C "${INSTALL_PATH}"
#COPY --from=mcr.microsoft.com/openjdk/jdk:11-ubuntu $JAVA_HOME $JAVA_HOME
ENV JAVA_HOME "${INSTALL_PATH}/jdk-16.0.2+7"
ENV PATH "${JAVA_HOME}/bin:${PATH}"

# Install Node.Js and NPM for Javascript apps
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash - \
    && sudo apt install nodejs

ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]
