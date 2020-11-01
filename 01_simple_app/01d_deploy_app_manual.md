This workshop is not about manipulating OpenStack itself but will guide you through the deployment
of a two-tier application using pre-made scripts by installing WordPress on one vm and MariaDB on
the other.

WordPress is the most famous Content Management System, written in PHP. It needs a webserver, which
you will install on the first VM, and a database server (MariaDB here), which you will install on
the second server.


# Pre-requisites

You need to have complete the [previous course](01c_manage_networks_and_ports.md) and have **two**
instances active with a private network. The two instances should have the following features:
- `vm01` has a private port attached with a fixed IP address of `10.0.0.100`
- `vm02` has a private port attached with a fixed IP address of `10.0.0.101`


# Deploy the software manually

You'll start with the database server on `vm02`.

## Install MariaDB on `vm02`

Connect to the `vm02` instance and run the following command:

> You will be asked for **`vm01`** public IP address

```shell
# With the ip of vm02
ssh debian@XXX.XXX.XXX.XXX

# Run the prepared installation script
debian@vm02:~$ curl https://{{WORKSHOP_SERVER}}/01d_mariadb.sh | sudo bash
```


## Install WordPress on `vm01`

Connect to the `vm01` instance and run the following command:
```shell
# With the ip of vm01
ssh debian@XXX.XXX.XXX.XXX

# Run the prepared installation script
debian@vm01:~$ curl https://{{WORKSHOP_SERVER}}/01d_wordpress.sh | sudo bash
```

Now you can browse to the given URL to see the result of the installation.


# Next course

This small course is only here to show you the result of a manual deployment.
Let's head to the [next course](01e_deploy_app_userdata.md) to automate things a bit more.
