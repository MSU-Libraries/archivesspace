FROM solr:7.7
ARG AS_VERSION

ENV SOLR_VERSION=7.7

USER root

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get -y install --no-install-recommends \
      git \
      wget \
      patch \ 
      vim

WORKDIR /opt/solr/server/solr/archivesspace

COPY core.properties core.properties
COPY schema.xml.patch /customizations/schema.xml.patch
COPY solrconfig.xml.patch /customizations/solrconfig.xml.patch


RUN if [ "x$AS_VERSION" = "x" ] ; then ARCHIVESSPACE_VERSION=${SOURCE_BRANCH:-`git ls-remote --tags --sort="v:refname" https://github.com/archivesspace/archivesspace.git | cut -d "/" -f 3 | egrep '^v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$' | tail -1`} ; \
    else ARCHIVESSPACE_VERSION=$AS_VERSION ; fi && \
    echo "Using version: $ARCHIVESSPACE_VERSION" && \
    mkdir conf && \
    mkdir data && \
    mkdir /archivesspace-release && \
    wget -q https://github.com/archivesspace/archivesspace/releases/download/$ARCHIVESSPACE_VERSION/archivesspace-$ARCHIVESSPACE_VERSION.zip && \
    unzip -q archivesspace-*.zip -d /archivesspace-release/. && \
    mkdir /archivesspace-release/solr && \
    unzip -q /archivesspace-release/archivesspace/wars/solr.war -d /archivesspace-release/solr && \
    cp /archivesspace-release/solr/WEB-INF/classes/* conf/ && \
    cd conf/ && \
    # Patching schema to uncomment ICU filter type for solr > v4
    patch < /customizations/schema.xml.patch && \
    # Patching solrconfig to include our lib directory for ICU jars
    patch < /customizations/solrconfig.xml.patch && \
    cd ../ && \
    mkdir lib && \
    cp /opt/solr/contrib/analysis-extras/lib/* lib/ && \
    cp /opt/solr/dist/solr-analysis-extras-*.jar lib/ && \
    cp /opt/solr/contrib/analysis-extras/lucene-libs/lucene-analyzers-icu-*.jar lib/ && \
    rm -r /archivesspace-release && \
    rm /opt/solr/server/solr/archivesspace/archivesspace-$ARCHIVESSPACE_VERSION.zip && \
    chown -R solr:solr /opt/solr

USER solr

VOLUME /opt/solr/server/solr/archivesspace/data
