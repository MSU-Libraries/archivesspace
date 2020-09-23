#!/bin/bash

docker exec solr curl -s http://localhost:8983/solr/archivesspace/update --data-binary '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
docker exec archivesspace rm -rf /archivesspace/data/*
systemctl restart archivesspace
