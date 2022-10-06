# WordPress MySQL Queries
## MySQL User Setup
```
INSERT INTO `databasename`.`wp_users` (`ID`, `user_login`, `user_pass`, `user_nicename`, `user_email`, `user_url`, `user_registered`, `user_activation_key`, `user_status`, `display_name`) VALUES ('4', 'demo', MD5('demo'), 'Your Name', 'test@yourdomain.com', 'http://www.test.com/', '2011-06-07 00:00:00', '', '0', 'Your Name');
INSERT INTO `databasename`.`wp_usermeta` (`umeta_id`, `user_id`, `meta_key`, `meta_value`) VALUES (NULL, '4', 'wp_capabilities', 'a:1:{s:13:"administrator";s:1:"1";}');
INSERT INTO `databasename`.`wp_usermeta` (`umeta_id`, `user_id`, `meta_key`, `meta_value`) VALUES (NULL, '4', 'wp_user_level', '10');
```
# wp-cli Commands
## Update Administrator Email
* ```wp option update admin_email user@example.com```

## Temporary Login
* wp package install aaemnnosttv/wp-cli-login-command
* wp login install
* wp login create 1

# WordPress Debug
```
define( 'WP_DEBUG', true )
if ( WP_DEBUG ) {
    define( 'WP_DEBUG_LOG', false );
    define( 'WP_DEBUG_DISPLAY', false);
    @ini_set( 'log_errors', true );
    @ini_set( 'error_log', dirname(__FILE__) . '/debug.log' );
};
```