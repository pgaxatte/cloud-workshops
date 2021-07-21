Deploy a simple infrastructure with Terraform
=============================================

The goal of this workshop is to deploy a simple infrastructure using terraform.

Environment initialization
--------------------------

Before writing any terraform code, you need to load your ``openrc`` otherwise
terraform will not be able to talk to the OpenStack API

.. warning::

    If at any point of the workshop you see a message of the form:

    .. code::

        Error: One of 'auth_url' or 'cloud' must be specified

    This means your environment is not properly setup and you need to load your
    ``openrc``.


Then, you need to create a directory to put your terraform configuration inside:

.. code:: shell

    $ mkdir /projects/tf-workshop
    $ cd /projects/tf-workshop

Create a keypair and an instance
--------------------------------

Every deployment of OpenStack instances starts with the upload of a keypair to
the API. You can use terraform to do that.

First, create a ``main.tf`` file in the module directory you just created and
put it the keypair definition:

.. code:: terraform

    # Create keypair from your local SSH keypair
    resource openstack_compute_keypair_v2 keypair {
        name       = "tf-sshkey"
        public_key = file("~/.ssh/id_rsa.pub")
    }

This will create a keypair named ``tf-sshkey`` by reading your public key in ``~/.ssh/id_rsa.pub``.

.. note::

    If you did not have an SSH keypair on your machine, refer to the
    :doc:`first workshop on public cloud<../day1/01_manage_instances>`.

Now we add the definition of your first instance by adding the following
code to your configuration in ``main.tf``:

.. code:: terraform

    # Create web1 instance
    resource openstack_compute_instance_v2 web1 {
        name        = "web1"
        image_name  = "Ubuntu 18.04"
        flavor_name = "s1-4"

        # Link to the keypair
        key_pair = openstack_compute_keypair_v2.keypair.name

        # You need to set the name of the network used because you have a private
        # network and OpenStack cannot make the decision for you as to which
        # network to use.
        network {
            # Tells OpenStack this is the interface we use to access the instance
            access_network = true
            name           = "Ext-Net"
        }


        # This parameter configures cloud-init to make all interfaces use DHCP as
        # soon as they come up. This circumvent a bug in Ubuntu 18.04.
        user_data = <<EOF
        #cloud-config
        write_files:
        - content: |
            [Match]
            Name=ens*
            [Network]
            DHCP=ipv4
          path: /etc/systemd/network/ens.network
        runcmd:
        - systemctl restart systemd-networkd
        EOF

        # In case the ID of the image changes (because a new version has been
        # pushed in production with the same name), this will prevent the instance
        # from being rebuilt
        lifecycle {
            ignore_changes = [image_id]
        }
        terraform {
          required_providers {
            openstack = {
              source = "terraform-provider-openstack/openstack"
              version = "1.42.0"
            }
          }

        }
    }


Now you can initialize your terraform module by running:

.. code:: shell

    $ terraform init

The output will include the following lines:

.. code::

    Initializing the backend...

    Initializing provider plugins...
    - Checking for available provider plugins...
    - Downloading plugin for provider "openstack" (terraform-providers/openstack) 1.33.0...

    [...]

    Terraform has been successfully initialized!

    You may now begin working with Terraform. Try running "terraform plan" to see
    any changes that are required for your infrastructure. All Terraform commands
    should now work.

    If you ever set or change modules or backend configuration for Terraform,
    rerun this command to reinitialize your working directory. If you forget, other
    commands will detect it and remind you to do so if necessary.

This shows that terraform is correctly initialized and magically found you need
the openstack provider.

You can safely apply this configuration:

.. code:: shell

    $ terraform apply

This will output the plan of what should be created and ask you if you want to apply it:

