FROM ubuntu:20.04

RUN apt update
RUN apt install -y samba
RUN apt install -y netatalk

RUN apt install -y nano

RUN apt autoremove -y && apt clean

# AFP TCP transfer
EXPOSE 548/tcp
# AVAHI UDP Port, will only work if network is host, though
#EXPOSE 5353/udp

# Samba ports
EXPOSE 137/udp 138/udp 139/tcp 445/tcp

COPY parser.sh /parser.sh
COPY samba-config.sh /samba-config.sh
COPY netatalk-config.sh /netatalk-config.sh
COPY afp-head.conf /afp-head.conf
COPY smb-head.conf /smb-head.conf
COPY entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
#CMD ["/bin/bash"]
