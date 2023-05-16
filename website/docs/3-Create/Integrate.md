---
id: solution-integrate
sidebar_position: 3
title: Integrate
---
# Enabling S3 Bucket access

## Task Overview

Per the IBM Documentation, the following steps would need to be performed in order to allow for S3 bucket access:

Installing AWS SDK for Java on B2BI Certified Container/Docker deployment:

1. On B2BI Dashboard, select Customization > Customization. Click the Click Here To Access link. In the Customization login screen, enter the User Name and Password and click Login. (apiadmin/apipassword)
2. Click Custom Jar. The Custom Jar list page is displayed.
Click Create CustomJar.
3. Set the 'Vendor Name' as "awssdk". 'Vendor Version' as the version from "aws-java-sdk-[version]" you downloaded earlier.
4. Set the 'File Type' as "LIBRARY". Set 'Target Path' as "Every".
5. Upload the files mentioned below (Create multiple custom jars using same parameters as mentioned in ibm-client-engineering/spog-fsm-st5#4 and ibm-client-engineering/spog-fsm-st5#5 above along with each file mentioned below):
    1. aws-java-sdk-[version].jar (Found in aws-java-sdk-[version]/lib)
    2. httpclient-[version].jar
    3. httpcore-[version].jar
    4. jackson-annotations-[version].jar
    5. jackson-core-[version].jar
    6. jackson-databind-[version].jar
    7. joda-time-[version].jar
    8. netty-*.jar (Found in aws-java-sdk-[version]/third-party/lib)

Restart the ASI/AC/API pods.

## Task Breakdown

### Creating an `apiadmin` user

Login to our dashboard URL:

https://k8s-ingressn-ingressn-f9d3dcbc72-69d548b3e1e33f06.elb.us-east-1.amazonaws.com/dashboard/

1. Select Accounts->User Accounts

![apiadmin_create_01|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/53dbc727-b0fa-4a6b-b514-61421a88eae1)

2. Set the username to `apiadmin` with a password of `apipassword`

![apiadmin_create_02|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/281121e5-0358-4a47-9a6a-2de6e4f65e8c)

3. Skip SSH Authorized Keys as we do not require this for this account

![apiadmin_create_03|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/09287bb6-2f43-462f-92ce-8dccce62b39f)


4. Under `Filter Data` search for `Sterling`, then Select `Sterling B2B Integrator Admin` and assign it. Then press `Next`

| | |
|:---|:---|
|![apiadmin_create_04a\|150](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/1e52ec87-11e4-48ae-88fb-af7a1fbc1b15)|![apiadmin_create_04b\|150](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/73b5ac62-2778-4975-9ab8-ce182a51f690)|

5. Permissions - Under `Filter Data` search for `APIUser`. Select `APIUser` and add it to the permissions below with the arrow. Then hit `Next`.

| | |
|:---|:---|
|![apiadmin_create_05a\|150](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/9279d0e8-d713-476d-9c68-7a87f7cc7fe0)|![apiadmin_create_05b\|150](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/b21115d7-a14e-4448-b655-9d0381b89a87)|

6. User Information - Set the `Given Name` and `Surname` to `api` and `apiadmin` respectfully. Then click `Next`.

![apiadmin_create_06|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/fabef444-8f8c-4740-a98a-8440ce848704)

7. Confirm - Verify all info is correct and then click `Finish`

![apiadmin_create_07|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/57cca0b8-605f-4704-b235-70d43a6a5c06)


## Uploading Required Jar files for S3 access

### Downloading latest AWS SDK zip file

Latest SDK can be retrieved here:

https://sdk-for-java.amazonwebservices.com/latest/aws-java-sdk.zip

Download the zip and extract it. The files needed will live at the following paths:

```
aws-java-sdk-1.12.464/lib/aws-java-sdk-1.12.464.jar
aws-java-sdk-1.12.464/third-party/lib/httpclient-4.5.13.jar
aws-java-sdk-1.12.464/third-party/lib/httpcore-4.4.13.jar
aws-java-sdk-1.12.464/third-party/lib/jackson-annotations-2.12.7.jar
aws-java-sdk-1.12.464/third-party/lib/jackson-core-2.12.7.jar
aws-java-sdk-1.12.464/third-party/lib/jackson-databind-2.12.7.1.jar
aws-java-sdk-1.12.464/third-party/lib/joda-time-2.8.1.jar
aws-java-sdk-1.12.464/third-party/lib/netty-buffer-4.1.86.Final.jar
aws-java-sdk-1.12.464/third-party/lib/netty-codec-4.1.86.Final.jar
aws-java-sdk-1.12.464/third-party/lib/netty-codec-http-4.1.86.Final.jar
aws-java-sdk-1.12.464/third-party/lib/netty-common-4.1.86.Final.jar
aws-java-sdk-1.12.464/third-party/lib/netty-handler-4.1.86.Final.jar
aws-java-sdk-1.12.464/third-party/lib/netty-resolver-4.1.86.Final.jar
aws-java-sdk-1.12.464/third-party/lib/netty-transport-4.1.86.Final.jar
aws-java-sdk-1.12.464/third-party/lib/netty-transport-native-unix-common-4.1.86.Final.jar
```

Versions may be differnt as the `aws-java-sdk.zip` is always being updated.

### PropertyUI url

Retrieve the propertyUI url. It can be retrieved with the following command:

```
echo "https://"$(kubectl get ingress sterling-b2bi-b2bi-ingress -o jsonpath='{..hostname}')"/propertyUI/app/"

https://myingress.elb.us-east-1.amazonaws.com/propertyUI/app/
```

Login using the `apiadmin` user we created with the password `apipassword`

### Upload each jar file

Select `CustomJar` from the top menubar

![customjars_01|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/6d410788-68d4-4a1d-a66d-d719b0cf24e8)

Click `Create CustomJar` from the top of the page

![customjars_02|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/cca5de3f-9d01-4bdb-9874-f379f119de27)

In this example we are uploading the latest `aws-java-sdk` jar file. Click the browse button and select the aws-java-sdk jar file from the path extracted above.

![customjars_03|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/78111b83-f7c0-4027-ae76-5a086a8f8719)

When complete, click the `Save CustomJar` button.

Wash, rinse, repeat with the other jar files in the above list. 

When complete, the page should look _similar_ but not exactly like this:

![customjars_04|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/394fa3dd-5ea4-4360-b619-d099009d5c85)

Restart all the pods.

```
kubectl scale sts sterling-b2bi-b2bi-ac-server --replicas=0
kubectl scale sts sterling-b2bi-b2bi-asi-server --replicas=0
kubectl scale sts sterling-b2bi-b2bi-api-server --replicas=0
kubectl scale sts sterling-b2bi-b2bi-ac-server --replicas=1
kubectl scale sts sterling-b2bi-b2bi-asi-server --replicas=1
kubectl scale sts sterling-b2bi-b2bi-api-server --replicas=1
```

:::warning

You may need to update the startup probe failure threshold for the ASI application in your b2bi overrides file to 12 before restarting the pods after creating the above custom jars.

```
  startupProbe:
    initialDelaySeconds: 120
    timeoutSeconds: 30
    periodSeconds: 60
    failureThreshold: 12

```

Whenever the pods are restarted, they will go through a copy process to install these custom jars and that adds to the load time. Without this change, the startup probe may wind up killing the ASI pod before this process is complete.
:::

# B2Bi Adapter creation and configuration

## Configuring communication adapters:

The following adapters can be used with Sterling File Gateway:

| Protocol | Adapter | 
|:----------|:---------|
| FTP, FTPS | FTP Server adapter |
| FTP, FTPS |	FTP Client adapter and services |
| SSH/SFTP, SSH/SCP |	SFTP Server adapter |
| SSH/SFTP |	SFTP Client adapter and services |
| Sterling Connect:Direct |	Connect:Direct Server adapter |
| PGP |	Command Line Adapter 2 |
| HTTP, HTTPS, WebDAV (Requires extensibility. See Add Custom Protocols.) |	HTTP Server adapter |
| HTTP, HTTPS, WebDAV (Requires extensibility. See Add Custom Protocols.) |	HTTP Client adapter and services |
| WebSphere® MQ File Transfer Edition | WebSphere MQ File Transfer Edition Agent adapter, WebSphere MQ Suite Async adapter, WebSphere MQ File Transfer Edition Create Transfer service, FTP Server Adapter |


Primary URL can be found with the following command:
```
kubectl get ingress sterling-b2bi-b2bi-ingress -o jsonpath="{..hostname}"

k8s-ingressn-ingressn-f9d3dcbc72-69d548b3e1e33f06.elb.us-east-1.amazonaws.com
```
Login to the dashboard as `fg_sysadmin`:

https://k8s-ingressn-ingressn-f9d3dcbc72-69d548b3e1e33f06.elb.us-east-1.amazonaws.com/dashboard

From the main menu: 
1. Select Deployment > Services > Configuration.
2. Select and configure the adapters you require.

As an example, let's configure SFTP. Per the above table, SFTP is `SFTP Client adapter`

Log out of dashboard and log back into the `filegateway` as `fg_architect`:

https://k8s-ingressn-ingressn-f9d3dcbc72-69d548b3e1e33f06.elb.us-east-1.amazonaws.com/filegateway

From the main menu, select **Participants > Communities** to create a community with the following values:

| Field | Value |
|-------|-------|
|Community Name |	FirstComm |
|Partner Initiates Protocol Connection|	X |
|Partner Listens for Protocol Connections |X |
|SSH/SFTP | X |
|Should Receive Notification|	Yes |

Select **Participants > Groups** to create a group named `Group1`.

Log out of `filegateway` and log back in as `fg_provisioner`

Create two partners with the following values:

Select **Participants > Partners** 

|Field| Value For First Partner| Value For Second Partner|
|-----|------|-----|
|Community|FirstComm|FirstComm|
|Partner Name|Partner1|Partner2|
|Phone|333|444|
|Email|y@x.com|x@y.com|
|User Name|partner1|partner2|
|Password|p@ssw0rd|p@ssw@rd|
|Given Name|partner|partner|
|Surname|1|2|
|Partner Role| Is a consumer of data - Initiates a connection|Is a producer of data|
|Use SSH|Yes|Yes|
|Use Authorized User Key|No|No|
|PGP Settings|- No - No|- No - No|

Associate the partners with Group1. Select Participants > Groups > Add Partner. Select the partners and the group, and click Execute

Log out and log back into the `filegateway` as `fg_architect`

Select Routes > Templates > Create to create a routing channel template with the following values:


| | |
|:---|:---|
|![Template_Type.png\|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/260bc4f3-f735-48bf-8f93-af875861e416)|![Template_Special_Characters.png\|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/f513633a-f09d-4e37-a59a-9688e128a84f)|
|![Template_Groups.png\|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/0b40b765-bf0b-4ce7-851f-4014416bbe0d)|![Template_Provisioning_Facts.png\|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/18c24d5d-ea91-4ac4-ba97-061bbd8f13e9)|
|![Template_Producer_File_Structure.png\|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/66378f70-9226-4789-80fb-73ec8de62c5f)|![Template_Consumer_File_Structure_add.png\|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/49d355aa-03a2-456a-9cde-260602bc8c77)|
|![Template_Consumer_File_Structure_format.png\|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/5acfa848-027d-4ec7-95a3-c01cd38cf2bf)|![Template_Consumer_File_Structure_Save.png\|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/e41e146b-8f13-4266-a692-01ac0768d467)|


Save the template

Log out and log back into `filegateway` as `fg_provisioner`

Create a routing channel with the following values:

|Field|Value|
|-----|-----|
|Routing Channel Template|FirstStatic|
|Producer|Partner2|
|Consumer|Partner1|
|User ID|User1|

Log out of the UI and log in to the `myFileGateway` ui as `partner2`. You will probably need to change the password on first login.

https://k8s-ingressn-ingressn-f9d3dcbc72-69d548b3e1e33f06.elb.us-east-1.amazonaws.com/myfilegateway

Upload a text file to the `/` mailbox and then log out.

Log in to `myfilegateway` as `partner1`. You will probably need to change the password on first login.

Click the `Download File` tab and see if the file is there. Since Partner1 is the consumer and Partner2 is the sender, the file should show up there.

Click on the file and download. Verify the file is downloaded and matches the naming convention we set.

Log out and log back in to `filegateway` as `fg_operator`. If the default `password` password does not work for him, you might need to log back into the dashboard as `fg_sysadmin` and manually set `fg_operator`'s password. Then you will be required to change it when you log in to the `filegateway`

Search for the file that was uploaded. We called it `readme.txt` in this example.

![File_search.png|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/49489c00-e2f6-411f-9673-9f63226ef131)

![File_search2.png|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/86314ce6-4907-4ae1-a94b-ce18e03f9f44)

### SFTP Access

In order to enable the SFTP Server Adapter, we first must create a host key.

Log into the `dashboard` url for B2Bi and select:

**Deployment->SSH Host Indentity Key**

Select the **Go** button next to New Host Identity key

![sfg-sftp-server-adapter-step01.png|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/b56c7114-5beb-4426-926e-2a1808ef3edb)

Set the hostname to something that matches. In our example we set it to `sterlingb2bi` and then set the key length to 2048.

![sfg-sftp-server-adapter-step02.png|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/7e71dfce-3241-4125-8f51-a9f1ed94e90f)

Under **Deployment->Services->Configuration** Create the new service.

![sfg-sftp-server-adapter-step03.png|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/243cebad-f948-4bb2-8672-6393f90f87fe)

Select `SFTP Server Adapter 2.0` under the Service Type.

![sfg-sftp-server-adapter-step04.png|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/bb6ca076-7c3e-48d5-8e39-5898f0255280)

Under `Services Configuration`, let's name this `SFTP Server Inbound` and also set that as the description. While B2BI has the capability of scaling the service to live across multiple pods, for now we are going to have it just live on our AC service pod.

![sfg-sftp-server-adapter-step05.png|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/40abfb52-fb37-4de5-bde5-8f0ca664e1ef)

Let's configure our Services Configuration for SFTP Server Inbound with the following values. Our `Host Identity Key` will be pre-populated with the host key we already created.

![sfg-sftp-server-adapter-step06.png|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/e0c21c1d-7384-4a5f-b238-af51f3889d3a)

Now let's set our document storage. For testing purposes we selected the Database to be our storage location where the files will be stored as blobs. Going forward this might not be the ideal location, but it is suitable for testing.

![sfg-sftp-server-adapter-step07.png|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/35ba645a-aef0-4d03-a6f2-97dabaf7e89c)

Next let's configure our allowed users. This can be set to match a group, but for our purposes, we will use the two partner ids we created above.

![sfg-sftp-server-adapter-step08.png|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/5e11b2c0-17f6-4e74-a2c3-fdd7ecb615f2)

Our final services configuration should look similar to below. Make sure to check `Enable Service for Business Processes` as this will actually start the service. Also important to note that the listen port for the service will be `50039`.

![sfg-sftp-server-adapter-step09.png|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/aca6e922-c6cc-4dc9-855c-9b81329596bd)

Let's verify the SFTP Adapter Service came up.

Under **Services->Configuration** search for `SFTP Inbound` as that's what we called this service adapter.

![sfg-sftp-server-adapter-step10.png|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/1272cbe7-93a2-426e-b6fe-0f7dddb06425)

Under the `Select Node` dropdown, set it to `node1AC1` as that's where we hosted this adapter service.

![sfg-sftp-server-adapter-step11.png|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/5a450a3e-9b71-4739-b8dc-b460748c9889)

You should see under Advanced Stats that the service in running and enabled. Clicking the exclaimation point next to `Enabled` will show you the service log.

![sfg-sftp-server-adapter-step12.png|300](https://zenhub.ibm.com/images/58adc1fd5a3922f84995d86b/17ae7acc-d868-40a7-8e34-73d47daf37c9)

### Cluster configuration to allow inbound access

So because we enabled the adapter to the AC node, we would need to add the extra ports to the overrides yaml for that service. 

We are also listening to port 50039

So we update our AC overrides with the following:
```
ac:
  replicaCount: 1
  env:
    jvmOptions:
    #Refer to global env.extraEnvs for sample values
    extraEnvs: []

  frontendService:
    type: ClusterIP
    ports:
      http: 
        name: http
        port: 35004
        targetPort: http
        nodePort: 30004
        protocol: TCP
    extraPorts:
      - name: sftp-frontend
        port: 50039
        targetPort: 50039
        nodePort: 50039
        protocol: TCP
    loadBalancerIP:  
    annotations: {}  
      
  backendService:
    type: LoadBalancer
    ports:
      - name: adapter-1
        port: 30401
        targetPort: 30401
        nodePort: 30401
        protocol: TCP
      - name: sftp-backend
        port: 50039
        targetPort: 50039
        nodePort: 50039
        protocol: TCP
    portRanges:
      - name: adapters
        portRange: 30501-30510
        targetPortRange: 30501-30510
        nodePortRange: 30501-30510
        protocol: TCP
    loadBalancerIP:  
    annotations: {} 
```

Let's run a helm upgrade after updating our overrides:

```
helm upgrade sterling-b2bi --debug -f overrides/sterling-b2bi-values.yaml ibm-b2bi-prod --timeout 3600s --namespace sterling
```

When that is complete, retrieve the loadbalancer address with the following command:

```
kubectl get service sterling-b2bi-b2bi-ac-backend-svc -o jsonpath="{..hostname}"

a3185b1737b284bcea6584859ea689e3-2046710660.us-east-1.elb.amazonaws.com
```

Verify that SFTP works from cmdline with the following:

```
sftp -P 50039 partner2@a3185b1737b284bcea6584859ea689e3-2046710660.us-east-1.elb.amazonaws.com
The authenticity of host '[a3185b1737b284bcea6584859ea689e3-2046710660.us-east-1.elb.amazonaws.com]:50039 ([3.214.94.81]:50039)' can't be established.
RSA key fingerprint is SHA256:fVTB9EihSrd651+zvl2RvzjuhZX11iwQaxNwBgDyvT4.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[a3185b1737b284bcea6584859ea689e3-2046710660.us-east-1.elb.amazonaws.com]:50039' (RSA) to the list of known hosts.
SSH Server supporting SFTP and SCP
partner2@a3185b1737b284bcea6584859ea689e3-2046710660.us-east-1.elb.amazonaws.com's password: 
Connected to a3185b1737b284bcea6584859ea689e3-2046710660.us-east-1.elb.amazonaws.com.
sftp>

```

We should now be able to put files here and observe their routing in the filegateway

:::note

You may need to update the health check ports in AWS EC2 for the loadbalancer to point to port `50039` or the nodePort as this will otherwise not allow traffic in.

If you run into any helm error when adding the extra ports definitions that has "doesn't match $setElementOrder list" in the output, it's possible this is a helm related bug. Re-run the "helm upgrade" with "--force"

:::
