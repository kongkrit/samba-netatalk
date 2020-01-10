FROM ubuntu:20.04

RUN apt update

RUN apt install -y samba

RUN apt install -y netatalk

RUN apt install -y nano

RUN apt autoremove -y && apt clean

COPY entrypoint.sh /entrypoint.sh
COPY afp.conf /etc/netatalk/afp.conf

CMD ["/bin/bash", "/entrypoint.sh"]

