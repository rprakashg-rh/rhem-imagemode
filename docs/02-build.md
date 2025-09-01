# Building the Imagemode Container

## Build container
Run the command below to build the container

```sh
podman build --secret id=creds,src=$HOME/.config/containers/auth.json \
    --authfile=$PULL_SECRET \
    -t "$REGISTRY/$REGISTRY_USER/rhem-server" \
    -f Containerfile .
```

## Push to registry
Push the container image to registry

```sh
podman push "$REGISTRY/$REGISTRY_USER/rhem-server"
```

## Create AMI for testing in AWS 
Create amazon machine image (AMI) for testing in AWS

### Overlay cloud-init
Overlay cloud init packages. 

First switch to cloud-init directory under images

```sh
cd ../cloud-init
```

then run podman build to build a new image with aws tag

```sh
podman build \
--build-arg=FROM=$REGISTRY/$REGISTRY_USER/rhem-server \
-t $REGISTRY/$REGISTRY_USER/rhem-server:aws \
-f Containerfile .
```

Push to registry
```sh
podman push $REGISTRY/$REGISTRY_USER/rhem-server:aws
```

### Build AMI using BiB
Build the AMI image using Bootc Image Builder. Before we can build ami using BiB we need to perform following steps below. This needs to only be done one time on the AWS account

#### Create an S3 bucket
Create an S3 bucket to store images using the command below

```sh
aws s3api create-bucket \
    --bucket=bootc-amis \
    --create-bucket-configuration LocationConstraint=$AWS_DEFAULT_REGION
```
#### Create vmimport service role
Create vmimport service role by running command below

```sh
aws iam create-role \
  --role-name=vmimport \
  --assume-role-policy-document='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "vmie.amazonaws.com"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:Externalid": "vmimport"  
                }
            }
        }
    ]}' \
--query='Role.Arn' \
--output=text | pbcopy
```
Note down the Role ARN: arn:aws:iam::102214807189:role/vmimport

#### Create role policy
Create an IAM policy for vmimport role

```sh
aws iam create-policy \
    --policy-name=vmimport_service_role_policy \
    --policy-document='{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action":  [
                    "s3:GetBucketLocation",
                    "s3:GetObject",
                    "s3:PutObject"
                ],
                "Resource": [
                    "arn:aws:s3:::bootc-amis",
                    "arn:aws:s3:::bootc-amis/*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:GetBucketLocation",
                    "s3:GetObject",
                    "s3:ListBucket",
                    "s3:PutObject",
                    "s3:GetBucketAcl"
                ],
                "Resource": [
                    "arn:aws:s3:::bootc-amis",
                    "arn:aws:s3:::bootc-amis/*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:ModifySnapshotAttribute",
                    "ec2:CopySnapshot",
                    "ec2:RegisterImage",
                    "ec2:Describe*"
                ],
                "Resource": "*"
            }
        ]}' \
--query='Policy.Arn' \
--output=text | pbcopy
```

Note down the policy ARN: arn:aws:iam::102214807189:policy/vmimport_service_role_policy

#### Attach the Policy to Role
Attach the IAM policy to the IAM role

```sh
aws iam attach-role-policy \
  --role-name=vmimport \
  --policy-arn=arn:aws:iam::102214807189:policy/vmimport_service_role_policy
```

Now we can run BiB to create the AMI. Remember above steps only need to be done once on the AWS account

```sh
sudo podman run \
--authfile=$PULL_SECRET \
--rm \
--privileged \
--security-opt label=type:unconfined_t \
--env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
--env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
--env AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
--env AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} \
-v /var/lib/containers/storage:/var/lib/containers/storage \
registry.redhat.io/rhel9/bootc-image-builder:latest \
--local \
--type ami \
--aws-ami-name rhem-server-x86_64 \
--aws-bucket bootc-amis \
--aws-region us-west-2 \
$REGISTRY/$REGISTRY_USER/rhem-server:aws
```
