#!/usr/bin/env bash

set -e # bail out early if any command fails
# set -u # fail if we hit unset variables
set -o pipefail # fail if any component of any pipe fails

if [ -z "$1" ]
  then
    echo "No argument supplied, you need to pass the name of the route/host"
    echo "You can get names by issuing cf routes and looking at the host column."
    echo ""
    echo "show_weight.sh <host>"
    exit 1
fi

routeName=${1}
routeInfo=$(cf curl "/v2/routes?q=host:${routeName}")
routeGuid=$(echo ${routeInfo} | jq -r '.resources[].metadata.guid')
routeMappings=$(cf curl /v2/routes/${routeGuid}/route_mappings | jq -r -c '.resources[]')
appsUrl=$(echo ${routeInfo} | jq -r '.resources[].entity.apps_url')
routeDomainUrl=$(echo ${routeInfo} | jq -r '.resources[].entity.domain_url')
routeDomain=$(cf curl ${routeDomainUrl} | jq -r -c .entity.name)
echo Route: ${routeName}.${routeDomain}

# Get the apps that are part of the URL
for app in $(cf curl ${appsUrl} | jq -r -c '.resources[].entity.name')
do

  appGuid=$(cf app ${app} --guid)
  weights=$(cf curl /v3/apps/${appGuid}/route_mappings | jq -r -c '.resources[]')

  for weight in ${weights}
  do
    values=$(echo ${weight} | jq -r '.weight')

    for value in ${values}
    do
    
      appURL=$(echo ${weight} | jq -r '.links.app.href')
      appRoute=$(echo ${weight} | jq -r '.links.route.href')
      appGuid=${appURL##*/}
      appRouteGuid=${appRoute##*/}

      if [[ "${appRouteGuid}" == "${routeGuid}" ]]
      then
        appName=$(cf curl /v3/apps/${appGuid} | jq -r '.name')
        echo App: ${appName} $'\t' Weight: ${value}
      fi

    done
  done
done