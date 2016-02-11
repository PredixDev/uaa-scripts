How to configure SAML federation between UAA Service Provider (UAA SP) and UAA Identity Provider (UAA IdP)

##### 1. Build and push UAA IdP app to the cloud foundry.
```code
Repository: https://github.com/GESoftware-CF/uaa
Branch: saml_idp
```
##### 2. Set the environment value for SPRING_PROFILES_ACTIVE
```code
cf set-env <IDP_APP_NAME> SPRING_PROFILES_ACTIVE saml,cloud
```
##### 3. Restage the app after setting the env.
```code
cf restage <IDP_APP_NAME>
```
##### 4. Export UAA IdP metadata into a file, i.e., uaa-idp-metadata.xml, by navigating to the following URL:
```code
<UAA_IDP_INSTANCE_URL>/saml/idp/metadata
```
##### 5.  Checkout scripts to manage UAA SP and IdP:
```code
git checkout https://github.com/PredixDev/uaa-scripts.git
cd uaa-scripts/mgmt
```
##### 6. Add UAA IdP configuration to UAA SP:
```code
uaac target <UAA_SP_INSTANCE_URL>
uaac token client get admin
Client secret: <admin client secret>
./create-saml-idp.sh -n <uaa-idp-name> -m uaa-idp-metadata.xml -a
```
##### 7. Check that UAA IdP configuration was succesfully added 
```code
uaac curl /identity-providers
```
##### 8. Provision a client for UAA IdP.  Client should be configured with UAA IdP as the allowed provider.
```code
./create-client-for-idp.sh -c <client-id> -s <client-secret> -p <uaa-idp-name> -r <redirect_uri>
```
##### 9. Validate that client is present and allowed providers attribute is set to UAA IdP.
```code
uaac client get <client-id>
```
##### 10. Export UAA SP metadata into a flie, i.e., uaa-sp-metadata.xml, by navigating to the following URL:
```code
<UAA_SP_INSTANCE_URL>/saml/metadata/alias/<UAA_SP_INSTANCE_GUID>.cloudfoundry-saml-login
```
##### 11. Provision a user for UAA IdP:
```code
uaac target <UAA_IDP_INSTANCE_URL>
uaac token client get admin
Client secret: <admin client secret>
uaac user add <user-name> --given_name <first-name> --family_name <last-name> --emails <email> -p <password>
uaac group add zones.uaa.admin
uaac member add zones.uaa.admin myuser
```
##### 12. Add UAA SP configuration to UAA IdP:
```code
uaac target <UAA_IDP_INSTANCE_URL>
uaac token authcode get
Client name:  identity
Client secret:  <identity client secret>
(Should be redirected to UAA IdP login page.  Enter credentials for user provisioned in step 11 above.)
Successfully fetched token via authorization code grant

./create-saml-sp.sh -n <uaa-sp-name> -m uaa-sp-metadata.xml -i
```
##### 13. Check that UAA SP configuration was succesfully added
```code
uaac curl /saml/service-providers
```
##### 14. To test the setup, navigate to the following URL:
```code
<UAA_SP_INSTANCE_URL>/oauth/authorize?client_id=<client-id>&response_type=code&redirect_uri=<redirect_uri>
```
client-id - name iof the client provisioned in the step 8 above
redirect_uri - application URL, i.e., https://security-predix-seed.grc-apps.svc.ice.ge.com

Should be redirected to UAA IdP login page.  Enter credentials for user provisioned in step 11 above.  If succesfull, should redirect to redirect_uri







