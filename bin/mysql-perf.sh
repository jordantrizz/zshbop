#!/usr/bin/env bash

 mysql -e 'show variables like "innodb_buffer_pool_size%";'