# UAA Secure Assertion Markup Language (SAML) Federation overview
SAML federation is not simple protocol to understand or implement. Hopefully below description will help you understand what needs to configured for your application and how to achieve it using set of helpful scripts.

First, lets try to understand what SAML federation needed if any and how it needs to be configured. Here few pointers that may help you.
* If your users accounts adminitered locally in UAA using UAA SCIM api's or UAA dashboard, no SAML federation needed. Just scip below section.
* If user accounts provisioned remotely on external Identity Provider (IdP) like GE SSO for example UAA become Service Provider in SAML that redirects to external Identity Provider (IdP). In this case please follw section 'Configuring UAA as Service Provider (SP)'.
* If you have application that capable to participate in SAML flow as SAML Service Provider (SP) like GitHub Enterprise or ServiceNow please follow section 'Configuring UAA as Identity Provider (IdP)'.
* For testing porposes it is possible to configure UAA as both Service Provider (SP) and Identity Provider (IdP). In this rare case you need to follow both sections.      

# Configuring UAA as Identity Provider (IdP) 

##### 1.  Checkout scripts to manage UAA IdP:
```code
git checkout https://github.com/PredixDev/uaa-scripts.git
cd uaa-scripts/mgmt
```
##### 2. Export UAA IdP metadata into a file, i.e., uaa-idp-metadata.xml, by navigating to the following URL:
```code
<UAA_IDP_INSTANCE_URL>/saml/idp/metadata
```
##### 3. Import UAA IdP configuration into your Service Provider (SP).
Every Service Provider may have different instructions how to import SAML metadata. As result we cannot provide direct instructions here.
##### 4. Obtain your SP SAML metadata from your SP administrator.
Follow up instructions assume that after configuring UAA IdP in your Service Provider, SP SAML metadata is stored into file: sp-metadata.xml

##### 5. Provision a user for UAA IdP:
```code
uaac target <UAA_IDP_INSTANCE_URL>
uaac token client get admin
Client secret: <admin client secret>
uaac user add <user-name> --given_name <first-name> --family_name <last-name> --emails <email> -p <password>
uaac group add zones.uaa.admin
uaac member add zones.uaa.admin myuser
```
##### 6. Add your SP configuration to UAA IdP:
```code
uaac target <UAA_IDP_INSTANCE_URL>
uaac token authcode get
Client name:  identity
Client secret:  <identity client secret>
```
You should be redirected to UAA IdP login page.  Enter credentials for user provisioned in step 5 above and verify that response is "Successfully fetched token via authorization code grant"
```code
./create-saml-sp.sh -n <your-sp-name> -m sp-metadata.xml -s <your-sp-entity-id> -i
```
your-sp-name is a user friendly name for your service provider.  It could be any arbitrary string without special characters
your-sp-entity-id should match service provider entityID in its metadata.
##### 7. Check if your SP configuration was succesfully added
```code
uaac curl /saml/service-providers
```

# Configuring UAA as Service Provider (SP)

##### 1.  Checkout scripts to manage UAA IdP:
```code
git checkout https://github.com/PredixDev/uaa-scripts.git
cd uaa-scripts/mgmt
```
##### 2. Export UAA SP metadata into a flie, i.e., uaa-sp-metadata.xml, by navigating to the following URL:
```code
<UAA_SP_INSTANCE_URL>/saml/metadata/alias/<UAA_SP_INSTANCE_GUID>.cloudfoundry-saml-login
```
##### 3. Import UAA SP metadata into your Identify Provider (IdP).
Every Identity Provider may have different instructions how to import SAML metadata. As result we cannot provide direct instructions here.
##### 4. Obtain your IdP SAML metadata from your IdP administrator.
Follow up instructions assume that after configuring UAA SP in your Identity Provider, IdP SAML metadata is stored into file: idp-metadata.xml
##### 5. Validate the SAML Identity Provider metadata is properly formatted by running through a XML parser. Ensure that it contains a valid XML header such as:
```code
<?xml version="1.0" encoding="UTF-8"?>
```
##### 2. Add your IdP configuration to UAA SP:
```code
uaac target <UAA_SP_INSTANCE_URL>
uaac token client get admin
Client secret: <admin client secret>
./create-saml-idp.sh -n <your-idp-name> -m idp-metadata.xml -a -c <mapping-config-file> -g <groups-config-file>
```
your-idp-name is a user friendly name for your identity provider.  It could be any arbitrary string without special characters

`a` option makes sure that shadow accounts created authomatically after successful login

`c` is optional parameter if any attribute mapping is requred to convert SAML assertion attributes to JWT token.

Example of attribute mapping configuration file would be following:
```code
{
 "email":"mail",
 "given_name":"first name",
 "family_name":"last name"
 }
```

`g` is optional parameter if any groups needs to be mapped from external IdP.
Example of groups array configuration file would be following:
```code
[
"group1",
"group2",
"group3",
"group4",
"group5"
]
```

##### 3. Check that the IdP configuration was succesfully added 
```code
uaac curl /identity-providers
```
Output of this command should show default UAA zone configuration as well as any IdP configured in prior steps.

##### 4. Optional Step if IdP configuration above needs to be updated
If you didn't set up identity provider up front and you need to change some IdP configuration after it was initially provisioned you can use following update script:

```code
uaac target <UAA_SP_INSTANCE_URL>
uaac token client get admin
Client secret: <admin client secret>
./update-saml-idp.sh -n <your-idp-name> -m idp-metadata.xml -d <idp-id> -a -c <mapping-config-file> -g <groups-config-file>
```
your-idp-name is a name of identoty provider that you set up during create step and corresponds to "name" attribute for /identity-providers payload
idp-id is auto generated id from UAA and corresponds to "id" attribute for /identity-providers payload
For a meanings of `a`, `c` and `g options please see above in create-saml-idp.sh script section.

##### 5. Provision a client for your IdP. Client should be configured with IdP as the allowed provider.
```code
./create-client-for-idp.sh -c <client-id> -s <client-secret> -p <your-idp-name> -r <redirect_uri>
```
##### 6. Validate that client created and allowed providers attribute is set to your IdP.
```code
uaac client get <client-id>
```
##### 7. To test the setup, navigate to the following URL:
```code
<UAA_SP_INSTANCE_URL>/oauth/authorize?client_id=<client-id>&response_type=code&redirect_uri=<redirect_uri>
```
client-id - name iof the client provisioned in the step 5 above
redirect_uri - application URL, i.e., https://security-predix-seed.grc-apps.svc.ice.ge.com
Above request should be redirected to your IdP login page.  Enter credentials for user provisioned for your IdP.  If succesfull, should redirect back to redirect_uri.
For validation SAML flow we recommend using browser plugin tools like 'SAML tracer' for Firefox.







