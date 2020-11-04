Manage network security
=======================

This workshop will address the management of security groups and rules in your project.

Pre-requisites
--------------

You need to have complete the :doc:`previous course <04_deploy_app_manual>` and
have **two** instances active with a public and a private interface and the
following software deployed:

* ``vm01`` is serving as web frontend running Apache + WordPress on port 80
* ``vm02`` is serving as a database server running MariaDB on port 3306

Both of the instances are also reachable via SSH on port 22.

Principle of operation
----------------------

Each instance's public network port can be protected by a set of rules defined in your project.

.. note::

    Defining security rules on the private network is not (yet) supported at
    OVH as of the writing of this guide.

The main attributes of the rules are:

* direction: ``ingress`` (external → VM) or ``egress`` (VM → external)
* ethertype: ``IPv4`` or ``IPv6``
* protocol: ``icmp``, ``tcp``, ``udp`` or ``None`` for any
* remote IP / remote group: the address or group of addresses you consider as
  external (so the source for ingress traffic or the destination for egress) or
  ``None`` for any
* dst port: destination port for TCP or UDP or ``None`` for any

These security rules are grouped in security groups and security groups are
applied to network ports individually.

Default rules
^^^^^^^^^^^^^

Before digging into how to create new rules and groups, let's take a look at
the default set of rules:

.. code:: shell

    $ openstack security group list
    +--------------------------------------+---------+------------------------+----------------------+
    | ID                                   | Name    | Description            | Project              |
    +--------------------------------------+---------+------------------------+----------------------+
    | 3109510a-15f6-4f4f-9276-0a0fc27fc4f9 | default | Default security group | fc55e5...            |
    +--------------------------------------+---------+------------------------+----------------------+

This shows that there is only one set of rules named ``default``. Let's take a
closer look at this group of rules:

.. code:: shell

    $ openstack security group rule list default
    +--------------------------------------+-------------+----------+------------+-----------------------+
    | ID                                   | IP Protocol | IP Range | Port Range | Remote Security Group |
    +--------------------------------------+-------------+----------+------------+-----------------------+
    | 3153c809-0ce4-41e7-b57b-d6eb85ec50ab | None        | None     |            | None                  |
    | 36ee8479-f113-44d4-b129-3b3c5133f2c4 | None        | None     |            | None                  |
    | 47c47a41-2905-44f9-847e-bb5ea8ef9c33 | None        | None     |            | None                  |
    | fc5552cf-69b1-4659-b40d-6aa74d62cf07 | None        | None     |            | None                  |
    +--------------------------------------+-------------+----------+------------+-----------------------+

Since this is not very helpful, you can query more details:

.. code:: shell

    $ openstack security group rule list default --long
    +--------------------------------------+-------------+----------+------------+-----------+-----------+-----------------------+
    | ID                                   | IP Protocol | IP Range | Port Range | Direction | Ethertype | Remote Security Group |
    +--------------------------------------+-------------+----------+------------+-----------+-----------+-----------------------+
    | 3153c809-0ce4-41e7-b57b-d6eb85ec50ab | None        | None     |            | egress    | IPv4      | None                  |
    | 36ee8479-f113-44d4-b129-3b3c5133f2c4 | None        | None     |            | ingress   | IPv6      | None                  |
    | 47c47a41-2905-44f9-847e-bb5ea8ef9c33 | None        | None     |            | ingress   | IPv4      | None                  |
    | fc5552cf-69b1-4659-b40d-6aa74d62cf07 | None        | None     |            | egress    | IPv6      | None                  |
    +--------------------------------------+-------------+----------+------------+-----------+-----------+-----------------------+

What you should understand from this list is that every kind of traffic is
allowed in any direction for IPv4 and IPv6.

So, by default, there is no filtering but if you remove the default rules, no
traffic will be allowed as the default policy is to block everything and
security rules define what must be allowed.

Create security groups and rules
--------------------------------

Considering the default rules and the way the software was deployed you have
one security problem: MariaDB should not be exposed to the internet.

You can check it is reachable by running the following command using ``vm02``
public IP address:

