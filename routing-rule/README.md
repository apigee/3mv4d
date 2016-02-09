## How to setup routing rule in your proxy.

Routing rules are important when you want need to determine what target servers to use at runtime. Setting this up on Apigee is really simple. 

There's a [4-minute video](https://www.youtube.com/watch?v=elnCVKVM9yU) that demonstrates this in action.

## Changes needed
1. Make sure you get a key from [openweather](http://openweathermap.org/appid#get).
2. Add the newly obtained key to the policy "AssignOpenweatherRequestParam". 
```
<AssignMessage async="false" continueOnError="false" enabled="true" name="AssignOpenweatherRequestParam">
    <DisplayName>AssignOpenweatherRequestParam</DisplayName>
    <Properties/>
    <Set>
        <QueryParams>
            <QueryParam name="id">{w}</QueryParam>
            <QueryParam name="appid">YOUR_KEY_GOES_HERE</QueryParam>
        </QueryParams>
        <Path/>
    </Set>
    <AssignVariable>
        <Name>target.copy.pathsuffix</Name>
        <Value>false</Value>
    </AssignVariable>
    <IgnoreUnresolvedVariables>true</IgnoreUnresolvedVariables>
    <AssignTo createNew="false" transport="http" type="request"/>
</AssignMessage>
``` 


## Deploying the proxy

You have several options. Choose one: 

1. manually zip and then upload via the Edge administrative UI.   
  a. zip up the apiproxy directory with  
  ``` 
  zip -r 4mv4d-routing-rule.zip  apiproxy -x "*/Icon*"
  ```
  b. upload via the Edge Admin UI, with the "+ API Proxy" button. 

2. upload using an automated script, like [pushapi](https://github.com/carloseberhardt/apiploy/)  
  ``` 
  ./pushapi -v -d -o ORGNAME -e ENVNAME -c 4mv4d-routing-rule/ 
  ``` 

3. Turn [trace tool](http://docs.apigee.com/api-services/content/using-trace-tool-0) on

## Make the API call with the proxy.
```
curl -i -X GET \ 
	"http://ORGNAME-ENVNAME.apigee.net/v1/data/weather?w=2442047" \
	-H "X-WEATHER-SOURCE: yahoo"
```
```
curl -i -X GET \ 
	"http://ORGNAME-ENVNAME.apigee.net/v1/data/weather?w=2442047" \
	-H "X-WEATHER-SOURCE: openweather"
```


