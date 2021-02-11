Puppet-foreman module
-------------
####Description
This module is intended to automate The Foreman installation on CentOS systems. What is does?

- Disables SELinux
- Puts a record into /etc/hosts matching hostname with host IP - in case DNS is not in place
- Installs required repositories
- Downloads and runs the foreman installer
- Optionally can install PuppetDB integration (but doesn't install PuppetDB itself)

The module supports some plugins/gems installation:
- Katello
- r10k
- eyaml
- hiera_vault to use Hashicorp Vault

You can also specify via module options to use existing PostgreSQL instance instead of installing it with The Foreman locally.

The file `data/values.yaml` is the main place to toggle module params.
The file `data/matrix.yaml` describes versions of Puppet, Katello and repos depending of the requested Foreman release.

####Installation steps
                
1. Fresh install of CentOS (Version 7 is tested).

2. Install puppet:
```
yum -y localinstall https://yum.puppet.com/puppet6-release-el-7.noarch.rpm
yum install -y puppet
```

3.  Make sure this directory /etc/puppetlabs/code/modules is in modulepath:
```
puppet config print | grep modulepath
```

4. Clone module into /etc/puppetlabs/code/modules:
```
cd /etc/puppetlabs/code/modules
git clone https://github.com/efoft/puppet-foreman.git foreman
```

5. Make sure puppet can see the foreman module:
```
puppet module list
```

6. Resolve dependencies, the module requires:
```
puppet module install puppetlabs-stdlib -i /etc/puppetlabs/code/modules
puppet module install puppetlabs-puppetserver_gem -i /etc/puppetlabs/code/modules
```

7. Adjust the values in modules's data/values.yaml (consult with doc section in manifests/init.pp):
  - release version
  - foreman UI admin password
  - if to install katello, puppetdb and plugins mentioned in values.yaml
  - if to install embedded PostgreSQL or use existing DB host.

8. Apply foreman module:
```
puppet apply -e "include foreman"
```