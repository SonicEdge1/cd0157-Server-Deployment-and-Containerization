#!/bin/bash

# amazon cli command to set up an EKS cluster nodegroup containing two m5.large nodes.
#if multiple profiles are set up, don't forget to use the --profile <profile name> tag
eksctl create cluster --name simple-jwt-api --region=us-west-1
kubectl get nodes

#to delete the cluster
# eksctl delete cluster simple-jwt-api  --region=us-west-1

# create role if necessary
aws iam create-role --role-name UdacityFlaskDeployCBKubectlRole --assume-role-policy-document file://trust.json --output text --query 'Role.Arn'
# Attach the iam-role-policy.json policy to the 'UdacityFlaskDeployCBKubectlRole'
aws iam put-role-policy --role-name UdacityFlaskDeployCBKubectlRole --policy-name eks-describe --policy-document file://iam-role-policy.json

# Fetches the current configmap and saves it to a file.
# The file will be created at `/System/Volumes/Data/private/tmp/aws-auth-patch.yml` path
kubectl get -n kube-system configmap/aws-auth -o yaml > /tmp/aws-auth-patch.yml

# Add the following group in the data → mapRoles section of the YAML file:
# mapRoles: |
#  - groups:
#    - system:masters
#    rolearn: arn:aws:iam::<ACCOUNT_ID>:role/UdacityFlaskDeployCBKubectlRole
#    username: build 
code /tmp/aws-auth-patch.yml

# Update the cluster's configmap
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat /tmp/aws-auth-patch.yml)"
# The command above should return "configmap/aws-auth patched"

############create pipeline that watches github############
# Generate a Github access token and save somewhere secure
# modify ci-cd-codepipeline.cfn.yml template to include github user name
# GitHubUser	-> Default:	Your Github username
# Create Stack
# Use the AWS web-console to create a stack for CodePipeline using the CloudFormation template file ci-cd-codepipeline.cfn.yml. Go to the CloudFormation service in the AWS console. Press the Create Stack button. It will make you go through the following three steps -
# Step 1 - Specify template - Choose the options "Template is ready" and "Upload a template file" to upload the template file ci-cd-codepipeline.cfn.yml. Click the 'Next' button.
# Step 2 - Specify stack details - Give the stack a name, fill in your GitHub login, and the Github access token generated in the previous step. Make sure that the cluster name matches the one you have created, and the 'kubectl IAM role' matches the role you created above, and the repository matches the name of your forked repo.
# Step 3 - Configure stack options - Leave default, and create the stack.

###########Set a Secret using AWS Parameter Store###########
# Add the following to the end of the buildspec.yml file
# env:
#   parameter-store:         
#     JWT_SECRET: JWT_SECRET
# put secret into AWS Parameter Store
aws ssm put-parameter --name JWT_SECRET --overwrite --value "YourJWTSecret" --type SecureString

# To delete secret:
# aws ssm delete-parameter --name JWT_SECRET