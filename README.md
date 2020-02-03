# chameleon-client


##  OpenStack RC File
Once you created Chameleon user account and have been added to the SAGE project in Chameleon, download the OpenStack RC File. Go to [https://chi.uc.chameleoncloud.org/project/](https://chi.uc.chameleoncloud.org/project/). Click on your username in the top right corner of the web site and select "OpenStack RC File v3". Save that file somewhere on your machines, for example in your home directory like this: `${HOME}/SAGE_project-openrc.sh`


## Build container  (TODO: upload to docker hub)

```bash
docker build -t chameleon-client .
```

## Start container
```bash
docker run -ti --rm -v ${HOME}/SAGE_project-openrc.sh:/openrc.sh:ro chameleon-client /bin/bash
```

On start of the container your openrc.sh will be automatically sourced. Be sure to specify the correct path to that file in the `docker run` command.

## Start chameleon bare-metal instance

```bash
./start_instance.sh
```