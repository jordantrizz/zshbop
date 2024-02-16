# WordPress MySQL Queries
## MySQL User Setup
```
INSERT INTO `databasename`.`wp_users` (`ID`, `user_login`, `user_pass`, `user_nicename`, `user_email`, `user_url`, `user_registered`, `user_activation_key`, `user_status`, `display_name`) VALUES ('4', 'demo', MD5('demo'), 'Your Name', 'test@yourdomain.com', 'http://www.test.com/', '2011-06-07 00:00:00', '', '0', 'Your Name');
INSERT INTO `databasename`.`wp_usermeta` (`umeta_id`, `user_id`, `meta_key`, `meta_value`) VALUES (NULL, '4', 'wp_capabilities', 'a:1:{s:13:"administrator";s:1:"1";}');
INSERT INTO `databasename`.`wp_usermeta` (`umeta_id`, `user_id`, `meta_key`, `meta_value`) VALUES (NULL, '4', 'wp_user_level', '10');
```

## Clear out Scheduled Actions

* Clear out all scheduled actions based on time.
```
DELETE FROM `wp_bspr_actionscheduler_actions` WHERE `scheduled_date_gmt` < NOW() - INTERVAL 1 WEEK;
```
* Clear out all scheduled actions based on time and status. 
```
DELETE FROM `wp_bspr_actionscheduler_actions` WHERE `status` = 'complete' AND `scheduled_date_gmt` < NOW() - INTERVAL 1 WEEK;
```
* Clear out all scheduled actions based on time and status.
```
DELETE FROM `wp_bspr_actionscheduler_actions` WHERE `status` = 'complete';
```

# wp-cli Commands
## Update Administrator Email
* ```wp option update admin_email user@example.com```
* ```update_option('admin_email', "info@domain.com");```

## Another Update is Currently in Progress
```wp option delete core_updater.lock```


## Temporary Login
* wp package install aaemnnosttv/wp-cli-login-command
* wp login install
* wp login create 1

# WordPress Configuration File
## WordPress Debug
```
define( 'WP_DEBUG', true )
if ( WP_DEBUG ) {
    define( 'WP_DEBUG_LOG', true );
    define( 'WP_DEBUG_DISPLAY', false);
    @ini_set( 'log_errors', true );
    @ini_set( 'error_log', dirname(__FILE__) . '/debug.log' );
};
```
## Change Site URL
* Add wp-config.php
```
define( 'WP_HOME', 'http://example.com' );
define( 'WP_SITEURL', 'http://example.com' );
```

# Linux Commands
## Tar Backup Directory
```tar -cvf public_html-01-01-2023.tar --exclude wp-content/cache --exclude wp-content/ai1wm-backups```

## Rsync Backup
```rsync -avz public_html root@192.168.0.101 --exclude wp-content/cache --exclude wp-content/ai1wm-backups```

# WordPress Code Snippets
## Error Logging for 'There has been a critical error on your website.' errors
Use this code snippet to print the actualy critical error
```
<?php
add_filter('wp_php_error_message', function ($message,$error) {
    error_log("Error-".print_r($message,true));
});
```