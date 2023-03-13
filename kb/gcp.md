# GCP CLI
## Install CLI
### Ubuntu/Debian Install
* The full install is located at https://cloud.google.com/sdk/docs/install-sdk#deb
```
sudo apt-get install apt-transport-https ca-certificates gnupg
sudo echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt-get update && sudo apt-get install google-cloud-cli
```
## Setup CLI
```
gcloud auth login --no-launch-browser
gcloud config set project <projectid>
gcloud config set compute/region us-central1-a
```

# SSH Login
## External with OS Login via IAM
```
gcloud compute os-login ssh-keys add \
    --key-file=$HOME/.ssh/KEY_FILE_PATH \
    --project=PROJECT \
    --ttl=EXPIRE_TIME 
```