.. code::

   An execution plan has been generated and is shown below.
    Resource actions are indicated with the following symbols:
      + create

    Terraform will perform the following actions:

      # openstack_compute_instance_v2.web1 will be created
      + resource "openstack_compute_instance_v2" "web1" {
          + access_ip_v4        = (known after apply)
          + access_ip_v6        = (known after apply)
          + all_metadata        = (known after apply)
          + all_tags            = (known after apply)
          + availability_zone   = (known after apply)
          + flavor_id           = (known after apply)
          + flavor_name         = "s1-4"
          + force_delete        = false
          + id                  = (known after apply)
          + image_id            = (known after apply)
          + image_name          = "Ubuntu 18.04"
          + key_pair            = "tf-sshkey"
          + name                = "web1"
          + power_state         = "active"
          + region              = (known after apply)
          + security_groups     = (known after apply)
          + stop_before_destroy = false

          + network {
              + access_network = false
              + fixed_ip_v4    = (known after apply)
              + fixed_ip_v6    = (known after apply)
              + floating_ip    = (known after apply)
              + mac            = (known after apply)
              + name           = "Ext-Net"
              + port           = (known after apply)
              + uuid           = (known after apply)
            }
        }

      # openstack_compute_keypair_v2.keypair will be created
      + resource "openstack_compute_keypair_v2" "keypair" {
          + fingerprint = (known after apply)
          + id          = (known after apply)
          + name        = "tf-sshkey"
          + private_key = (known after apply)
          + public_key  = <<~EOT
                ssh-rsa [...]
            EOT
          + region      = (known after apply)
        }

    Plan: 2 to add, 0 to change, 0 to destroy.

    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.

      Enter a value:

.. admonition:: Task 1

    Answer ``yes`` and check with the ``openstack server show web1`` command
    that your new instance has been booted.

    Make sure you can connect to it via SSH.

Add a second instance
---------------------

You should be able to duplicate the first instance's configuration to create a second instance.


.. admonition:: Task 2

    Add an identical instance but named ``db1`` (in the name of the resource
    AND in the ``name`` attribute).

    Apply the new configuration.

    Make sure you can connect to it via SSH.


Use variables
-------------

As you can see, you have repeated and hardcoded some information that could be
factored into variables.

Create a new file named ``variables.tf`` and add the following lines to it:

.. code:: terraform

    variable image_name {
      description = "Name of the image to use for the instances"
      type        = string
      default     = "Ubuntu 18.04"
    }

    variable flavor_name {
      description = "Name of the flavor to use for the instances"
      type        = string
      default     = "s1-4"
    }

Modify your ``web1`` configuration in ``main.tf`` to use the variables:

.. code:: terraform

    resource openstack_compute_instance_v2 web1 {
        name        = "web1"
        image_name  = var.image_name
        flavor_name = var.flavor_name
        key_pair    = openstack_compute_keypair_v2.keypair.name
        # ...
    }

.. admonition:: Task 3

    Do the same for the ``db1``, save the files and apply the new configuration.

    **It SHOULD NOT propose any change on the infrastructure**

Link the public network to a data source
----------------------------------------

There is another hardcoded information repeated in both instances: the public
network name.

Since this is a fixed network provided by the OpenStack infrastructure, a good
way to refactor this is to use a ``data`` source and reference it inside the
instances.

Add the following block to ``main.tf``:

.. code:: terraform

    data openstack_networking_network_v2 pubnet {
        name      = "Ext-Net"
        tenant_id = ""
    }

This will create a ``data`` named ``pubnet`` containing the result of the
search for a network named ``Ext-Net`` that is not assigned to any tenant
(OpenStack project).

You must then use it in the instances for the ``name`` attribute of the
``network`` block:

.. code:: terraform

    resource openstack_compute_instance_v2 web1 {
        # ...
        network {
            access_network = true
            name           = data.openstack_networking_network_v2.pubnet.name
        }
        # ...
    }

.. note::

    Notice the reference starts with ``data.``. This prefix would not be present
    if you had referenced another ``resource``.

.. admonition:: Task 4

    Do the same for the ``db1``, save the files and apply the new configuration.

    **It SHOULD still NOT propose any change on the infrastructure**

Add a private network
---------------------

Let's now add a network interface on a private network on both instances.

But first you need to create it. Add these resources to ``main.tf``:

