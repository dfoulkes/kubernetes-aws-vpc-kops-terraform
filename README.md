# kubernetes-aws-vpc-kops-terraform

Example code for
the
[Deploy Kubernetes in an Existing AWS VPC with Kops and Terraform](https://ryaneschinger.com/blog/kubernetes-aws-vpc-kops-terraform/) blog
post.

## tldr

```bash
terraform apply -var name=yourdomain.com

export NAME=$(terraform output cluster_name)
export KOPS_STATE_STORE=$(terraform output state_store)
export ZONES=$(terraform output -json availability_zones | jq -r '.value|join(",")')

kops create cluster \
    --master-zones $ZONES \
    --zones $ZONES \
    --topology private \
    --dns-zone $(terraform output public_zone_id) \
    --networking calico \
    --vpc $(terraform output vpc_id) \
    --target=terraform \
    --out=. \
    ${NAME}

terraform output -json | docker run --rm -i ryane/gensubnets:0.1 | pbcopy

kops edit cluster ${NAME}

# replace *subnets* section with your paste buffer (be careful to indent properly)
# save and quit editor

kops update cluster \
  --out=. \
  --target=terraform \
  ${NAME}

terraform apply -var name=yourdomain.com
```

## using a subdomain

If you want all of your dns records to live under a subdomain in its own hosted
zone, you need to setup route delegation to the new zone. After running
`terraform apply -var name=k8s.yourdomain.com`, you can run the following
commands to setup the delegation:

```bash
export KUBE_DOMAN=yourdomain.com
terraform apply -var name=k8s.$KUBE_DOMAN
cat update-zone.json \
 | jq ".Changes[].ResourceRecordSet.Name=\"$(terraform output name).\"" \
 | jq ".Changes[].ResourceRecordSet.ResourceRecords=$(terraform output -json name_servers | jq '.value|[{"Value": .[]}]')" \
 > update-zone.json

aws --profile=default route53 change-resource-record-sets \
 --hosted-zone-id $(aws --profile=default route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name=="$KUBE_DOMAN.") | .Id' | sed 's/\/hostedzone\///') \
 --change-batch file://update-zone.json
```

Wait until your changes propagate before continuing. You are good to go when

```bash
host -a k8s.$KUBE_DOMAN
```

## Configure the Master Nodes

By deafult, the node type used is T2.medium, since this is a low cost demo, we should change the master nodes to be of type T2.micro
todo this, enter the following command:
```
 kops edit ig nodes  
```

in the editor, change the follwoing line:
```
machineType: t2.micro
```

After editing, run the following:

```
kops update cluster $NAME
```

This will preview the changes, if you wish to proceed, then enter:

```
kops update cluster $NAME -y
```


returns the correct NS records.

To Set The Type of Nodes

## Creating a Pod and deploying

example:
```
kubectl run kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --port=8080
```

to see the output of this pod, you will first need to launch the proxy:
```
kubectl proxy
```

Then to see the content try:

```
export POD_NAME=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
curl http://localhost:8001/api/v1/namespaces/default/pods/$POD_NAME/proxy/
```


## Deleting Cluster
To delete the cluster you will need to execute the following:

```
 kops delete cluster $NAME --yes
```