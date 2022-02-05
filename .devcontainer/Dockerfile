# ------------------------------------------------------------
# Copyright (c) Microsoft Corporation and Dapr Contributors.
# Licensed under the MIT License.
# ------------------------------------------------------------
ARG VARIANT=3-bullseye
FROM mcr.microsoft.com/vscode/devcontainers/python:${VARIANT}
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

# Install GoLang
#RUN sudo apt install golang -y
ENV PATH /usr/local/go/bin:$PATH

ENV GOLANG_VERSION 1.17.1

RUN set -eux; \
	arch="$(dpkg --print-architecture)"; arch="${arch##*-}"; \
	url=; \
	case "$arch" in \
		'amd64') \
			url='https://dl.google.com/go/go1.17.1.linux-amd64.tar.gz'; \
			sha256='dab7d9c34361dc21ec237d584590d72500652e7c909bf082758fb63064fca0ef'; \
			;; \
		'armel') \
			export GOARCH='arm' GOARM='5' GOOS='linux'; \
			;; \
		'armhf') \
			url='https://dl.google.com/go/go1.17.1.linux-armv6l.tar.gz'; \
			sha256='ed3e4dbc9b80353f6482c441d65b51808290e94ff1d15d56da5f4a7be7353758'; \
			;; \
		'arm64') \
			url='https://dl.google.com/go/go1.17.1.linux-arm64.tar.gz'; \
			sha256='53b29236fa03ed862670a5e5e2ab2439a2dc288fe61544aa392062104ac0128c'; \
			;; \
		'i386') \
			url='https://dl.google.com/go/go1.17.1.linux-386.tar.gz'; \
			sha256='e60bb44046f424ba2cc47db7b183079b5add2f8cfa6887daf45bf2f317cc2f53'; \
			;; \
		'mips64el') \
			export GOARCH='mips64le' GOOS='linux'; \
			;; \
		'ppc64el') \
			url='https://dl.google.com/go/go1.17.1.linux-ppc64le.tar.gz'; \
			sha256='df4fa945512c3b472cf3d2dcb2e4ae5b34819607bc63f3223f5bc0c17b637dd0'; \
			;; \
		's390x') \
			url='https://dl.google.com/go/go1.17.1.linux-s390x.tar.gz'; \
			sha256='f770b72e1e1281239b12b64825f87a928a1788943c7f09cac7f28985ef2cf692'; \
			;; \
		*) echo >&2 "error: unsupported architecture '$arch' (likely packaging update needed)"; exit 1 ;; \
	esac; \
	build=; \
	if [ -z "$url" ]; then \
# https://github.com/golang/go/issues/38536#issuecomment-616897960
		build=1; \
		url='https://dl.google.com/go/go1.17.1.src.tar.gz'; \
		sha256='49dc08339770acd5613312db8c141eaf61779995577b89d93b541ef83067e5b1'; \
		echo >&2; \
		echo >&2 "warning: current architecture ($arch) does not have a compatible Go binary release; will be building from source"; \
		echo >&2; \
	fi; \
	\
	wget -O go.tgz.asc "$url.asc"; \
	wget -O go.tgz "$url" --progress=dot:giga; \
	echo "$sha256 *go.tgz" | sha256sum -c -; \
	\
# https://github.com/golang/go/issues/14739#issuecomment-324767697
	GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
# https://www.google.com/linuxrepositories/
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 'EB4C 1BFD 4F04 2F6D DDCC EC91 7721 F63B D38B 4796'; \
	gpg --batch --verify go.tgz.asc go.tgz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" go.tgz.asc; \
	\
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	\
	if [ -n "$build" ]; then \
		savedAptMark="$(apt-mark showmanual)"; \
		apt-get update; \
		apt-get install -y --no-install-recommends golang-go; \
		\
		( \
			cd /usr/local/go/src; \
# set GOROOT_BOOTSTRAP + GOHOST* such that we can build Go successfully
			export GOROOT_BOOTSTRAP="$(go env GOROOT)" GOHOSTOS="$GOOS" GOHOSTARCH="$GOARCH"; \
			./make.bash; \
		); \
		\
		apt-mark auto '.*' > /dev/null; \
		apt-mark manual $savedAptMark > /dev/null; \
		apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
		rm -rf /var/lib/apt/lists/*; \
		\
# pre-compile the standard library, just like the official binary release tarballs do
		go install std; \
# go install: -race is only supported on linux/amd64, linux/ppc64le, linux/arm64, freebsd/amd64, netbsd/amd64, darwin/amd64 and windows/amd64
#		go install -race std; \
		\
# remove a few intermediate / bootstrapping files the official binary release tarballs do not contain
		rm -rf \
			/usr/local/go/pkg/*/cmd \
			/usr/local/go/pkg/bootstrap \
			/usr/local/go/pkg/obj \
			/usr/local/go/pkg/tool/*/api \
			/usr/local/go/pkg/tool/*/go_bootstrap \
			/usr/local/go/src/cmd/dist/dist \
		; \
	fi; \
	\
	go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

