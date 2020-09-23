FROM solr:7.7
ARG AS_VERSION

ENV SOLR_VERSION=7.7 

USER root

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get -y install --no-install-recommends \
      git \
      wget

WORKDIR /opt/solr/server/solr/archivesspace

COPY core.properties core.properties


RUN if [ "x$AS_VERSION" = "x" ] ; then ARCHIVESSPACE_VERSION=${SOURCE_BRANCH:-`git ls-remote --tags --sort="v:refname" https://github.com/archivesspace/archivesspace.git | cut -d "/" -f 3 | egrep '^v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$' | tail -1`} ; \
    else ARCHIVESSPACE_VERSION=$AS_VERSION ; fi && \
    echo "Using version: $ARCHIVESSPACE_VERSION" && \
    mkdir conf && \
    mkdir data && \
    cd conf && \
    wget https://raw.githubusercontent.com/archivesspace/archivesspace/$ARCHIVESSPACE_VERSION/solr/solrconfig.xml && \
    wget https://raw.githubusercontent.com/archivesspace/archivesspace/$ARCHIVESSPACE_VERSION/solr/schema.xml && \
    touch stopwords.txt && \
    touch synonyms.txt && \
    chown -R solr:solr /opt/solr

USER solr

VOLUME /opt/solr/server/solr/archivesspace/data
