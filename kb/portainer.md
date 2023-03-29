# Updating an Image
## Option 1
1. Go to your dashboard and open your Stack (stack details)
2. Switch to the Editor tab
3. Just below the editor, you will see a button to update the stack . This works similar to docker compose up.
4. Click on Update the Stack. Skip the option ` prune services` .

## Option 2
1. Stop container
2. Click Re-create and select pull latest image.
3. Start container after creation is finished.

# Updating Portainer
* cd /home/ubuntu/docker/core
* docker-compose pull
* docker-compose up -d