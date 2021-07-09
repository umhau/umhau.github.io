create a new VM from my base image customize it

# clone the base image, create a snapshot of the new VM, and log in
VBoxManage list runningvms
VBoxManage list vms
VBoxManage clonevm 8f220529-32a4-4e89-b3d3-d60202c319ef --register --name="new_vm"

# change the amount of RAM the machine will allocate (in MB). e.g., the VPN server needs <1GB.
VBoxManage modifyvm 8f220529-32a4-4e89-b3d3-d60202c319ef --memory 1000 

# change the MAC address of the machine, so it will receive a unique IP address
VBoxManage modifyvm 8f220529-32a4-4e89-b3d3-d60202c319ef --macaddress1 auto

VBoxManage startvm 92d2f328-e342-4a11-b520-1d16b118819b --type headless

VBoxManage list runningvms

start / stop / pause 

VBoxManage startvm 92d2f328-e342-4a11-b520-1d16b118819b --type headless
VBoxManage controlvm "vm name" poweroff
VBoxManage controlvm 92d2f328-e342-4a11-b520-1d16b118819b pause

log into the new VM

# get IP address
VBoxManage guestproperty get VM-NAME /VirtualBox/GuestInfo/Net/0/V4/IP

# log in
ssh umhau@IP

change the hostname and reboot
sudo hostnamectl set-hostname descriptive_new_hostname`

# the hostname of the base image is cameras_fbcr_vm. Find that and change to the new hostname.
sudo vim /etc/hosts

# change "preserve_hostname: false" to "preserve_hostname: true".
sudo vim  /etc/cloud/cloud.cfg

sudo reboot

save settings
VBoxManage snapshot 92d2f328-e342-4a11-b520-1d16b118819b take snapshot-name
