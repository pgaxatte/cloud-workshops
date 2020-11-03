Cloud Workshops on OpenStack @OVHcloud
======================================

This is a collection of workshops to learn how to use OpenStack on OVH Public
Cloud (although it can be adapted easily to different cloud provider using
OpenStack).

.. toctree::
   :maxdepth: 1
   :caption: Workshop list:

   day1/index


Introduction
=============


Before beginning the workshops, the following elements should have been communicated to you:

* the address of the lab server
* the password of the lab user (named ``student``)


Connect to the container
------------------------

With this information you can connect to the bounce server:

.. code:: shell

    ssh student@XXX.XXX.XXX.XXX

Follow the instructions by providing a username of your choice.

**You are now logged in.**


Load the credentials
--------------------

Load the credentials contained in the ``openrc`` file to access your cloud project:

.. code:: shell

    source openrc

**Congratulations!** You are now ready to use OpenStack and complete the workshops.


.. warning::
    If, during the workshop, you see this message::

        Missing value auth-url required for auth plugin password

    It probably means you forgot to load your credentials.

Conventions
===========

Throughout the workshop you will encounter blocks of code instructing you to
execute certain commands.

Please pay attention to the prompt (the start of the line):

* The lines starting with a ``#`` are comments:

    .. code:: shell

        # This is a comment, do not execute this

* If there is no prompt at the start of the line or just a single ``$``: you
  must run this command from the bounce server directly

    .. code:: shell

        # This command is to be run from the bounce server:
        echo "This is a test"

        # This one two, without the leading `$`
        $ echo "This is a test"

* If there is a prompt (in the form of ``user@host:~$``): you must run this
  command from the indicated instance

    .. code:: shell

      # This command is to be run from the vm01 instance:
      debian@vm01:~$ echo "Hello from vm01"

      # This command is to be run from the vm02 instance:
      debian@vm02:~$ echo "Hello from vm02"

OpenStack command line interface
================================

OpenStack is a collection of projects providing an API to manage cloud infrastructure. Each project
has its own API but the community maintains a common command line tool able to manage any part of
the API: ``openstack``.

The way it works is pretty consistent across projects and it is generally used in this way:

.. code:: shell

    openstack {resource} {action} [options]

Here are some examples which should help you see the pattern:

.. code:: shell

    # Create a new instance (server)
    openstack server create --flavor=... --key-name=... --image=... NAME

    # Delete a volume
    openstack volume delete NAME
    # or
    openstack volume delete ID

    # List networks
    openstack network list

    # Show the details of a specific instance
    openstack server show NAME
    # or
    openstack server show ID

    # Modify the properties of a specific object container
    openstack container set --property ...=... ID

You can discover what actions are available for each resource using:

.. code:: shell

    openstack {resource} --help

Then you have help on the actions like so:

.. code:: shell

    openstack {resource} {action} --help
