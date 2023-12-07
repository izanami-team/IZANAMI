IZANAMI
====

Use Ansible to provision a full-stack MovableType Server

## Description

Build a Movable Type server using Ansible, or build a local development server using Vagrant

## Introduction

* Perl5.36
* Nginx or Apache
* PHP8
* MySQL8
* Let'sEncrypt

## Requirement

* ansible2.2 or later
* Vagrant
   * Mac(Intel) : Virtualbox
   * Mac(Arm) : Parallels("Pro" and "Business" editions only)
   * vagrant-hostmanager

### Supported Server OS

* Amazon Linux 2023 (AL2023)
* Red Hat Enterprise Linux 9 (RHEL9)
* AlmaLinux 9
* Rocky Linux 9

## Install

```bash
$ brew install ansible
$ git clone git@github.com:izanami-team/IZANAMI.git
$ cd IZANAMI
```

### required only for Vagrant
* Install [homebrew](https://brew.sh/ 'Homebrew') beforehand
    * you also need Xcode to install homebrew. You can install Xcode from App Store. 
* Install [Vagrant](https://www.vagrantup.com/ "Vagrant")
* Install Vagrant Plugin
```bash
$ vagrant plugin install vagrant-parallels
$ vagrant plugin install vagrant-hostmanager
```

## Usage


### Local server

```bash
$ vagrant up
```

### Remote server

```bash
$ ansible-playbook -i hosts site.yml -u ec2-user --private-key=~/.ssh/private_key.pem -l severname
```
