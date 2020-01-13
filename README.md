# samba-netatalk
- docker samba-netatalk (afpd) on ubuntu 20.04
- enhanced from [kongkrit/docker-netatalk](https://github.com/kongkrit/docker-netatalk) which is forked from [cptactionhank/docker-netatalk](https://github.com/cptactionhank/docker-netatalk)
- **VERY EARLY BETA QUALITY WORK. USE AT YOUR OWN RISK!**

## Quick Start
- Pull image `docker pull kongkrit/samba-netatalk:latest`
- Read the (yet-to-be-explained-but-pretty-self-explanatory) [config](https://raw.githubusercontent.com/kongkrit/samba-netatalk/master/config-sample5) file
- In there, you can see you need to create a folder per samba share, and a folder for time machine
- In the following example, we will put out samba data in `/home/dude/samba_data`, our time machine data in `/home/dude/samba_data/timemachine_data` and our config file at `/home/dude/samba-netatalk/config-sample5`
- Run:
```
docker run -d --restart always \
    --network host \
    -e PUID=$(id -u) -e PGID=$(id -g) \
    --name samba-netatalk \
    -v /home/dude/samba_data/:/samba_data \
    -v /home/dude/samba_data/timemachine_data/:/timemachine_data \
    -v /home/dude/samba-netatalk/config-sample5:/config \
    kongkrit/samba-netatalk
```
- Further explanation:
  - The built-in Avahi daemon won't work unless the container is run from host network, which isn't ideal.
  - if you do not want to run from host network, replace the run above with:
  ```
  docker run -d --restart always \
    -p 137:137/udp -p 138:138/udp -p 139:139/tcp -p 445:445/tcp \
    -p 548:548/tcp \
    -e PUID=$(id -u) -e PGID=$(id -g) \
    --name samba-netatalk \
    -v /home/dude/samba_data/:/samba_data \
    -v /home/dude/samba_data/timemachine_data/:/timemachine_data \
    -v /home/dude/samba-netatalk/config-sample5:/config \
    kongkrit/samba-netatalk
  ```
  Avahi uses 5353/udp which will no longer work Here are the ports used by Samba / Netatalk (AFPD) - info from [here](https://support.apple.com/en-us/HT202944)
  
  |Port Number|Protocol|Explanation|
  |:---------:|:------:|:----------|
  | 137 | udp | WINS service |
  | 138 | udp | NETBIOS service |
  | 139 | tcp | SMB |
  | 445 | tcp | SMB Domain Server |
  | 548 | tcp | AFP over TCP |
  | 139 | tcp | SMB traffic |
  |5353 | udp | Avahi daemon (will not work from docker bridge) |