.. code:: shell

    # With vm02 public IP address

    $ nc -v XXX.XXX.XXX.XXX 3306
    Connection to XXX.XXX.XXX.XXX port 3306 [tcp/*] succeeded!

    # Use <CTRL-C> to interrupt the command

So let's proceed in securing this by creating security groups and rules.

Allow only SSH first
^^^^^^^^^^^^^^^^^^^^

As you saw the default rules allow all traffic to the VM so you need to
remove it from the VM if you want to be able to filter anything.

But before blocking all traffic by removing the default rules, you need
at least a rule that allows SSH connection from everywhere.

So let's create a security group:

.. code:: shell

    $ openstack security group create --description 'Allow SSH from everywhere' allow-ssh
    +-----------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | Field           | Value                                                                                                                                                                      |
    +-----------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | created_at      | 2019-01-10T09:11:55Z                                                                                                                                                       |
    | description     | Allow SSH from everywhere                                                                                                                                                  |
    | id              | 37bbb677-d4a9-4a5b-96d5-abe738ed9386                                                                                                                                       |
    | name            | allow-ssh                                                                                                                                                                  |
    | project_id      | fc55e5...                                                                                                                                                                  |
    | revision_number | 1                                                                                                                                                                          |
    | rules           | created_at='2019-01-10T09:11:55Z', direction='egress', ethertype='IPv4', id='cda87185-428d-4e27-a9e4-a73faeb8068a', revision_number='1', updated_at='2019-01-10T09:11:55Z' |
    |                 | created_at='2019-01-10T09:11:55Z', direction='egress', ethertype='IPv6', id='0c5ad054-34c1-4baf-9455-ba2afa0aae0c', revision_number='1', updated_at='2019-01-10T09:11:55Z' |
    | updated_at      | 2019-01-10T09:11:55Z                                                                                                                                                       |
    +-----------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

The command created a new group but also two rules, let's see what they do:

.. code:: shell

    $ openstack security group rule list allow-ssh --long
    +--------------------------------------+-------------+----------+------------+-----------+-----------+-----------------------+
    | ID                                   | IP Protocol | IP Range | Port Range | Direction | Ethertype | Remote Security Group |
    +--------------------------------------+-------------+----------+------------+-----------+-----------+-----------------------+
    | 0c5ad054-34c1-4baf-9455-ba2afa0aae0c | None        | None     |            | egress    | IPv6      | None                  |
    | cda87185-428d-4e27-a9e4-a73faeb8068a | None        | None     |            | egress    | IPv4      | None                  |
    +--------------------------------------+-------------+----------+------------+-----------+-----------+-----------------------+

These two rules just allow any egress traffic but don't allow ingress so now
you can add some rules to it:

.. code:: shell

    $ openstack security group rule create \
        --description 'Allow SSH in for any IPv4' \
        --ingress \
        --ethertype IPv4 \
        --protocol tcp \
        --dst-port 22 \
        allow-ssh
    +-------------------+--------------------------------------+
    | Field             | Value                                |
    +-------------------+--------------------------------------+
    | created_at        | 2019-01-10T09:38:26Z                 |
    | description       | Allow SSH in for any IPv4            |
    | direction         | ingress                              |
    | ether_type        | IPv4                                 |
    | id                | 1a36e202-de1d-4c75-9ac7-1b7721f9b725 |
    | name              | None                                 |
    | port_range_max    | 22                                   |
    | port_range_min    | 22                                   |
    | project_id        | fc55e5...                            |
    | protocol          | tcp                                  |
    | remote_group_id   | None                                 |
    | remote_ip_prefix  | 0.0.0.0/0                            |
    | revision_number   | 1                                    |
    | security_group_id | 37bbb677-d4a9-4a5b-96d5-abe738ed9386 |
    | updated_at        | 2019-01-10T09:38:26Z                 |
    +-------------------+--------------------------------------+

    # Do the same for IPv6
    $ openstack security group rule create \
        --description 'Allow SSH in for any IPv6' \
        --ingress \
        --ethertype IPv6 \
        --protocol tcp \
        --dst-port 22 \
        allow-ssh
    +-------------------+--------------------------------------+
    | Field             | Value                                |
    +-------------------+--------------------------------------+
    | created_at        | 2019-01-10T09:42:29Z                 |
    | description       | Allow SSH in for any IPv6            |
    | direction         | ingress                              |
    | ether_type        | IPv6                                 |
    | id                | cd7cd1ad-94b2-42ca-9aed-ee2e34b600be |
    | name              | None                                 |
    | port_range_max    | 22                                   |
    | port_range_min    | 22                                   |
    | project_id        | fc55e5...                            |
    | protocol          | tcp                                  |
    | remote_group_id   | None                                 |
    | remote_ip_prefix  | None                                 |
    | revision_number   | 1                                    |
    | security_group_id | 37bbb677-d4a9-4a5b-96d5-abe738ed9386 |
    | updated_at        | 2019-01-10T09:42:29Z                 |
    +-------------------+--------------------------------------+

Check the rules are correct:

.. code:: shell

    $ openstack security group rule list allow-ssh --long
    +--------------------------------------+-------------+-----------+------------+-----------+-----------+-----------------------+
    | ID                                   | IP Protocol | IP Range  | Port Range | Direction | Ethertype | Remote Security Group |
    +--------------------------------------+-------------+-----------+------------+-----------+-----------+-----------------------+
    | 0c5ad054-34c1-4baf-9455-ba2afa0aae0c | None        | None      |            | egress    | IPv6      | None                  |
    | 1d8990da-798b-43db-a022-3e80b06e3859 | tcp         | 0.0.0.0/0 | 22:22      | ingress   | IPv4      | None                  |
    | cd7cd1ad-94b2-42ca-9aed-ee2e34b600be | tcp         | None      | 22:22      | ingress   | IPv6      | None                  |
    | cda87185-428d-4e27-a9e4-a73faeb8068a | None        | None      |            | egress    | IPv4      | None                  |
    +--------------------------------------+-------------+-----------+------------+-----------+-----------+-----------------------+

Now let's apply this group to ``vm01`` and ``vm02`` and remove the default
group from it:

.. code:: shell

    $ openstack server add security group vm01 allow-ssh
    $ openstack server add security group vm02 allow-ssh

    $ openstack server remove security group vm01 default
    $ openstack server remove security group vm02 default

    # Check the changes are applied to the VM
    $ openstack server show vm01 -c security_groups
    +-----------------+------------------+
    | Field           | Value            |
    +-----------------+------------------+
    | security_groups | name='allow-ssh' |
    +-----------------+------------------+

.. admonition:: Task 1

   Test to connect to ``vm01`` and ``vm02`` via SSH and validate it works.

Try to ping the VM and realise it fails and you need to reevaluate your
life choices.

.. admonition:: Task 2

    Create a new group with rules allowing ping (protocol ``icmp``) and add it
    to both instances. Test the ping again to validate.

Allow HTTP
^^^^^^^^^^

You now have two instances reachable by SSH and ping but not by HTTP. Check
that it is indeed the case:

.. code:: shell

    # With the public IP address of vm01
    $ curl http://XXX.XXX.XXX.XXX/
    curl: (7) Failed to connect to XXX.XXX.XXX.XXX port 80: Connection timed out

Let's add a new group and rules for HTTP but limited to specific IPs:

.. code:: shell

    $ openstack security group create --description 'Allow HTTP in' allow-http

    # Find the public IP address of your machine
    $ curl http://ifconfig.ovh/
    YYY.YYY.YYY.YYY

    # Add the rules for HTTP
    $ openstack security group rule create \
        --description 'Allow restricted HTTP in' \
        --ingress \
        --ethertype IPv4 \
        --protocol tcp \
        --dst-port 80 \
        --remote-ip YYY.YYY.YYY.YYY \
        allow-http

.. admonition:: Task 3

    Validate you can now connect to vm01 using HTTP from the bounce server
    (using curl) and verify you cannot connect to it from a different machine
    (using your browser on your workstation).

.. admonition:: Task 4

    Get the public IP of your workstation and add a rule to allow yourself in HTTP.

