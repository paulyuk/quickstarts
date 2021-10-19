# DOCKER_IMAGE_PREFIX ?= distributed-calculator-
# APPS                ?= node python go csharp react-calculator
	
# include ../docker.mk
# include ../validate.mk

TARGET_DOTNET_PLATFORM = $(TARGET_ARCH)
ifeq ($(TARGET_DOTNET_PLATFORM),amd64)
  TARGET_DOTNET_PLATFORM = x64
endif

.PHONY: build, build_go, build_csharp, build_python, build_node, build_react

build: build_go build_csharp build_python build_go build_react

build_go:
	cd ./go && go get -u github.com/gorilla/mux && go build app.go

build_csharp_local:
	#cd csharp && dotnet restore -r linux-$(TARGET_DOTNET_PLATFORM)
	cd csharp && dotnet build
	cd csharp && dotnet publish -c Release -o out

build_csharp: build_csharp_local

build_python:
	cd ./python && pip3 install -r requirements.txt

build_node:
	cd ./node && npm install

build_react:
	cd ./react-calculator && npm install && npm run buildclient
