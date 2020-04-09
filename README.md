# Alt-V-Docker-automating-your-Server
This is ONLY for Typescript alt-v resources serverside. Clientside has to be javascript.

1. Clone this repo and cd into the cloned folder.
2. Change docker-compose args git link and branch.
- git link: git@github.com:yourusername/your_altv_recource
- branch: master
3. 
```
docker-compose build --force-rm --build-arg SSH_KEY="$(cat ~/.ssh/id_rsa)"
docker-compose up
```
The build arg SSH_KEY gives the docker your ssh identity so you can clone from a private repo. Change the path if your ssh key is located somewhere else.
