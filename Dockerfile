

# docker build -t chameleon-client .
# docker run -ti --rm -v ${HOME}/SAGE_project-openrc.sh:/openrc.sh:ro chameleon-client /bin/bash


FROM python:3

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update &&  apt-get install -y jq


RUN pip install --upgrade pip
RUN pip install python-openstackclient python-heatclient


RUN pip install 'python-blazarclient>=1.1.1'
RUN pip install -e git+https://github.com/ChameleonCloud/python-blazarclient.git@chameleoncloud/stable/rocky#egg=python-blazarclient

COPY *.sh /chameleon/

WORKDIR /chameleon/

# this makes sure the mounted openrc.sh will be sourced (warning: there is no error is the file is missing)
ENTRYPOINT /bin/bash --rcfile /openrc.sh
