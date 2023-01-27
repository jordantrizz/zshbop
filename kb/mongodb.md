# Reset Admin Login
* https://dba.stackexchange.com/questions/62976/how-can-i-enter-mongo-as-a-superuser-or-reset-users

1. Connect to the machine that was hosting my MongoDB instance
2. Open the MongoDB configuration file found in /etc/ folder using: sudo nano mongod.conf
3. Comment out the following code like so:
```
# security:
#   authorization: enabled
```
4. Stop the MongoDB service: sudo service mongod stop
5. Start the MongoDB service: sudo service mongod start
6. Connect to the database using Robo3T or equivalent. With a connection to the admin collection, create a new admin superuser:
```
db.createUser({ user:"admin", pwd:"password", roles:[{role:"root", db:"admin"}] });
```
7. Go back and uncomment the lines from step 3. Then repeat steps 4 and 5.

You should now be able to authenticate with the new user you created in step 6 and have full access to the database.
