# XML-to-JSON and JSON-to-XML transformations

If you deal with many different APIs, from time to time you will come upon one that is delivering results or accepting input in a form that is not optimal for you, or for the developers you're trying to enable. For example, the API will accept XML or return XML, when you want JSON. Or, it will accept or return JSON, and you want XML. 

Apigee Edge has out-of-the-box policies that let you convert from one format to the other, in outbound requests or on a response. With these policies, you can use Apigee Edge to produce facades that work the way your developers want to work!

This simple API proxy shows you how to apply the XMLToJSON and JSONToXML
policies within Apigee Edge. 

There's a [4-minute video](https://www.youtube.com/watch?v=6z-TtOr7H-k) that demonstrates this in action. 


## Deploying the proxy

You have several options. Choose one: 

1. manually zip and then upload via the Edge administrative UI.   
  a. zip up the apiproxy directory with  
  ``` 
  zip -r 3mv4d-xform.zip  apiproxy -x "*/Icon*"
  ```
  b. upload via the Edge Admin UI, with the "+ API Proxy" button. 

2. upload using an automated script, like [pushapi](https://github.com/carloseberhardt/apiploy/)  
  ``` 
  ./pushapi -v -d -o ORGNAME -e ENVNAME -c 3mv4d-xform/
  ```

## Using this proxy with Postman

If you use the [Postman](https://chrome.google.com/webstore/detail/postman/fhbjgbiflinjbdggehcddcbncdddomop?hl=en) tool, 
there is a handy collection [here](SimpleTransforms.json.postman_collection). 
Within postman, you need to set an environment which specifies these variables:

- orgname
- envname

## Using this proxy with curl

### Example 1: 

Invoke the endpoint to transform any arbitrary XML document to JSON: 

```
curl -i -X POST \
    -H content-type:application/xml \
    http://ORGNAME-ENVNAME.apigee.net/3mv4d-xform/xmltojson \
    -d '
<root>
  <element1>aaaa</element1>
  <e2>bbbb</e2>
</root>' 
```

Note: you must pass the content-type header or the XML-to-JSON policy will not execute! 

Expected result:

```json
{
  "root": {
    "element1": "aaaa",
    "e2": "bbbb"  
  }
}
```



### Example 2: 

Invoke the endpoint to transform any JSON document to XML: 

```
curl -i -X POST \
    -H content-type:application/json \
    http://ORGNAME-ENVNAME.apigee.net/3mv4d-xform/jsontoxml \
-d '{
  "root": {
    "element1": "aaaa",
    "e2": "bbbb"  
  }
}'
```

Note: you must pass the content-type header correctly or the JSONToXML policy will not execute! 


Expected Result:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <element1>aaaa</element1>
  <e2>bbbb</e2>
</root>
```


### Example 3:
Transform a slightly-more-complex XML document to JSON: 

```
curl -i -X POST \
    -H content-type:application/xml \
    http://ORGNAME-ENVNAME.apigee.net/3mv4d-xform/xmltojson \
    -d '
<root>
  <element1>aaaa</element1>
  <e2>bbbb</e2>
  <item>
    <name>ccc</name>
  </item>
  <item>
    <name>ddd</name>
  </item>
</root>' 
```


Expected result:

```json
{
  "root": {
    "element1": "aaaa",
    "item": [
      {
        "name": "ccc"      
      },
      {
        "name": "ddd"      
      }
    ],
    "e2": "bbbb"  
  }
}
```

### Example 4:

Transform a slightly-more-complex JSON document to XML:

```
curl -i -X POST \
    -H content-type:application/json \
    http://ORGNAME-ENVNAME.apigee.net/3mv4d-xform/jsontoxml \
    -d '{
  "root": {
    "element1": "aaaa",
    "e2": "bbbb",
    "item": [
      {
        "name": "ccc"
      },
      {
        "name": "ddd"
      }
    ]
  }
}'
```

Expected result:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <element1>aaaa</element1>
  <e2>bbbb</e2>
  <item>
    <name>ccc</name>
  </item>
  <item>
    <name>ddd</name>
  </item>
</root>
```


### Example 5:

Retrieve XML from a backend.  This call retrieves data from the [Yahoo weather service RSS API](https://developer.yahoo.com/weather/documentation.html), in XML format. No transform to JSON is performed in this example.  *The next example will transform this response)


```
curl -i http://ORGNAME-ENVNAME.apigee.net/3mv4d-xform/forecast1?w=2490383
```

Expected result:

```xml
<response>
   <stamp>Fri, 13 Nov 2015 10:49 am PST</stamp>
   <sunrise>7:09 am</sunrise>
   <sunset>4:34 pm</sunset>
   <title>Conditions for Seattle, WA at 10:49 am PST</title>
   <current text="Cloudy"
            code="26"
            temp="59"
            date="Fri, 13 Nov 2015 10:49 am PST"/>
   <forecast day="Fri"
             date="13 Nov 2015"
             low="47"
             high="57"
             text="Rain"
             code="12"/>
   <forecast day="Sat"
             date="14 Nov 2015"
             low="41"
             high="50"
             text="Rain"
             code="12"/>
   <forecast day="Sun"
             date="15 Nov 2015"
             low="39"
             high="47"
             text="Showers"
             code="11"/>
   <forecast day="Mon"
             date="16 Nov 2015"
             low="46"
             high="47"
             text="Rain"
             code="12"/>
   <forecast day="Tue"
             date="17 Nov 2015"
             low="50"
             high="54"
             text="Rain"
             code="12"/>
</response>
```


### Example 6:

Transform an XML received from a backend, to JSON.  This one retrieves data from the [Yahoo weather service RSS API](https://developer.yahoo.com/weather/documentation.html), and transforms it to JSON. 


```
curl -i http://ORGNAME-ENVNAME.apigee.net/3mv4d-xform/forecast2?w=2490383
```

Expected result:

```json
{
  "response": {
    "title": "Conditions for Seattle, WA at 10:52 pm PST",
    "stamp": "Wed, 11 Nov 2015 10:52 pm PST",
    "forecast": [
      {
        "code": 29,
        "text": "Partly Cloudy",
        "high": 52,
        "low": 42,
        "date": "11 Nov 2015",
        "day": "Wed"      
      },
      {
        "code": 39,
        "text": "PM Showers",
        "high": 50,
        "low": 49,
        "date": "12 Nov 2015",
        "day": "Thu"      
      },
      {
        "code": 12,
        "text": "Rain",
        "high": 56,
        "low": 48,
        "date": "13 Nov 2015",
        "day": "Fri"      
      },
      {
        "code": 12,
        "text": "Rain",
        "high": 50,
        "low": 41,
        "date": "14 Nov 2015",
        "day": "Sat"      
      },
      {
        "code": 11,
        "text": "Showers",
        "high": 47,
        "low": 40,
        "date": "15 Nov 2015",
        "day": "Sun"      
      }
    ],
    "current": {
      "date": "Wed, 11 Nov 2015 10:52 pm PST",
      "text": "Partly Cloudy",
      "code": 29,
      "temp": 46    
    },
    "sunset": "4:37 pm",
    "sunrise": "7:07 am"  
  }
}
```

