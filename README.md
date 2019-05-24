![](https://pngimage.net/wp-content/uploads/2018/05/beta-png-2.png)

# Pivotal Application Service Weighted Routing

![](https://ezuce.com/media/uploads/beta-stamp.png)
NOTE: This is a beta feature so may change a little by GA

| Target Audience          | Difficulty | Experience | Time Needed | Impact (wow factor) |
| ------------------------ | ---------- | ---------- | ----------- | ------------------- |
| Developers, Architects   | Easy     | Low     | 30 min      |   👍    |

Shows how to configure weighted routing for your apps.

The weighted routing feature is available for Pivotal Application Service (PAS) deployments that use service mesh. For more information, see [Service Mesh (Beta)](https://docs.pivotal.io/pivotalcf/2-5/adminguide/service-mesh.html).

Weighted routing allows you to map multiple apps to the same route and control the amount of traffic sent to each of them. Some use cases include blue-green deployments, A/B testing, canary releases, or rolling out features over time to incremental user-bases.

## Demo

### Pre-reqs
The following will be needed for this demo to work;
* PAS with Service Mesh enabled
* `jq` on the machine you run the scripts
* `cf` CLI

After cloning the repo deploy the applications as defined in the `manifest.yml` file.

```
cf push
```

You should now have a number of apps running and ready to work though the demo.

### Simple Round Robin

The default weight is 1. This means that if multiple apps are mapped to the same route and their weights are not updated, traffic is equally distributed between them. This is the case when you initially map routes to apps (you can bind using the API rather than CF, instructions [here](https://docs.pivotal.io/pivotalcf/2-5/devguide/weighted-routing.html))


Lets first look at the routes
```
# cf create-route SPACE DOMAIN [--hostname HOSTNAME] [--path PATH]
cf create-route demo mesh.apps.gcp.pcf.space -n demo
Creating route demo.mesh.apps.gcp.pcf.space for org rob / space demo as admin...
Route demo.mesh.apps.gcp.pcf.space has been created.
OK
```

Now the route you want to use for you app is configured (in the my case [demo.mesh.apps.gcp.pcf.space](https://demo.mesh.apps.gcp.pcf.space) we now add the instances we want to the route (at the moment if you browse nothing will appear);

```
cf map-route app-blue mesh.apps.gcp.pcf.space -n demo
Creating route demo.mesh.apps.gcp.pcf.space for org rob / space demo as admin...
OK
Adding route demo.mesh.apps.gcp.pcf.space to app app-blue in org rob / space demo as admin...
OK

cf map-route app-green mesh.apps.gcp.pcf.space -n demo
Creating route demo.mesh.apps.gcp.pcf.space for org rob / space demo as admin...
OK
Route demo.mesh.apps.gcp.pcf.space already exists
Adding route demo.mesh.apps.gcp.pcf.space to app app-green in org rob / space demo as admin...
OK
```

Browse to your route and traffic should be balanced between both running instances.

```
curl http://demo.mesh.apps.gcp.pcf.space/
<body style='background-color:blue'>

curl http://demo.mesh.apps.gcp.pcf.space/
<body style='background-color:green'>
```

### Weighted A/B Testing
Traffic routing can be used for A/B testing, the testing of new features by sending a subset of customer traffic to instances with the new feature and observing telemetry and user feedback. Although commonly used for user interfaces, A/B testing can also be employed for microservices. 

Use-cases for microservice A/B testing might include trying out new features for a subset of users or geographical regions, or testing an update on a reduced scale before complete roll-out - if a significant amount of errors are detected on the new version then the rollout can be reverted and all traffic sent to the incumbent service. Testing new features via A/B testing is potentially impactful; it would be safer to perform canary releases.

Istio can be configured to direct traffic based on a percentage weight, cookie value, query parameter and HTTP headers, to name a few, however at the moment the service mesh features in PAS only allow for percentage weight.

The way weight works in PAS is weight of `app-b / ( weight of app-a + weight of app-b )`, this means that settings of `1` & `3` would give a 25%/75% split. At the moment while the feature is in beta a CLI extension does not yet exist so to alter the weights you need to use the various API's. TO make life easier a couple of scripts have been created, the details of what is happening can be viewed in the scripts themselves.

```
# change_weight.sh <host> <app name> <weight>
./change_weight.sh demo app-green 3
```

You should now have 75% of traffic being directed at the `app-green` instances.

### Canary Deploy 
Canary releases could be considered a special case of A/B testing, in which the rollout happens much more gradually. The analogy being alluded to by the name is the canary in the coal mine. A canary release begins with a “dark” deployment of the new service version, which receives no traffic. If the service is observed to start healthily it is directed a small percentage of traffic (e.g. 1%). Errors are continually monitored as continued health is rewarded with increased traffic, until the new service is receiving 100% of the traffic and the old instances can be shut down. Obviously, the ability to safely perform canary releases rests upon reliable and accurate application health checks.

```
# show_weight.sh <host>
./canary_weight.sh demo
Route: demo.mesh.apps.gcp.pcf.space
App: app-blue 	 Weight: 1
App: app-green 	 Weight: 3
```
The vast majority of traffic should now go to `app-blue` and a small amount to `app-green`.

NOTE: I have noticed a slight delay in the updates occuring.


### Show weights
At the moment with the lack of CLI commands you need to chain a couple of API calls together (well its the way I workout out how to get the info), use the script `./show-weight.sh` to display.

### Tidy Up
```
cf unmap-route app-blue mesh.apps.gcp.pcf.space -n demo
cf unmap-route app-green mesh.apps.gcp.pcf.space -n demo
```

```
cf delete-route mesh.apps.gcp.pcf.space -n demo

Really delete the route app.mesh.apps.gcp.pcf.space?> y
Deleting route app.mesh.apps.gcp.pcf.space...
OK
```