#!/bin/bash

src=/root/bootstrap
opscode_url=http://opscode.com/chef/install.sh

user=duck
home=/home/$user
sudoers_entry="%sudo	ALL=(ALL) NOPASSWD: ALL"  # <-- hard tab there!

if grep -wi ubuntu /etc/issue; then
    ubuntu=true
elif grep -wi centos /etc/issue; then
    centos=true
    groupadd sudo
else
    echo -e "i don't know how to bootstrap this os!\n"
    cat /etc/issue
    exit 1
fi

# duck
crypt='$6$M2K7/dBx$vzp5MUa6bDaMe4sDjAt4nerVJE/XkYWocHBKU2dqDa/1mxr288h74tqok0YU864SeoH/QKKpLoa8prIwiRHAp.'
useradd -m -G root,adm,sudo,games,users -p "$crypt" -s /bin/bash $user

# dotfiles
shopt -s dotglob
export GLOBIGNORE=_ # anything non-null causes `.' and `..' to be ignored

cp -vLr $src/.* $home
cp -vLr $src/.* /root

chown -R $user: $home

# ssh keys
chmod -v 750 $home/.ssh
chmod -v 600 $home/.ssh/id_rsa

# hosts
cat $src/hosts |grep -vw `hostname` >> /etc/hosts

# chef
curl -SsL $opscode_url |bash
cp -av $src/.chef /root
sed -i 's/@@CHEF_HOSTNAME@@/chef/' /root/.chef/knife.rb
echo "node_name                '`hostname`'" >> /root/.chef/knife.rb
knife configure client /etc/chef
cp -v $src/bin/* /usr/local/bin

# sudo
if [ -n $centos ]; then
    # add line for centos
    echo "$sudoers_entry" >> /etc/sudoers
else
    # modify existing line for ubuntu
    sed -i "s/^%sudo.*/$sudoers_entry/" /etc/sudoers
fi

# sshd
sed -ri 's/^#?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
service ssh${centos:+d} restart

# iptables
if [ -n $centos ]; then
    service iptables stop
    chkconfig iptables off
fi

# run chef-client
ch
