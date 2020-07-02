# chameleon-client


##  OpenStack RC File
Once you created Chameleon user account and have been added to the SAGE project in Chameleon, download the OpenStack RC File. Go to [https://chi.uc.chameleoncloud.org/project/](https://chi.uc.chameleoncloud.org/project/). Click on your username in the top right corner of the web site and select "OpenStack RC File v3". Save that file somewhere on your machines, for example in your home directory like this: `${HOME}/SAGE_project-openrc.sh`

## ssh key
Upload an existing public key or create a new ssh key pair: Goto [https://chi.uc.chameleoncloud.org/project/key_pairs](https://chi.uc.chameleoncloud.org/project/key_pairs) and click on either "Import Public Key" or "Create Key Pair". You will need the private key to be able to ssh into an instance you created. They default place for a private key is `~/.ssh/id_rsa`. If have more than one ssh key you can also use a more descriptive names such as  `~/.ssh/chameleon.pem` and `~/.ssh/chameleon.pub`.


## Build container

```bash
docker build -t chameleon-client .
```

## Start container
```bash
docker run -ti --rm -v ${HOME}/SAGE_project-openrc.sh:/openrc.sh:ro chameleon-client /bin/bash
```

On start of the container your `openrc.sh` will be automatically sourced. Be sure to specify the correct path to that file in the `docker run` command. Note that the openrc.sh will ask you for your chameleon password every time you start the container.

## Start chameleon bare-metal instance

```bash
./create_instance.sh
```