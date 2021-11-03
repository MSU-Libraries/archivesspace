FROM ubuntu:20.04
ARG AS_VERSION
ARG CONFIG_PATCH_FILE

ENV TZ="America/Detroit"
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y tzdata

RUN apt-get -y install --no-install-recommends \
      build-essential \
      git \
      openjdk-8-jre-headless \
      openjdk-8-jdk \
      ca-certificates \
      wget \
      openssh-server \
      vim \
      unzip \
      netbase

COPY . /customizations

COPY docker-startup.sh /startup.sh

RUN mkdir /source && \
    cd /source && \
    git clone https://github.com/archivesspace/archivesspace.git . && \
    if [ "x$AS_VERSION" = "x" ] ; then ARCHIVESSPACE_VERSION=${SOURCE_BRANCH:-`git tag -l --sort=v:refname | egrep '^v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$' | tail -1`} ; \
    else ARCHIVESSPACE_VERSION=$AS_VERSION ; fi && \
    echo "Using version: $ARCHIVESSPACE_VERSION" && \
    cd / && \
    rm -r /source && \
    wget -q https://github.com/archivesspace/archivesspace/releases/download/$ARCHIVESSPACE_VERSION/archivesspace-$ARCHIVESSPACE_VERSION.zip && \
    unzip -q /*.zip -d / && \
    wget -q https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.20/mysql-connector-java-8.0.20.jar && \
    cp /mysql-connector-java-8.0.20.jar /archivesspace/lib/ && \
    # Example of using a custom theme
    #mkdir /archivesspace/plugins/msul-theme && \
    #git clone -b merged https://gitlab.msu.edu/msu-libraries/public/archivesspace-customizations.git /archivesspace/plugins/msul-theme/  && \
    # TODO -- add in any custom plugin clones here
    # example: git clone https://github.com/AtlasSystems/ArchivesSpace-Aeon-Fulfillment-Plugin /archivesspace/plugins/aeon-fulfillment/ && \
    cd /archivesspace/config && \
    patch < /customizations/$CONFIG_PATCH_FILE && \
    mv /startup.sh /archivesspace/startup.sh && \
    chmod u+x /archivesspace/startup.sh && \
    groupadd -g 1000 archivesspace && \
    useradd -l -M -u 1000 -g archivesspace archivesspace && \
    chown -R archivesspace:archivesspace /archivesspace


USER archivesspace

EXPOSE 8080 8081 8089 8090 8092

HEALTHCHECK --interval=1m --timeout=5s --start-period=5m --retries=2 \
  CMD wget -q --spider http://localhost:8089/ || exit 1

CMD ["/archivesspace/startup.sh"]
