This workshop will guide through the deployment of WordPress + MariaDB using userdata supplied on
boot.

[cloud-init](https://cloudinit.readthedocs.io) is a daemon running on all instances by default. It
enables you to perform some tasks right after boot in order to automate parts of your deployment.

cloud-init can, among many other functionalities, run a script to install the software you
installed earlier manually.

In order to know what to do, cloud-init needs some instructions which you pass to the instance in
the form of a [cloud-config YAML
file](https://cloudinit.readthedocs.io/en/latest/topics/examples.html) and this metadata will be
read by cloud-init's daemon.


# Delete previous instances

Since you can only use cloud-init on boot, you need to start over. Please complete the following tasks:
- :exclamation: **Task 1**: Delete the two instances `vm01` and `vm02`
- :exclamation: **Task 2**: Delete the two volumes `volume01` and `volume02`

> Keep the private ports you will need them


# Create public ports

You will need to know in advance the IP address of the WordPress instance in order to configure
WordPress properly. The best way to do that is to first create public ports to reserve some public
IP addresses and then attach them to the instances.

> Nota bene: it is a best practice to create ports for instances which you intend to use with a DNS
> record.

First, look up the public network's ID:
```shell
openstack network show -c id -f value Ext-Net
```

Create the two public ports for your instances:
```shell
openstack port create --network 581fad02-... pub01
openstack port create --network 581fad02-... pub02
```

> Notice how you don't supply a `--fixed-ip` option as earlier with private ports? This is because
> you can't choose an IP address on the public network, it is given to you by the infrastructure.


# Deploy the software on boot

In order to tell cloud-init what to do, you need to write the userdata that will run the scripts.

## Write the user-data files

The two instances will have different commands to run on boot so you need to create two separate
user-data files.

> to be continued...
