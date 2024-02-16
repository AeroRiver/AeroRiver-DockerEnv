FROM ubuntu:latest
RUN apt-get update && \
    apt-get install -y sudo curl git build-essential python3-pip python3-distutils gcc-arm-none-eabi binutils-arm-none-eabi g++ clang && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash -u 1002 aeroriver && \
    usermod -aG sudo aeroriver && \
    echo "aeroriver ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /app

USER aeroriver 

RUN pip install --user empy==3.3.4 pexpect future

ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++

CMD ["bash"]
