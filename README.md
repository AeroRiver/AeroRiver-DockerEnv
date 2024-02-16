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
RUN apt-get update && \
    apt-get install -y sudo curl git build-essential python3-pip python3-distutils gcc-arm-none-eabi binutils-arm-none-eabi g++ clang && \
    rm -rf /var/lib/apt/lists/*
```
- Aqui temos a instalação dos pacotes módulos e programas necessários para a construção do código do ArduPilot. Eventuais depêndencias e atualizações de pacotes são adicionados aqui.

```bash
RUN useradd -m -s /bin/bash -u 1002 aeroriver && \
    usermod -aG sudo aeroriver && \
    echo "aeroriver ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
```
- Esse bloco de comandos executa a criação e configuração de um novo usuário dentro do ambiente Docker. Alguns scripts do ardupilot não podem ser executados como root, a criação de um usuário com permissão de sudo, facilita o trabalho dentro do contêiner.

```bash
WORKDIR /app
```
- Define o diretório de trabalho para /app, o que significa que todos os comandos subsequentes serão executados nesse diretório.

```bash
USER aeroriver
```
- Define o usuário padrão para a execução dos comandos subsequentes, sendo esse usuário o criado anteriormente.

```bash
RUN pip install --user empy=3.3.4 pexpect future
```
- Esse bloco de comandos instala pacotes Python necessários para a execução do ardupilot. Novas depêndencias de pacotes ou atualização de versão são realizadas aqui.

```bash
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++
```
- Aqui há a definição das variáveis de ambiente para os compiladores C e C++, e a especificação dos diretórios nos quais o sistema deve procurar por executáveis quando um comando é executado.

```bash
CMD ["bash"]
```
- Define o comando padrão a ser executado quando o contêiner é iniciado. Nesse caso, inicia um terminal Shell Bash.

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

---

Este repositório contém o [Dockerfile](Dockerfile) com as configurações mais recentes do ambiente virtual e os arquivos de [build](sample_build.txt) e [run](sample_run.txt). Este README apresenta uma visão geral do funcionamento e configuração do ambiente Docker,
além disso o [Guia de Instalação Docker](InstallDocker.md) apresenta um passo-a-passo para instalar o Docker Engine em sistemas Linux e Windows.

---






#### Pedro Masteguin


