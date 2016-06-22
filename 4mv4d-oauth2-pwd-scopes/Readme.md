# OAuthv2.0 Token Dispensing and Verification

This is an example proxy that illustrates how to use Apigee Edge to dispense tokens
for the password grant_type, and then verify the validity and the scopes of those tokens.

This proxy runs in Apigee Edge and relies on a mock database of users that is implemented
within a Javascript hash. It exposes 2 proxy endpoints: one for dispensing tokens, and one for validating or verifying tokens. 


The tokens dispensed here are opaque OAuth 2.0 tokens. They are not JWT. 

## Preparing and Provisioning

1. Import the proxy into any Apigee Edge organization

2. Create an API product. The API product normally wraps API proxies with metadata.
For the purposes of this example, your API product need not contain any API proxies.

3. Create a Developer within Apigee Edge

4. Create a Developer App within Apigee Edge, associated to the new Developer, and with
   authorization to use the API product.

5. View and copy the client_id and client_secret


The previous 5 steps can be automated with the [provision-4mv4d-oauth-pwd-demo.sh](provision-4mv4d-oauth-pwd-demo.sh) script . 


## Using the proxy

1. invoke the API proxy to retrieve a token via password grant_type as:
   ```
   curl -i -X POST \
     -H 'content-type: application/x-www-form-urlencoded' \
     -u CLIENT_ID_HERE:CLIENT_SECRET_HERE \
     'https://vhost-ip:vhost-port/4mv4d/oauth2-pwd/token' \
     -d 'grant_type=password&username=Bugs&password=Bunny'
   ```
   or, alternatively, compute the HTTP Basic Authorization header yourself, and invoke like this: 
   ```
   curl -i -X POST \
     -H 'content-type: application/x-www-form-urlencoded' \
     -H 'Authorization: Basic BASE64_BLOB_HERE' \
     'https://vhost-ip:vhost-port/4mv4d/oauth2-pwd/token' \
     -d 'grant_type=password&username=Bugs&password=Bunny'
   ```  
   In the above, you need to correctly format the
   BASE64_BLOB_HERE to contain `Base64(client_id, client_secret)'` .
   
   In either case, the username and password are validated against a static list of
   users, implemented in a JS callout. In a real system, this will be replaced by a
   callout to a remote system (LDAP or other) to validate the credentials.
   
   
   The response you see will look something like this:
   ```json
   {
     "refresh_token_issued": "2016-Mar-30T15:51:20.950",
     "issued": "2016-Mar-30T15:51:20.950",
     "application_name": "rbeckerapp1",
     "refresh_token_expires_in": 28799,
     "access_token": "voc70CKikpKVFOmxTs1iuapbAvdi",
     "client_id": "p1Lr9kXLERZOIAkE9QGIiwE0qAeluQL9",
     "refresh_token": "NNZUG00fbNHGEooUs10OA1tDPXs2wStY",
     "authenticated_user": "greg",
     "expires_in": 1799,
     "api_product_list": "[NprProduct2]",
     "scopes": ["scope-01","scope-02"],
     "user-groups": "A,B",
     "refresh_token_issued_at": 1459353080950,
     "grant_type": "password",
     "issued_at": 1459353080950
   }
   ```
   
   The available username and password that you pass can be one of these pairs:
   * Sydney, Crosby
   * Kris, Letang
   * Evgeny, Malkin
   
   When you login as different users, you will see different groups returned in the user-groups property of the response payload, and also different scopes. 

You can then demonstrate token verification like so:
   ```
   curl -i -X GET \
     -H 'Authorization: Bearer ACCESS_TOKEN_HERE' \
     'https://vhost-ip:vhost-port/4mv4d/oauth2-pwd-resources/t1' 
   ```  

...or replace t1 with one of {t2, t3, t4, t99}. 
Different tokens (from different users) will produce different results.

## Using the proxy with Postman

If you run the [provision-4mv4d-oauth-pwd-demo.sh](provision-4mv4d-oauth-pwd-demo.sh) script, it will generate a postman collection that ought to work with your organization. 


## Additional Commentary

This API proxy dispenses opaque oauth tokens. The attributes associated to the dispensed tokens are stored in the key-management database within Apigee Edge. The API publisher has the ability to curate or adjust the response to requests for tokens. You could, for example, deliver a JSON payload with only the token and the expiry. The current example provides lots of additional information in the response.

These tokens are not JWT. JWT describes a standard way to format self-describing tokens.
Apigee Edge can generate and return JWT, that function in much the same way as the opaque oauth tokens shown here. This is not implemented in this example API Proxy. 

These tokens are not delivered via an OpenID Connect flow. OpenID connect describes an authentication flow on top of the OAuth 2.0 authorization framework. Apigee Edge can render JWT as a result of an OpenID Connect flow. This is not implemented in this example API Proxy.





