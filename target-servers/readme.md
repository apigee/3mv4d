## How to use Target Servers in your API Proxies

When you deal with API Proxies that have to be deployed in multiple environments target servers can help you with getting the backend URL right. A target server definition is basically a name for a backend URL, and you can set a different URL for each environment. By using target servers you can reference the target server name instead of hard-coding the backend URL directly.

Apigee Edge support defining target servers from the UI, and also through the Management API.

In this [video](https://youtu.be/crnuHAgj9Vo) we show how to create target servers and how to use it in your API Proxy. Also we demonstrate how to do load balancing over target servers.

Creating a target server definition through the Management API looks like this:

> curl -H "Content-Type:text/xml" -X POST -d \
    '<TargetServer name="OMDB">
    <Host>www.omdbapi.com</Host>
    <Port>80</Port>
    <IsEnabled>true</IsEnabled>
    </TargetServer>' \
    -u username@apigee.com
    https://api.enterprise.apigee.com/v1/o/orgname/environments/envname/targetservers 

To reference the target server in the TargetEndpointHTTPConnection you use this XML snippet:

    <LoadBalancer>
        <Server name="OMDB"/>
    </LoadBalancer>
    <Path>/</Path> 

If you would like to use LoadBalancing over multiple target server definitions you simply include an algorithm element and all the target servers:

    <LoadBalancer>
        <Algorithm>RoundRobin</Algorithm>
        <Server name="OMDB1" />
        <Server name="OMDB2" />
        <Server name="OMDB3" />
    </LoadBalancer>
    <Path>/</Path> 

The following algorithms are supported for loadbalancing:
1. RoundRobin
2. Weighted
3. LeastConnection
4. MaxFailures

More information about target servers can be found here:
1. [documentation on the management api](http://docs.apigee.com/management/apis/post/organizations/%7Borg_name%7D/environments/%7Benv_name%7D/targetservers)
2. [load balancing](http://docs.apigee.com/api-services/content/load-balancing-across-backend-servers)