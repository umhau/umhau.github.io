#!/bin/bash

# reduce the swappiness of the system - still have access in an emergency, but
# swap isn't used regularly.  src: https://askubuntu.com/a/440349

sudo nano /etc/sysctl.conf

# to the bottom of the file, append
vm.swappiness=1
