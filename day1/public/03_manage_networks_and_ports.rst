Create a private network and use it
===================================

This workshop will help you manage some network resources of the cloud.

You will be dealing with 3 different components:

* **networks** (approximatively) represent the `layer 2
  <https://en.wikipedia.org/wiki/Data_link_layer>`__ in the OSI model
* **subnets** are encapsulated in the networks and carry the `layer 3
  <https://en.wikipedia.org/wiki/Network_layer>`__ information
* **ports** represent the link between an instance and a subnetwork. This is the virtual interface
  and cable connecting the instance to the network.

Pre-requisites
--------------

You need a project with vRack activated and it should already be the case if you are following a guided session.

You also need to have completed at least the :doc:`first course
<01_manage_instances>` and have booted **two** instances.

Create a private network and subnet
-----------------------------------

By default only a public network is provided but some use case require the instances to be connected
on a dedicated private network.

OpenStack provides this functionality and it is implemented at OVH using a technology named vRack.
Without going into the details, vRack provides an isolated network that spans across regions and can
be used to connect any instance and even dedicated servers.

Let's start by simply creating a network which will be an empty envelope carrying very few
information:

.. code:: shell

    openstack network create privnet

This will output some information about the network, for instance:

::

    +---------------------------+--------------------------------------+
    | Field                     | Value                                |
    +---------------------------+--------------------------------------+
    | admin_state_up            | UP                                   |
    | availability_zone_hints   |                                      |
    | availability_zones        |                                      |
    | created_at                | 2019-01-03T17:04:26Z                 |
    | description               |                                      |
    | dns_domain                | None                                 |
    | id                        | 84cad8f5-e07b-412f-982f-4c7f332cdea1 |
    | ipv4_address_scope        | None                                 |
    | ipv6_address_scope        | None                                 |
    | is_default                | None                                 |
    | is_vlan_transparent       | None                                 |
    | mtu                       | 9000                                 |
    | name                      | privnet                              |
    | port_security_enabled     | False                                |
    | project_id                | 88c866...                            |
    | provider:network_type     | vrack                                |
    | provider:physical_network | None                                 |
    | provider:segmentation_id  | 2700                                 |
    | qos_policy_id             | None                                 |
    | revision_number           | 2                                    |
    | router:external           | Internal                             |
    | segments                  | None                                 |
    | shared                    | False                                |
    | status                    | ACTIVE                               |
    | subnets                   |                                      |
    | tags                      |                                      |
    | updated_at                | 2019-01-03T17:04:26Z                 |
    +---------------------------+--------------------------------------+

This will allow the creation of a subnet to define a range of IP that should be used. Here we will
use a /24 IPv4 network which will provide 253 usable addresses:

.. code:: shell

    openstack subnet create \
        --network privnet \
        --subnet-range 10.0.0.0/24 \
        --allocation-pool start=10.0.0.10,end=10.0.0.254 \
        --gateway none \
        --dns-nameserver 0.0.0.0 \
        subnet01

.. note::

    Since this a private network, there is no gateway. Also it is mandatory to add a DNS nameserver
    to ``0.0.0.0`` to prevent the DHCP server to send any unwanted nameserver in the DHCP reply.

The result of this command will look like:

::

    +-------------------+--------------------------------------+
    | Field             | Value                                |
    +-------------------+--------------------------------------+
    | allocation_pools  | 10.0.0.2-10.0.0.254                  |
    | cidr              | 10.0.0.0/24                          |
    | created_at        | 2019-01-03T17:09:20Z                 |
    | description       |                                      |
    | dns_nameservers   | 0.0.0.0                              |
    | enable_dhcp       | True                                 |
    | gateway_ip        | None                                 |
    | host_routes       |                                      |
    | id                | cc7a966e-8f39-44d0-b067-cd191bb07ac6 |
    | ip_version        | 4                                    |
    | ipv6_address_mode | None                                 |
    | ipv6_ra_mode      | None                                 |
    | name              | subnet01                             |
    | network_id        | 84cad8f5-e07b-412f-982f-4c7f332cdea1 |
    | project_id        | 88c866...                            |
    | revision_number   | 2                                    |
    | segment_id        | None                                 |
    | service_types     |                                      |
    | subnetpool_id     | None                                 |
    | tags              |                                      |
    | updated_at        | 2019-01-03T17:09:20Z                 |
    +-------------------+--------------------------------------+

Now we can take a look at the available networks and see the public network along its subnet(s) and
the newly created private network with the new subnet:

