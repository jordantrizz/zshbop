# Traefik Authentication Configuration
## Config
```
- "traefik.http.middlewares.instancename-secure.basicauth.users=username:encodedpassword"
```

# Password
```
echo $(htpasswd -nB user) | sed -e s/\\$/\\$\\$/g
```