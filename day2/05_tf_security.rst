[Bonus] Deploy security groups
==============================

This small workshop will show you how to create security groups with terraform.

Restrict to SSH only first
--------------------------

As you know, the default rules are set to let in any traffic. So first we need
to allow only SSH. This will replace the default rules with a security group
that has only one rule in it: letting SSH in.

So what this will do is close everything except SSH. We will add HTTP right after.

Let's add the security group and rule for that:

.. code:: terraform

    # Create security group to allow SSH from everywhere
    resource openstack_networking_secgroup_v2 allow_ssh {
      name        = "allow-ssh-from-all"
      description = "Allow SSH from everywhere"
    }

    # Create security rule to allow SSH from all sources
    resource openstack_networking_secgroup_rule_v2 allow_ssh {
      direction         = "ingress"
      ethertype         = "IPv4"
      protocol          = "tcp"
      port_range_min    = 22
      port_range_max    = 22
      remote_ip_prefix  = "0.0.0.0/0"
      security_group_id = openstack_networking_secgroup_v2.allow_ssh.id
    }

You can now apply this to the public ports of all your instances.
To do so, you need to add an ``security_group_ids`` argument to the
``openstack_networking_port_v2`` resources.


For example:

.. code:: terraform

    resource openstack_networking_port_v2 pub_XXX {
      # [...]

      security_group_ids = [
        # Reference to the openstack_networking_secgroup_v2 resource's id
      ]
    }

.. admonition:: Task 1

    Modify all the public port resources to add a link to the ``allow_ssh``
    security group.

Open HTTP for the web server instance
-------------------------------------

Following the example of SSH, you should be able to do this on your own:

.. admonition:: Task 2

    Add a security group and a security rule allowing HTTP from everywhere.

    Add the new security group on the public port of the web server only.

    Apply the configuration and access the website to make sure it works.

Well done, you completed the last workshop of this session!