.. code:: shell

    $ openstack network list
    +--------------------------------------+----------+----------------------------------------------------------------------------+
    | ID                                   | Name     | Subnets                                                                    |
    +--------------------------------------+----------+----------------------------------------------------------------------------+
    | 581fad02-...                         | Ext-Net  | 634a92e0-..., 98de7b3b-...                                                 |
    | 84cad8f5-e07b-412f-982f-4c7f332cdea1 | privnet  | cc7a966e-8f39-44d0-b067-cd191bb07ac6                                       |
    +--------------------------------------+----------+----------------------------------------------------------------------------+

Create two VM connected to the public and private network
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Now that we have a private network, we must specify the networks to use with the ``--nic`` option.

We can use the following command to create 2 new VM in one shot with a connection to both networks
(notice the ``--min`` and ``--max`` options):

.. code:: shell

    openstack server create \
        --image 'Debian 10' \
        --flavor s1-2 \
        --key-name mykey \
        --nic net-id=581fad02-... \
        --nic net-id=84cad8f5-... \
        --min 2 \
        --max 2 \
        vmpriv

.. note::

    Be sure to replace the net-id arguments with the id of your public network and your private
    network

You should now have 2 new instances named ``vmpriv-XXX``:

.. code:: shell

    $ openstack server list
    +--------------------------------------+------------+--------+------------------------------------------------------------+----------+--------+
    | ID                                   | Name     | Status | Networks                                                  | Image     | Flavor |
    +--------------------------------------+------------+--------+------------------------------------------------------------+----------+--------+
    | 2040e150-ae5b-4b51-a218-36ca7f600784 | vmpriv-2 | ACTIVE | Ext-Net=2001:xxx::yyy, 51.XXX.YYY.ZZZ; privnet=10.0.0.168 | Debian 10 | s1-2   |
    | 4bd6c328-ff7c-4577-8df5-ff749d25b4e6 | vmpriv-1 | ACTIVE | Ext-Net=2001:xxx::yyy, 51.XXX.YYY.ZZZ; privnet=10.0.0.197 | Debian 10 | s1-2   |
    +--------------------------------------+------------+--------+------------------------------------------------------------+----------+--------+

As you can see the 2 VM have a public and a private IPv4 address.

Let's verify that the instances can see each other on the private network:

