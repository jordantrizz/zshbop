# MySQL Memory Settings
## innodb_flush_method
If you want to use OS caching for some storage engines. With InnoDB, we recommend innodb_flush_method=O_DIRECT  in most cases, which won’t use Operating System File Cache. However, there have been cases when using buffered IO with InnoDB made sense. If you’re still running MyISAM, you will need OS cache for the “data” part of your tables.
