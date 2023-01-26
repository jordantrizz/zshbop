# AWS CLI
## Login
```aws configure```
## Session Manager Plugin
* https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
```
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
```

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