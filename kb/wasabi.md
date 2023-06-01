# Using S3 Client
1. Install aws cli
2. Setup profile
```
aws configure --profile wasabi
```
3. Install awscli-plugin-endpoint
```
pip install awscli-plugin-endpoint
aws configure set plugins.endpoint awscli_plugin_endpoint
aws configure set plugins.cli_legacy_plugin_path /home/username/.local/lib/python3.8/site-packages/
aws configure --profile wasabi set s3.endpoint_url https://s3.wasabisys.com
```
# Testing Wasabi Storage
* You need to have s3fs installed as a package
1. Create $HOME/.wasabi and add the following to the file
```accessKeyId:secretAccessKey```
2. Ensure Permissions are 600 on $HOME/.wasabi
```chmod $HOME/.wasabi```
2. Mount the storage
```s3fs -f wasabistorage $HOME/mnt/wasabistorage -o passwd_file=$HOME/.wasabi -o url=https://s3.eu-west-2.wasabisys.com```