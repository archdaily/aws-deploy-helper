AWS Deploy Helper
=================

A little ruby lib to ease the deployment to an AWS Auto Scaling Group. It connects to an AWS Elastic Load Balancer, see the current instances and generate the ssh and capistrano config files.

Instructions
============

- Clone this repo in the machine where you are going to execute ``` cap deploy ```
- Rename ```config/config.yml.example``` to ```config/config.yml``` and replace all the values
- Run the ```main.rb``` script

Result
======

Assuming you have added two projects (*project_one* and *project_two*) to your config.yml, and *project_one* has 2 instances and *project_two* has 1 instance right now, you will get these two files:

1) SSH Configuration file
```
# You will get a file like this at your <<ssh_config_file>> file
Host project_one_1
  Hostname xxxxx1.compute-1.amazonaws.com
  User ubuntu
  IdentityFile ~/.ssh/keys/keys_one.pem  
  StrictHostKeyChecking no

Host project_one_2
  Hostname xxxxx2.compute-1.amazonaws.com
  User ubuntu
  IdentityFile ~/.ssh/keys/keys_one.pem
  StrictHostKeyChecking no

Host project_two_1
  Hostname xxxxx3.compute-1.amazonaws.com
  User ubuntu
  IdentityFile ~/.ssh/keys/keys_two.pem
  StrictHostKeyChecking no  
```

2) Capistrano Configuration File
```
# You will get a file like this at your <<cap_config_file>> file
sites:
  project_one:
   - project_one_1
   - project_one_2
  project_two:
   - project_two_1
```

From now, you can connect to the instances this way:
```
$ ssh project_one_1
$ ssh project_one_2
$ ssh project_two_1
```

So, you can read this *cap_config_file* and proceed to deploy *project_one* to the instances *project_one_1* and *project_one_2*

Acknowledgment
==============
Thanks to [Felipe Espinoza](https://github.com/fespinoza) who wrote a preliminar version of the *AWSSite Class*.
