---
id: solution-deploy
sidebar_position: 1
title: Deploy
---

# Sterling Installation

## Required secrets

Create the following secrets in the `sterling` namespace

`sterling-secrets.yaml`
```
apiVersion: v1
kind: Secret
metadata:
  name: b2b-system-passphrase-secret
type: Opaque
stringData:
  SYSTEM_PASSPHRASE: password
---
apiVersion: v1
kind: Secret
metadata:
    name: mq-secret
type: Opaque
stringData:
    JMS_USERNAME: app
    JMS_PASSWORD: mqpasswd
---
apiVersion: v1
kind: Secret
metadata:
  name: b2b-db-secret
type: Opaque
stringData:
  DB_USER: SI_USER
  DB_PASSWORD: dbpassword
```
As a note, we are setting the user/pass for the database to `SI_USER` with a password of `dbpassword`.

Apply the secrets.
```
kubectl apply -f sterling-secrets.yaml -n sterling
```

## Sidecar Deployment

In order to upload the required jdbc drivers that b2bi will need to talk to the database, we must create a sidecar pod with a storage volume that will be shared.

### Generate the yaml file

Create the following file

`sterlingtoolkitdeploy.yaml`
```
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sterlingtoolkit-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sfg-sc
  resources:
    requests:
      storage: 20Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sterlingtoolkit
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sterlingtoolkit
  template:
    metadata:
      labels:
        app: sterlingtoolkit
    spec:
      containers:
      - name: sterlingtoolkit
        image: centos
        command: ["/bin/sh"]
        args: ["-c", "useradd -u 1010 b2biuser && sleep infinity"]
        volumeMounts:
        - mountPath: /var/nfs-data/resources
          name: storagevol
      volumes:
      - name: storagevol
        persistentVolumeClaim:
          claimName: sterlingtoolkit-pvc
```

### Create the sidecar pod and volume

```
kubectl apply -f sterlingtoolkitdeploy.yaml
```

### Retrieve the JDBC driver and stage it to the pod

Download the Oracle JDBC driver

https://download.oracle.com/otn-pub/otn_software/jdbc/219/ojdbc8.jar

Determine our pod name
```
kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
oracleclient                       1/1     Running   0          3h55m
sterlingtoolkit-577b8c56f5-dchdx   1/1     Running   0          4m59s
```

Upload the jar file to the appropriate folder

```
kubectl cp ojdbc11.jar sterlingtoolkit-577b8c56f5-dchdx:/var/nfs-data/resources
```
## Download the Sterling helm charts

The following link is for the required helm charts for this installation. If you haven't already pulled this down, do it now.