.. code:: terraform

    resource openstack_networking_network_v2 privnet {
        name           = "private-net"
        admin_state_up = "true"
    }

    resource openstack_networking_subnet_v2 privsubnet {
        name            = "private-subnet"
        network_id      = openstack_networking_network_v2.privnet.id
        cidr            = "10.1.0.0/24"
        ip_version      = 4
        dns_nameservers = ["0.0.0.0"]
        enable_dhcp     = true
    }

.. admonition:: Task 5

    On both instances, add a new ``network`` block using a reference to the
    ``privnet`` resource's name.

    Do not add the ``access_network`` attribute for the private network.

    Apply the new configuration.

    Make sure your instances have a private network interface and a private
    IP assigned using ``openstack server list`` for example.

.. admonition:: Task 6

    Connect to each instance and make sure the private interfaces are up and
    configured.

    On one of the instances, ping the other one on its private IP.

.. note::

    If you see this kind of message when connecting to the instances:

    .. code::

        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
        Someone could be eavesdropping on you right now (man-in-the-middle attack)!
        It is also possible that a host key has just been changed.
        The fingerprint for the ECDSA key sent by the remote host is
        SHA256:....
        Please contact your system administrator.
        Add correct host key in /home/student/.ssh/known_hosts to get rid of this message.
        Offending ECDSA key in /home/student/.ssh/known_hosts:2
        remove with:
        ssh-keygen -f "/home/student/.ssh/known_hosts" -R "xxx.xxx.xxx.xxx"
        ECDSA host key for xxx.xxx.xxx.xxx has changed and you have requested strict checking.
        Host key verification failed.

    You can run the proposed ``ssh-keygen -f "/home/student/.ssh/known_hosts"
    -R "xxx.xxx.xxx.xxx"`` command and retry to connect.

.. note::

    This operation caused the recreation of the instances because any change to
    the network interfaces forces a replacement as displayed in the plan.

Use network ports
-----------------

Two problems arise from the current situation:

1. Your public IP addresses just changed and this is not desirable, especially
   if had used DNS to reach these IP addresses.

2. You did not choose your private IP and used some that were automatically
   assigned to you. This will not fit our use case where we already know the
   private addresses we want to use.

The answer to these problems is simple: use ports and assign them to the instances.

Create the private ports
^^^^^^^^^^^^^^^^^^^^^^^^

Let's start with the private one for ``web1``. Add the following resource in ``main.tf``

.. code:: terraform

    resource openstack_networking_port_v2 priv_web1 {
        name           = "private-web1"
        network_id     = openstack_networking_network_v2.privnet.id
        admin_state_up = "true"

        fixed_ip {
            subnet_id  = openstack_networking_subnet_v2.privsubnet.id
            ip_address = "10.1.0.100"
        }
    }

Modify the ``web1`` instance resource to use the port:

.. code:: terraform

    resource openstack_compute_instance_v2 web1 {
        # ...
        network {
            access_network = true
            name           = data.openstack_networking_network_v2.pubnet.name
        }

        # Modify the private network block
        network {
            port = openstack_networking_port_v2.priv_web1.id
        }
        #...
    }

.. admonition:: Task 7

   Create a second private port for ``db1`` on the same model with
   ``10.1.0.101`` as fixed IP address and add it to the instance's
   configuration.

   Apply the configuration. *(This will re-create the instances again)*

Create the public ports
^^^^^^^^^^^^^^^^^^^^^^^

You should be able to do the same operation for the public ports on your own.

.. admonition:: Task 8

   Create the two public ports based on the private ports with the following
   differences:
   - rename the ports and resources
   - adapt the ``network_id`` to reference the public network ``data``
   - remove the ``fixed_ip`` block since you cannot choose a public IP address

   Apply the configuration. *(Guess what, this will re-create the instances again)*

Play with the configuration
---------------------------

You successfully created two instances with reserved port so let's try to break
them and see how terraform behaves.

.. admonition:: Task 9

   Write down the public IP addresses of both instances (``openstack server
   list``).

   Delete both instances with the ``openstack server delete`` command.

   Run ``terraform apply`` again.

.. note::

   Results:

   * Only the instances should be re-created.
   * The instances should spawn the same IP address as before.

Once this is done, proceed to the :doc:`next part <02_ansible_deploy_app>`.
