#!/bin/sh

cd /tmp

curl --silent -L http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${ES_VERSION}.tar.gz | tar -xz
./elasticsearch-${ES_VERSION}/bin/elasticsearch