[ibm-b2bi-prod-2.1.3](https://github.com/IBM/charts/raw/master/repo/ibm-helm/ibm-b2bi-prod-2.1.3.tgz)

Download the `ibm-b2bi-prod` helm charts from the above link.

Extract the `ibm-b2bi-prod-2.1.1.tgz` file
```
tar zxvf ibm-b2bi-prod-2.1.1.tgz
```
We will need to update the Kubernetes version in the `Chart.yaml`

```
cd ibm-b2bi-prod
```
### Update our chart version

:::note

As of this writing, you will need to update the version in the `Chart.yaml`.

:::

Retrieve our EKS kubernetes version
```
kubectl version --short

Client Version: v1.23.0
Kustomize Version: v4.5.7
Server Version: v1.23.14-eks-ffeb93d
```
### Update the Chart.yaml

Make a note of the `Server Version` and update the `Chart.yaml` file in the `ibm-b2bi-prod` directory.
```
sed -i "s/^kubeVersion:.*/kubeVersion: '>=v1.23.14-eks-ffeb93d'/" Chart.yaml
```

## Sterling Override File

This is valid for installing the Sterling B2BI product. 

[sterling-overrides-b2bi.yaml](../../../overrides/sterling-b2bi-values.yaml)

:::note

If you need to add custom labeling for the pods, look for this section under each application definition in the overrides file:

```
  # for pod Affinity and podAntiAffinity
  extraLabels: {}
    #acLabel: acValue
```

Add the labels that would be applied to each pod

```
  # for pod Affinity and podAntiAffinity
  extraLabels:
    customlabelname: customlabelvalue 
```

:::

### Update the overrides as required

Host entries for each ingress should match what your existing domain is if you don't have a dedicated FQDN. This means you should set a wildcard.

In our example, we are on AWS so our ingress host entries look like the following in the overrides document for each application (ac, asi, api):

```
  ingress:
    internal:
      host: "*.elb.us-east-1.amazonaws.com"
      tls:
        enabled: true
        secretName: sterling-b2bi-b2bi-ac-frontend-svc
      extraPaths: []
    external:
      host: "*.elb.us-east-1.amazonaws.com" 
      tls:
        enabled: true
        secretName: sterling-b2bi-b2bi-ac-frontend-svc
      extraPaths: []
```

### Setting MQ info in the overrides

Run the following sed commands on the overrides file. You should have the cluster-ip of the MQ service from a previous step in during Preparation:

```
sed -i "s/^jmsVendor:.*/jmsVendor: IBMMQ/" sterling-b2bi-values.yaml
sed -i "s/^jmsQueueName:.*/jmsQueueName: DEV.QUEUE.1/" sterling-b2bi-values.yaml
sed -i "s/^jmsHost:.*/jmsHost: 10.100.98.89/" sterling-b2bi-values.yaml
sed -i "s/^jmsChannel:.*/jmsChannel: DEV.APP.SVRCONN/" sterling-b2bi-values.yaml
sed -i "s/^jmsSecret:.*/jmsSecret: mq-secret/" sterling-b2bi-values.yaml
```

### Setting the Database info in the overrides

Run the following sed commands on the overrides file. Make sure you took note of the RDS url to access the RDS instance.

```
sed -i "s/^dbVendor:.*/dbVendor: Oracle/" sterling-b2bi-values.yaml
sed -i "s/^dbHost:.*/dbHost: sterling-mft-db.cehubq1eqcri.us-east-1.rds.amazonaws.com/" sterling-b2bi-values.yaml
sed -i "s/^dbPort:.*/dbPort: 1521/" sterling-b2bi-values.yaml
sed -i "s/^dbData:.*/dbData: ORCL/" sterling-b2bi-values.yaml
```

### Custom Network Policies

If your cluster is restrictive, you may need to add extra customPolicies to the overrides file. This can be found near the top and would resemble the following entries:

```
global:
  license: true
  image:
    repository: "cp.icr.io/cp/ibm-b2bi/b2bi"
    tag: "6.1.2.1"
    digest: sha256:7426e3f8d935f28135b3f2b9cd5bc653105af9609606da967cb1cf70ca0b49de
    pullPolicy: IfNotPresent
    pullSecret: "ibm-pull-secret"
  networkPolicies:
    ingress:
      enabled: true
      customPolicies:
    egress:
      enabled: true
// hightlight-start
      customPolicies:
      - name: allow-egress-to-rds
        toSelectors:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: b2bi
              release: sterling-b2bi
        - ipBlock:
            cidr: 192.168.99.219/32
        ports:
          - protocol: TCP
            port: 1521
      - name: allow-egress-to-cd
        toSelectors:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: b2bi
              release: sterling-b2bi
        - ipBlock:
            cidr: 192.168.99.219/32
        ports:
          - protocol: TCP
            port: 1366
// highlight-end
```
### Increased proxy-body-size

Ingress needs to be updated globally in the overrides to allow for uploading large jar files to the B2Bi api.

```
ingress:
  enabled: true
  controller: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: 2000m
  port:
```

### TLS SecretNames for ingress

When the tls option is enabled for each app container, the secretName is created by the creattls job that is run at the beginning of the installation. So that secret can be applied in advance to the overrides:

```
ac.ingress.external.tls.enabled = true

ac.ingress.external.tls.secretName = sterling-b2bi-b2bi-ac-frontend-svc

asi.ingress.external.tls.enabled = true

asi.ingress.external.tls.secretName = sterling-b2bi-b2bi-asi-frontend-svc

api.ingress.external.tls.enabled = true

api.ingress.external.tls.secretName = sterling-b2bi-b2bi-asi-frontend-svc
```

## Perform the Helm installation

Run the helm installation with the following command

```
helm install sterling-b2bi -f sterling-b2bi-values.yaml /path/to/ibm-b2bi-prod --timeout 3600s --namespace sterling
```

Installation should take approximately 40 minutes


### Application Validation

## Default Sterling Users:

| Role | User ID | Password |
|------|---------|----------|
| System Administrator | fg_sysadmin | password |
| Integration Architect | fg_architect | password |
| Route Provisioner |	fg_provisioner | password |
| Operator | fg_operator | password |


Relevant URL:
https://www.ibm.com/docs/en/b2b-integrator/6.1.2?topic=overview-sterling-file-gateway-tutorial