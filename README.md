# Incode devops task
### Overview
I didn't use terraform to create a bucket for state and dynamodb for locks because of a chicken-and-egg problem. As option, they might be created manually, by CloudFormation or Terragrunt.

Monitoring is not a part of "simple scenario" which you can do perform in 1d

I decided to use ecs fargate instead of EC2 instances because of:
* security and maintenance reasons - ec2 instances should be patched regularly. Deploying an app to EC2 directly without docker is something legacy 
* scaling reason - fargate implementation scales better than ec2
* budget reason - EC2 instance will eat money even with low load

Service Discovery with TLS is a good security opportunity, but it is overengineering for one app
