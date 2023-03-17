# Add user via Docker
```
docker exec -it <containerid>
./plikd --config ./plikd.cfg user create --login root --name Admin --admin
```