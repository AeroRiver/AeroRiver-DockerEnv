# Documentação do Ambiente Virtual Docker para Build da AeroRiver-ArduPilot

Este repositório contém a documentação e os scripts necessários para configurar e executar um ambiente virtual Docker para compilar o código do ArduPilot. O ArduPilot é um projeto que requer várias dependências de módulos Python e compiladores C e C++.

No cotidiano de desenvolvimento, ao compilar o código do ArduPilot diretamente no sistema operacional host, sofremos com problemas de versão de pacotes, variáveis de ambiente e "No meu computador funciona". Esses problemas podem comprometer o funcionamento do sistema operacional, já que outras aplicações e programas podem depender desses pacotes e configurações.

Para evitar esses problemas e garantir um ambiente de compilação consistente e isolado, foi configurado um ambiente virtual utilizando um contêiner Docker. Esse ambiente virtual permite construir o código com todas as dependências necessárias, sem interferir no funcionamento do Sistema Operacional hospedeiro e promovendo melhor rastreamento de erros.

**Obs:** Para manter o ambiente simples, eficaz e sem consumir muitos recursos de memória, o ambiente docker realiza apenas a parte referente ao build do código (comandos ./waf).

---

## 1 - Instalação do Docker

Antes de tudo, o primeiro passo para configurar o ambiente virtual de desenvolvimento é instalar o Docker. Em resumo breve, Docker é uma plataforma de software que permite criar, testar e implantar contêineres, uma forma de virtualização que encapsula o código, bibliotecas e depêndencias de uma aplicação em um único pacote. O Docker consiste em uma série de ferramentas, mas no caso do desenvolvimento na AeroRiver utilizaremos o Docker Engine, uma ferramenta CLI que permite criar e gerenciar contêineres Docker.

Para o passo-a-passo da instalação do Docker Engine veja o [Tutorial de Instalação Docker](InstallDocker.md).

---

## 2 - Dockerfile

Dockerfile é um arquivo de texto simples que contem uma lista de instruções que o Docker utiliza para criar a imagem do contêiner. A sua estrutura é simples:

```bash
FROM ubuntu:latest
```
- Esse comando define a imagem base que será utilizada como ponto de partida para a construção do contêiner. Nesse caso, é utilizada a versão mais recente disponível da imagem do Ubuntu.

```bash
WORKDIR /app
```
- Define o diretório de trabalho para /app, o que significa que todos os comandos subsequentes serão executados nesse diretório.

```bash
ARG USER_NAME="aeroriver"
ARG OPT="/opt"
ARG PKGS="sudo git g++ wget build-essential ccache g++-arm-linux-gnueabihf python3-pip python3-distutils"
ARG ARM_ROOT="gcc-arm-none-eabi-10-2020-q4-major"
```
- Definição de algumas variáveis a serem utilizadas nas configurações do Docker.

```bash
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    $PKGS && \
    rm -rf /var/lib/apt/lists/*
```
- Instalação dos pacotes básicos definidos na em PKGS, novos pacotes são adicionados nessa variável para instalação.

```bash
RUN cd $OPT && \
    sudo wget --no-check-certificate --progress=dot:giga https://firmware.ardupilot.org/Tools/STM32-tools/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2 && \
    sudo chmod -R 777 gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2 && \
    sudo tar xjf gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2 && \
    sudo rm gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2 && \
    sudo ln -s -f $(which ccache) /usr/lib/ccache/arm-none-eabi-g++ && \
    sudo ln -s -f $(which ccache) /usr/lib/ccache/arm-none-eabi-gcc
```
- Bloco para instalação do pacote arm-none-eabi, essencial para a compilação do código ardupilot.

```bash
ENV PATH="${OPT}/gcc-arm-none-eabi-10-2020-q4-major/bin:${PATH}"
```
- Configuração do caminho do compilador arm.

```bash
RUN useradd -m -s /bin/bash -u 1002 $USER_NAME && \
    usermod -aG sudo $USER_NAME && \
    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USER_NAME
```
- Criação do usúario não root com permissões sudo.

```bash
RUN pip install --user empy==3.3.4 pexpect future
```
- Instalação de pacotes de python utilizados pelo ardupilot, dentro da pasta do usuário.

```bash
RUN sudo apt-get clean && \
    sudo apt-get autoclean && \
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```
- Limpeza de pacotes e variáveis temporárias para economizar espaço em disco.

```bash
CMD ["bash"]
```
- Definição do comando a ser executado ao entrar no contêiner.

---

## 3 - Docker Build

Para criar efetivamente o ambiente virtual é preciso construir o docker a partir do Dockerfile, executando o comando:

```bash
docker build -t env .
```
- Nesse comando evocamos o docker build utilizado para construir imagens Docker passando como parâmetros ```-t env```, que atribui a tag env ao contêiner e ```.```, que é o diretório de contexto onde o docker buscará pelos arquivos necessários para criação da imagem.

---

## 4 - Docker Run

Ao executar o docker build uma imagem docker será criada e ficará disponível para uso, contendo todos as instruções especificadas anteriormente. Para executar o contêiner basta evocar o comando:

```bash
docker run -it env
```
- Esse comando simples irá executar a imagem com a tag (-t) env, de modo iterativo (-i), ou seja, significa que você terá acesso ao terminal do contêiner. É possível passar mais argumentos para o docker run a fim de montar volumes ou executar comandos específicos.

Para montar a pasta do ardupilot dentro do contêiner e ser possível construir o código basta executar o comando:

```bash
docker run -it --name aeroriver \
    -v /caminho/para/ardupilot:/app/ArduPilot:rw \
    env
```
- Nesse comando passamos o parâmetro ```--name aeroriver``` para logar como o usuário criado e o parâmetro ```-v /caminho/para/ardupilot:/app/ArduPilot:rw``` monta o volume do ardupilot do computador local dentro da pasta /app/ArduPilot no contêiner, com as permisões read-write (```:rw```)
Desse modo, é possível passar o código do ardupilot de maneira sincronizada, ou seja, as alterações feitas no código no seu computador, se refletem no contêiner e os arquivos e binários gerados pelo contêiner, ficam disponível para uso local.

---

## 5 - Exemplo de uso:

Para facilitar, convém criar shell scripts para executar os comandos de build e run. Com o contêiner em execução é possível verficar seu funcionamento usando o comando ```docker ps -a```, que lista os contêineres ativos.

**Exemplo**
```bash
  LOCAL   |  Comando no terminal
host      ->      ./build.sh
host      ->      ./run.sh
contêiner ->      ./Tools/gittools/submodule-sync.sh -- Apenas se for a primeira vez em que o ArduPilot é executado.
contêiner ->      ./waf distclean
contêiner ->      ./waf configure --board=[Nome-da-Board] 
contêiner ->      ./waf [Nome-do-veículo]
```

Com isso o processo de build do ArduPilot é executado utilizando as dependências e pacotes do ambiente virtual e o binário do ardupilot (arduplane.exe ou arduplane por exemplo) fica disponível na pasta do host.

**ATT - ** Atualização para buildar o Docker com a biblioteca para executar a janela OSD ->
```bash
./waf configure --board=SITL --osd --enable-smfl --sitl-osd
```

---

Este repositório contém o [Dockerfile](Dockerfile) com as configurações mais recentes do ambiente virtual e os arquivos de [build](sample_build.txt) e [run](sample_run.txt). Este README apresenta uma visão geral do funcionamento e configuração do ambiente Docker,
além disso o [Guia de Instalação Docker](InstallDocker.md) apresenta um passo-a-passo para instalar o Docker Engine em sistemas Linux e Windows.

---






#### Pedro Masteguin


