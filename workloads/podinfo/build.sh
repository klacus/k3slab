#!/bin/bash

VERSIONTAG=1.0.0

docker build -t podinfo:${VERSIONTAG} .

docker tag podinfo:${VERSIONTAG} registry.services.labk3s.perihelion.lan/podinfo:${VERSIONTAG}

docker images | grep podinfo

docker push registry.services.labk3s.perihelion.lan/podinfo:${VERSIONTAG}

curl -L https://registry.services.labk3s.perihelion.lan/v2/_catalog
curl -L https://registry.services.labk3s.perihelion.lan/v2/podinfo/tags/list
