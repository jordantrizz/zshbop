# AWS CLI
## Login
```aws configure```
## Pull down Docker EKR
* https://medium.com/geekculture/how-to-locally-pull-docker-image-from-aws-ecr-ebebbb4c100
```
aws ecr get-login-password --region <region_name> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region_name>.amazonaws.com
docker pull <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com/<repo_name>:<tag>
```


# AWS Linux
## Enable EPEL repository on AWS Linux
```amazon-linux-extras install epel -y```

## Troubleshoot EPEL Issues
* yum repolist

## Enable EPEL on AL1 
* yum install epel-release
* Double check /etc/yum/repos.d for enabled=1

# Get OS version
```cat /etc/os-release```