# UAA Secure Assertion Markup Language (SAML) Federation overview
SAML federation is a complex protocol to understand and implement. The description in this readme will guide you through the process of configuring UAA and your application using a set of helpful scripts.

First, determine what SAML federation is required (if any) and how it can be configured.
* You do not need to configure UAA for SAML federation if you administer users accounts locally in UAA using UAA SCIM APIs or UAA dashboard.
* If you provision your user accounts remotely on an external IdP such as Company SSO, you can configure UAA as SP that redirects to external IdP. For more information, see section 'Configuring UAA as Service Provider (SP)'.
* If you have applications that provide SP capability (For example, GitHub Enterprise or ServiceNow), you can configure UAA as IdP. For more information, see section 'Configuring UAA as Identity Provider (IdP)'.
* It is possible to configure UAA as both SP and IdP. However such a configuration is useful only as a test environment. To set up UAA as SP and IdP, you can complete steps for configuring UAA as both SP and IdP.      

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
##### 7. Check if your SP configuration was succesfully added:
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
##### 5. Validate the SAML Identity Provider metadata is properly formatted by running through an XML parser. Ensure that it contains a valid XML header such as:
```code
<?xml version="1.0" encoding="UTF-8"?>
```
##### 2. Add your IdP configuration to UAA SP:
```code
uaac target <UAA_SP_INSTANCE_URL>
uaac token client get admin
Client secret: <admin client secret>
./create-saml-idp.sh -n <your-idp-name> -m idp-metadata.xml -a -c <mapping-config-file> -g <groups-config-file> -h <config_email_domain_file>
```
your-idp-name is a user friendly name for your identity provider.  It could be any arbitrary string without special characters

`a` option specifies that a shadow user should be created in UAA. By default, a shadow user is not created.

`c` is an optional parameter that specifies configuration mapping file. A configuration mapping file contains attribute mappings required to convert SAML assertion attributes to JWT token.

Example of an attribute mapping configuration file is as follows:
```code
{
 "email":"mail",
 "given_name":"first name",
 "family_name":"last name"
 }
```

`g` is an optional parameter that specifies groups configuration file. A groups configuration file contains any groups that need to be mapped from external IdP.

Example of a groups configuration file is as follows:
```code
[
"group1",
"group2",
"group3",
"group4",
"group5"
]
```
`h` is an optional parameter that specifies email domains that the IdP can authenticate, this is used for the saml idp discovery profile.
 Example of a email domains configuration file is as follows:
 ```code
 [
 "ge.com",
 "example.org",
 "subexample.example.com",
 "digital.gov"
 ]
```
##### 3. Check that the IdP configuration was succesfully added 
```code
uaac curl /identity-providers
```
Output of this command should show default UAA zone configuration as well as any IdP configured in prior steps.

##### 4. (Optional) If you need to update the existing IdP configuration
If you didn't set up identity provider up front and you need to change some IdP configuration after it was initially provisioned, you can use the following update script:

```code
uaac target <UAA_SP_INSTANCE_URL>
uaac token client get admin
Client secret: <admin client secret>
./update-saml-idp.sh -n <your-idp-name> -m idp-metadata.xml -d <idp-id> -a -c <mapping-config-file> -g <groups-config-file> -h <config_email_domain_file>
```
your-idp-name is a name of identoty provider that you set up during create step and corresponds to "name" attribute for /identity-providers payload
idp-id is auto generated id from UAA and corresponds to "id" attribute for /identity-providers payload
For a meanings of `a`, `c`, `g` and `h` options please see above in create-saml-idp.sh script section.

##### 5. Provision a client for your IdP(s). Client should be configured with IdP(s) as the allowed provider.
```code
./create-client-for-idp.sh -c <client-id> -s <client-secret> -p <idp_array_file> -r <redirect_uri>
```
Example of a IdP array file is as follows: where "gesso" could be the `<your-idp-name>` above in Add your IdP configuration.
```code
[
"gesso",
"example-sso",
"saml-gov-sso",
]
```
##### 6. Validate that client created and allowed providers attribute is set to your IdP list.
```code
uaac client get <client-id>
```
##### 7. (Optional) If you need to update the existing client for your IdP(s).
```code
./update-client-for-idp.sh -c <client-id> -s <client-secret> -p <idp_array_file> -r <redirect_uri>
```
For meaning of IdP array file, please see the above Provision a client for your IdP.
##### 8. To test the setup, navigate to the following URL:
```code
<UAA_SP_INSTANCE_URL>/oauth/authorize?client_id=<client-id>&response_type=code&redirect_uri=<redirect_uri>
```
client-id - name iof the client provisioned in the step 5 above 
redirect_uri - URL encoded application URL, i.e., https%3A%2F%2Fsecurity-predix-seed.grc-apps.svc.ice.ge.com
This request should be redirected to your IdP login page.  Enter credentials for user provisioned for your IdP.  If successful, should redirect back to redirect_uri.
For validation SAML flow, it is recommended to use browser plugin tools like 'SAML tracer' for Firefox.