.. code:: shell

    # With the public IP address of vmpriv-1
    $ ssh debian@XXX.XXX.XXX.XXX
    [...]
    debian@vmpriv-1:~$

    # Once connected to the instance let's install nmap to check the surrounding network
    debian@vmpriv-1:~$ sudo apt-get update -y && sudo apt-get install -y nmap
    [...]

    # Run a ping scan on the entire private network
    debian@vmpriv-1:~$ sudo nmap -sP 10.0.0.0/24

    Starting Nmap 7.40 ( https://nmap.org ) at 2019-01-07 19:21 UTC
    Nmap scan report for 10.0.0.2
    Host is up (-0.20s latency).
    MAC Address: FA:16:3E:A3:74:8C (Unknown)
    Nmap scan report for 10.0.0.3
    Host is up (-0.15s latency).
    MAC Address: FA:16:3E:E6:5F:F1 (Unknown)
    Nmap scan report for 10.0.0.168
    Host is up (-0.15s latency).
    MAC Address: FA:16:3E:6E:6A:F5 (Unknown)
    Nmap scan report for 10.0.0.197
    Host is up.
    Nmap done: 256 IP addresses (4 hosts up) scanned in 5.95 seconds

It seems that **4** IP addresses have shown up. You can see the two private IP attributed to the
instances along with 2 others.

.. admonition:: Task 1

    Find out what is behind those unexpected IP addresses.

.. note::

    Take a look at the ``ports`` of your project: ``openstack port list`` and ``openstack port
    show`` should help you.

Delete the two VM connected to the private network
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The private network test is done, now is time to remove the two ``vmpriv-XXX`` you just created.


.. admonition:: Task 2

    Delete the ``vmpriv-XXX`` instances.

Hotplug ports
-------------

The same goes for the network ports as for the volumes: instead of unplugging an external hard-drive
from one machine to plug it to another, just imagine you unplug a network card and its cable and
plug it back into another machine.

The advantage of creating a network port separately is that a port will have an IP address
permanently assigned to it on creation. So if you remove the instance, you still keep the IP address
on the port which is left after the deletion of the instance.

Create a port
^^^^^^^^^^^^^

So let's add a private port with an IP address that we choose beforehand: ``10.0.0.100``.

To create the port you will need the subnet and network id of the private network so first you
should run:

.. code:: shell

    openstack subnet list

Now you can create a new port with a predetermined address:

.. code:: shell

    openstack port create --fixed-ip subnet=cc7a966e-...,ip-address=10.0.0.100 --network 84cad8f5-... priv01

The new port should appear as ``DOWN`` in the list returned by ``openstack port list``.

Plug the port to ``vm01``
^^^^^^^^^^^^^^^^^^^^^^^^^

Let's plug the port we created to the ``vm01`` instance.

First you need the ID of the port you just created. You can find it with the following command:

.. code:: shell

    # To search and display as list:
    openstack port list --fixed-ip ip-address=10.0.0.100

    # Or just select the ID:
    openstack port list -f value -c ID --fixed-ip ip-address=10.0.0.100

Now, using this ID, we can add it to an instance:

.. code:: shell

    openstack server add port vm01 c695b5d8-...

The OS (Debian 10 here) should be able to use the new interface right away by sending a DHCP
request. Let's make sure of it by connecting to ``vm01`` and checking the interface is up and well
configured:

::

    # With the public IP address of vm01
    $ ssh debian@XXX.XXX.XXX.XXX
    [...]
    debian@vm01:~$

    # Check that you see two interfaces (three if you count the loopback...)
    debian@vm01:~$ ip addr show
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
           valid_lft forever preferred_lft forever
        inet6 ::1/128 scope host
           valid_lft forever preferred_lft forever
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        link/ether fa:16:3e:60:92:82 brd ff:ff:ff:ff:ff:ff
        inet 54.37.76.135/32 brd 54.37.76.135 scope global dynamic eth0
           valid_lft 82668sec preferred_lft 82668sec
        inet6 fe80::f816:3eff:fe60:9282/64 scope link
           valid_lft forever preferred_lft forever
    3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        link/ether fa:16:3e:48:41:46 brd ff:ff:ff:ff:ff:ff
        inet6 fe80::f816:3eff:fe48:4146/64 scope link
           valid_lft forever preferred_lft forever

    # If eth1 does not have an IP address, wait a bit until you see one appear.
    debian@vm01:~$ ip a s eth1
    3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        link/ether fa:16:3e:48:41:46 brd ff:ff:ff:ff:ff:ff
        inet 10.0.0.100/24 brd 10.0.0.255 scope global dynamic eth1
           valid_lft 86398sec preferred_lft 86398sec
        inet6 fe80::f816:3eff:fe48:4146/64 scope link
           valid_lft forever preferred_lft forever

    # (yeah you can abbreviate the ip commands...)

You can proceed to do the following things:

.. admonition:: Task 3

    Connect to ``vm01`` and check you can now ping another IP address on the private network

.. note::

    You should already know there are two other addresses and you should be able to ping them both

Move the port to another VM
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Just for fun, let's now detach the private port of ``vm01`` and attach it to ``vm02``.

So first you need to remove the port from ``vm01``:

.. code:: shell

    openstack server remove port vm01 c695b5d8-...

Check that the port is still there with a status ``DOWN``:

.. code:: shell

    openstack port show c695b5d8-...

We can finally re-attach the port to ``vm02``:

.. code:: shell

    openstack server add port vm02 c695b5d8-...

A quick look at the instance should confirm the port is connected:

.. code:: shell

    openstack server show vm02

You should be able to complete the following tasks on your own:

.. admonition:: Task 4

    Connect to ``vm02`` and check that you got an IP address on the private network as previously on ``vm01``

.. admonition:: Task 5

    Check you can now ping another IP address on the private network from ``vm02``

You're up
---------

To finish this workshop, complete the following:

.. admonition:: Task 6

    Move the port ``priv01`` back on ``vm01``.

.. admonition:: Task 7

    Create a new private port named ``priv02``, with IP address ``10.0.0.101`` and attach it to ``vm02``. Make sure it is up and that ``vm02`` gets an IP address from the DHCP.

.. admonition:: Evaluation

    Connect to **each** instance and run the following command to check you did everything right:

    .. code:: shell

        # From the first VM
        debian@vm01:~$ curl -sL https://{WORKSHOP_SERVER}/check/103 | sh

        # And from the second one
        debian@vm02:~$ curl -sL https://{WORKSHOP_SERVER}/check/103 | sh

Once you are ready, move on to the :doc:`next course <04_deploy_app_manual>`.
