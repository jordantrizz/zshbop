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
