FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y cowsay fortune-mod netcat && \
    ln -s /usr/games/cowsay /usr/bin/cowsay && \
    ln -s /usr/games/fortune /usr/bin/fortune && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /wisecow

COPY wisecow.sh /wisecow/wisecow.sh
RUN chmod +x wisecow.sh

EXPOSE 4499

CMD ["bash", "wisecow.sh"]