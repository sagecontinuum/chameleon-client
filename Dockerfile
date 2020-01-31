


#docker build -t chameleon-client .
#docker run -ti --rm -v ${HOME}/SAGE_project-openrc.sh:/SAGE_project-openrc.sh:ro chameleon-client /bin/bash


FROM python:3

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update &&  apt-get install -y jq


RUN pip install --upgrade pip
RUN pip install python-openstackclient


RUN pip install 'python-blazarclient>=1.1.1'
RUN pip install -e git+https://github.com/ChameleonCloud/python-blazarclient.git@chameleoncloud/stable/rocky#egg=python-blazarclient