# Install .NET Core 3.1.x runtime
ENV \
    # Unset ASPNETCORE_URLS from aspnet base image
    ASPNETCORE_URLS= \
    # Do not generate certificate
    DOTNET_GENERATE_ASPNET_CERTIFICATE=false \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # SDK version
    DOTNET_SDK_VERSION=3.1.19 \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Unset Logging__Console__FormatterName from aspnet base image
    Logging__Console__FormatterName= \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # PowerShell telemetry for docker image usage
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-DotnetSDK-Debian-11 \
	# Set download filename and install path
	DOTNET_FILE=dotnet.tar.gz \
	DOTNET_ROOT=/usr/share/dotnet
RUN curl -SL --output "$DOTNET_FILE" https://download.visualstudio.microsoft.com/download/pr/05c0293f-fabb-4d0a-926b-34f28c3ae4f0/b6666e2c4838ff24fb27447ee8437291/aspnetcore-runtime-3.1.19-linux-arm64.tar.gz
RUN dotnet_sha512='4cba9b43a9beb977bb50c290c0e7cbbf42664538609079dd1bc0e925a0cc4a1f76748492d4d0d402610ae910e878449bab5d797a9f12e63399585b11f9bfbee9'
RUN echo "$dotnet_sha512  $DOTNET_FILE"
RUN mkdir -p "$DOTNET_ROOT" \
    && tar -C "$DOTNET_ROOT" -xzf "$DOTNET_FILE" \
    && rm "$DOTNET_FILE" \
	&& echo "unpacked to ${DOTNET_ROOT}"

# Install .NET 5 runtime
ENV \
    # Alter SDK version
    DOTNET_SDK_VERSION=5.0.401

RUN curl -SL --output "$DOTNET_FILE" https://download.visualstudio.microsoft.com/download/pr/2ce6cf91-6aff-4565-87df-d20212418009/e3a924fa1192637dcd7379c1109e14e0/aspnetcore-runtime-5.0.10-linux-arm64.tar.gz
RUN dotnet_sha512='e86dd5b26e5add2f35c3a029c78e3c447755a319c105d371da297f66db5eff260f3f55ccf23e508e9a33536876708ac2e358dc62a4a28518f88df3a9131adb01'
RUN echo "$dotnet_sha512  $DOTNET_FILE"
RUN mkdir -p "$DOTNET_ROOT" \
    && tar -C "$DOTNET_ROOT" -xzf "$DOTNET_FILE" \
    && rm "$DOTNET_FILE" \
	&& echo "unpacked to ${DOTNET_ROOT}"

# Install .NET 6 SDK & runtime
ENV \
    # Alter SDK version
    DOTNET_SDK_VERSION=6.0.101

ENV PATH "${DOTNET_ROOT}:${PATH}"
RUN curl -SL --output "$DOTNET_FILE" https://download.visualstudio.microsoft.com/download/pr/d43345e2-f0d7-4866-b56e-419071f30ebe/68debcece0276e9b25a65ec5798cf07b/dotnet-sdk-6.0.101-linux-arm64.tar.gz
RUN dotnet_sha512='04cd89279f412ae6b11170d1724c6ac42bb5d4fae8352020a1f28511086dd6d6af2106dd48ebe3b39d312a21ee8925115de51979687a9161819a3a29e270a954'
RUN echo "$dotnet_sha512  $DOTNET_FILE"
RUN mkdir -p "$DOTNET_ROOT" \
    && tar -C "$DOTNET_ROOT" -xzf "$DOTNET_FILE" \
    && rm "$DOTNET_FILE" \
	&& echo "unpacked to ${DOTNET_ROOT}"

    # Trigger first run experience by running arbitrary cmd
    ## && dotnet help

ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]
