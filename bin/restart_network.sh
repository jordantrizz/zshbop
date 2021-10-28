#!/bin/sh
sudo ifdown --exclude=lo -a && sudo ifup --exclude=lo -a
