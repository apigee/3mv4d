# Management API - Download Proxy

Using the Edge management API to download a proxy revision is an easy way to migrate proxies between different organizations. Downloading proxies is also used during API lifecycle management processes. This is a very straightforward process and is easy to integrate into your SDLC.

In the [video](https://youtu.be/gMdyL3wiMkY) we show how to download a proxy using the UI and the management API. We also provide a simple script to download all the proxies in an organization.

Documentation on the Edge Management API is available [online](http://apigee.com/docs/management/apis) including the specific documentation for [exporting an API proxy revision](http://apigee.com/docs/management/apis/get/organizations/%7Borg_name%7D/apis/%7Bapi_name%7D/revisions/%7Brevision_number%7D).

The example script to export all proxies in an org is as follows:
```
host=https://api.enterprise.apigee.com;org=ORGNAME; \
for proxy in `curl $host/v1/o/$org/apis | jq '.[]' | \
sed -e 's/"//g'`; do echo "downloading to $proxy.zip..."; \
curl $host/v1/o/cdmo/apis/$proxy/revisions/`curl \
$host/v1/organizations/$org/apis/$proxy | jq '.revision \
| max | tonumber'`?format=bundle -o $proxy.zip; done
```  

While at first blush this is complex, stepping through the construction of it should clarify things.
** There may well be cleaner scripts to do this same thing. If you have a nicer solution, please share! **
1. First, list all the proxies defined in our org:
```
ApigeeCorporation in ~
☯ host=https://api.enterprise.apigee.com;org=cdmo; \
→ curl $host/v1/o/$org/apis
[
  "rot13",
  "bucketlist",
  "identity-demo-app",
  "weather-sample",
  "tester",
  "identity-consentmgmt-api",
  "second-problem",
  "idwapi",
  "konakart",
  "jsonpath",
  "identity-usermgmt-api",
  <snip>
```

1. The result is just a json array, so in order to loop through that in bash we need the items in a clean list. For that we turn to [jq](https://stedolan.github.io/jq/). (I'm never above jumping outside core tools if it makes life easier.)
```
  ApigeeCorporation in ~
☯ host=https://api.enterprise.apigee.com;org=cdmo; \
→ curl $host/v1/o/$org/apis | jq '.[]'
"rot13"
"bucketlist"
"identity-demo-app"
"weather-sample"
"tester"
"identity-consentmgmt-api"
"second-problem"
"idwapi"
"konakart"
"jsonpath"
"identity-usermgmt-api"
```

1. Closer, but we still have quotes we don't need. Sed can take care of that...
```
ApigeeCorporation in ~
☯ host=https://api.enterprise.apigee.com;org=cdmo; \
→ curl $host/v1/o/$org/apis | jq '.[]' | sed -e 's/"//g'
rot13
bucketlist
identity-demo-app
weather-sample
tester
identity-consentmgmt-api
second-problem
idwapi
konakart
jsonpath
identity-usermgmt-api
```
Now we have something we can loop through in bash and create a curl call to download the proxy.

1. But if we want to grab the latest revision of each proxy we'll also need to retrieve that for each one. Given a specific proxy, here's how we can find the revisions:
```
ApigeeCorporation in ~
☯ host=https://api.enterprise.apigee.com;org=cdmo; \
→ curl $host/v1/o/$org/apis/presos
{
  "metaData": {
    "createdAt": 1391191116356,
    "lastModifiedAt": 1391461096594
  },
  "name": "presos",
  "revision": [
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9"
  ]
}
```

1. Turning to jq again we can get the max revision for a specific proxy:
```
ApigeeCorporation in ~
☯ host=https://api.enterprise.apigee.com;org=cdmo; \
→ curl $host/v1/o/$org/apis/presos | jq '.revision | max | tonumber'
9
```
1. Now we have a list of proxies we can loop through easily, and a one-liner to get the revision number for each proxy. Putting it all together gives us our final script:
```
host=https://api.enterprise.apigee.com;org=ORGNAME; \
for proxy in `curl $host/v1/o/$org/apis | jq '.[]' | \
sed -e 's/"//g'`; do echo "downloading to $proxy.zip..."; \
curl $host/v1/o/cdmo/apis/$proxy/revisions/`curl \
$host/v1/organizations/$org/apis/$proxy | jq '.revision \
| max | tonumber'`?format=bundle -o $proxy.zip; done
```  
