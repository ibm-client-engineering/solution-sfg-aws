---
id: solution-integrate
sidebar_position: 3
title: Integrate
---

# B2Bi Adapter creation and configuration

## Configuring communication adapters:

The following adapters can be used with Sterling File Gateway:

| Protocol | Adapter |
|----------|---------|
| FTP, FTPS | FTP Server adapter |
| FTP, FTPS |	FTP Client adapter and services |
| SSH/SFTP, SSH/SCP |	SFTP Server adapter |
| SSH/SFTP |	SFTP Client adapter and services |
| Sterling Connect:Direct |	Connect:Direct Server adapter |
| PGP |	Command Line Adapter 2 |
| HTTP, HTTPS, WebDAV (Requires extensibility. See Add Custom Protocols.) |	HTTP Server adapter |
| HTTP, HTTPS, WebDAV (Requires extensibility. See Add Custom Protocols.) |	HTTP Client adapter and services |
| WebSphere® MQ File Transfer Edition |
- WebSphere MQ File Transfer Edition Agent adapter
- WebSphere MQ Suite Async adapter
- WebSphere MQ File Transfer Edition Create Transfer service
- FTP Server Adapter |


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

<img src="../../../images/Template_Type.png" width="300">
<img src="../../../images/Template_Special_Characters.png" width="300">
<img src="../../../images/Template_Groups.png" width="300">
<img src="../../../images/Template_Provisioning_Facts.png" width="300">
<img src="../../../images/Template_Producer_File_Structure.png" width="300">
<img src="../../../images/Template_Consumer_File_Structure_add.png" width="300">
<img src="../../../images/Template_Consumer_File_Structure_format.png" width="300">
<img src="../../../images/Template_Consumer_File_Structure_Save.png" width="300">

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

<img src="../../../images/File_search.png" width="300">

<img src="../../../images/File_search2.png" width="300">

### SFTP Access

In order to enable the SFTP Server Adapter, we first must create a host key.

Log into the `dashboard` url for B2Bi and select:

**Deployment->SSH Host Indentity Key**

Select the **Go** button next to New Host Identity key

<img src="../../../images/sfg-sftp-server-adapter-step01.png" width="300">

Set the hostname to something that matches. In our example we set it to `sterlingb2bi` and then set the key length to 2048.

<img src="../../../images/sfg-sftp-server-adapter-step02.png" width="300">

Under **Deployment->Services->Configuration** Create the new service.

<img src="../../../images/sfg-sftp-server-adapter-step03.png" width="300">

Select `SFTP Server Adapter 2.0` under the Service Type.

<img src="../../../images/sfg-sftp-server-adapter-step04.png" width="300">

Under `Services Configuration`, let's name this `SFTP Server Inbound` and also set that as the description. While B2BI has the capability of scaling the service to live across multiple pods, for now we are going to have it just live on our AC service pod.

<img src="../../../images/sfg-sftp-server-adapter-step05.png" width="300">

Let's configure our Services Configuration for SFTP Server Inbound with the following values. Our `Host Identity Key` will be pre-populated with the host key we already created.

<img src="../../../images/sfg-sftp-server-adapter-step06.png" width="300">

Now let's set our document storage. For testing purposes we selected the Database to be our storage location where the files will be stored as blobs. Going forward this might not be the ideal location, but it is suitable for testing.

<img src="../../../images/sfg-sftp-server-adapter-step07.png" width="300">

Next let's configure our allowed users. This can be set to match a group, but for our purposes, we will use the two partner ids we created above.

<img src="../../../images/sfg-sftp-server-adapter-step08.png" width="300">

Our final services configuration should look similar to below. Make sure to check `Enable Service for Business Processes` as this will actually start the service. Also important to note that the listen port for the service will be `50039`.

<img src="../../../images/sfg-sftp-server-adapter-step09.png" width="300">

Let's verify the SFTP Adapter Service came up.

Under **Services->Configuration** search for `SFTP Inbound` as that's what we called this service adapter.

<img src="../../../images/sfg-sftp-server-adapter-step10.png" width="300">

Under the `Select Node` dropdown, set it to `node1AC1` as that's where we hosted this adapter service.

<img src="../../../images/sfg-sftp-server-adapter-step11.png" width="300">

You should see under Advanced Stats that the service in running and enabled. Clicking the exclaimation point next to `Enabled` will show you the service log.

<img src="../../../images/sfg-sftp-server-adapter-step12.png" width="300">

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
