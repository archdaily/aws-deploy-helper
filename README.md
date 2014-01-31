AWD Deploy Helper
=================

A little ruby lib to ease the deployment to an AWS Auto Scaling Group. It connects to an AWS Elastic Load Balancer, see the current instances and generate the ssh and capistrano config files.

Instructions
============

- Clone this repo in the machine where you are going to execute ``` cap deploy ```
- Rename ```config/config.yml.example``` to ```config/config.yml``` and replace all the values
- Run the ```main.rb``` script and see the two configuration files
