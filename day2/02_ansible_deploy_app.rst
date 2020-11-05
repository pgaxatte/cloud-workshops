Deploy a simple application with Ansible
========================================

In your workdir, you should have a folder named "ansible".

Build your inventory
--------------------

First step to work with Ansible is to define your inventory.

*Note : as we won't use any DNS service or SSH user configuration for this workshop, we will provide some information directly into the Ansible inventory, such as your machines IPs, the user to connect to, and the SSH port to use.*

.. code:: shell

        $ vim inventory/hosts

For this first part, we will work with two machines : *db1* and *web1*.

A first basic attempt would be :

.. code:: shell

        [ema]
        db1 ansible_host=XX.XX.XX.XX ansible_port=XXXXX ansible_user=XXXXX
        web1 ansible_host=XX.XX.XX.XX ansible_port=XXXXX ansible_user=XXXXX

As you can see, we define in the inventory the IP of each machine , the SSH port and the user to connect to. But, the more the machines, the more duplicated information. Let's factorize a little :

.. code:: shell

        [ema]
        db1 ansible_host=XX.XX.XX.XX
        web1 ansible_host=XX.XX.XX.XX

        [ema:vars]
        ansible_port=XXXXX
        ansible_user=XXXXX

Here, every machine from the *ema* group will inherit the *ansible_port* and *ansible_user* variables.

Finally, our machines will have different roles in our infrastructure, so it would be better to split them in more specific groups :

.. code:: shell

        [database_server]
        db1 ansible_host=XX.XX.XX.XX

        [web_server]
        web1 ansible_host=XX.XX.XX.XX

        [ema:children]
        database_server
        web_server

        [ema:vars]
        ansible_port=XXXXX
        ansible_user=XXXXX

When you will execute a playbook against this inventory, it will compute every groups and variables dynamically : that way, you machine *db1*, as part of group *database_server*, is also part of the group *ema*, and then will benefit from the *ema* specific variables.
Adding a new machine in the *database_server* group will make it also benefit from the same variables.

*Note : as you can see, it is easy to build an inventory with Ansible, but it can also become a real puzzle if you have dozens or thousands of machines, splitted in many groups or sub-groups. Building a valid inventory can be difficult, and managing it on a day-to-day basis can lead to mistakes : you will quickly need some automation to build it from a CMDB.*

Now we have our inventory, it's time to test it ! To do so, we will use the *ping* Ansible module, which will try to connect to your machines using the inventory information, and detect if a valid Python environnement is present. In our case, we specify we want to test it against the group *ema* :

.. code:: shell

        $ ansible -m ping ema

If you need to override the user to connect to, you need to use the *-u* parameter ; if you also need to specify a password, you need to use the *-k* parameter (password will be prompted dynamically).

.. code:: shell

        $ ansible -m ping ema -u root -k
        SSH password:

You should have a result like this :

.. code:: shell

        web1 | SUCCESS => {
            "ansible_facts": {
                "discovered_interpreter_python": "/usr/bin/python3"
            },
            "changed": false,
            "ping": "pong"
        }
        db1 | SUCCESS => {
            "ansible_facts": {
                "discovered_interpreter_python": "/usr/bin/python"
            },
            "changed": false,
            "ping": "pong"
        }

Enforce your basic configuration
--------------------------------

Before doing anything else, we will run a basic playbook to ensure our SSH or hostname configuration is valid.

.. code:: shell

        $ vim playbooks/base.yml

.. code:: yaml

        - hosts:
          - ema

          become: yes

          roles:
            - admins
            - ssh
            - hostname

As you can see, this playbook will run against the *ema* group, and use the *admins*, *ssh* and *hostname* roles. You should have a look to them to understand what they do, as **there are 2 missing parts to make them work**.

Admin and SSH key configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The first missing part is related to the *admins* role :

.. code:: shell

        $ vim roles/admins/tasks/main.yml

.. code:: yaml

        [...]

        - name: create unix groups for admin users
          group:
            name: "{{ item.username }}"
          with_items: "{{ admins }}"
          loop_control:
              label: "{{ item.name }}"

        [...]

In this small extract, you can see that this step is looking for a *admins* variable (as well as other steps), but this variable is neither defined in the role nor in a *defaults/main.yml* file. This variable is defined in the *group_vars* folder.

.. code:: shell

        $ vim inventory/group_vars/all/admins

.. code:: yaml

        ---

        admins:

        old_admins:
          - name: Toto
            username: toto
            ssh_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN6z7BUPAKbv2R9NvrfmQN8m/8VVvXXl8sc0L73PYYXi toto@toto-computer"

.. admonition:: Admin username and SSH key configuration

        The *admins* variable is empty : based on the *old_admins* exemple, complete the missing part to create a **student** admin user with **your SSH key**.

When it's done, let's run our playbook (remember to use *-u* and/or *-k* parameters if required) :

.. code:: shell

        $ ansible-playbook playbooks/base.yml -D

        PLAY [ema] *******************************************************************************************

        TASK [Gathering Facts] *******************************************************************************
        ok: [web1]
        ok: [db1]

        TASK [admins : Set specific variables for distributions] *********************************************
        ok: [db1] => (item=~/ansible/roles/admins/vars/default.yml)
        ok: [web1] => (item=~/ansible/roles/admins/vars/default.yml)

        TASK [admins : install sudo] *************************************************************************
        ok: [web1]
        ok: [db1]

        TASK [admins : create unix groups for admin users] ***************************************************
        changed: [db1] => (item=Student)
        changed: [web1] => (item=Student)

        TASK [admins : create unix admin users] **************************************************************
        changed: [db1] => (item=Student)
        changed: [web1] => (item=Student)

        TASK [admins : set unix admin users authorized_keys] *************************************************
        --- before: /home/student/.ssh/authorized_keys
        +++ after: /home/student/.ssh/authorized_keys
        @@ -0,0 +1 @@
        +<mySshKey> Student

        changed: [web1] => (item=Student)
        --- before: /home/student/.ssh/authorized_keys
        +++ after: /home/student/.ssh/authorized_keys
        @@ -0,0 +1 @@
        +<mySshKey> Student

        changed: [db1] => (item=Student)

        TASK [configure sudoers file for admins] *************************************************************
        --- before: /etc/sudoers (content)
        +++ after: /etc/sudoers (content)
        @@ -28,3 +28,4 @@
         # See sudoers(5) for more information on "#include" directives:

         #includedir /etc/sudoers.d
        +student ALL = (ALL) NOPASSWD:ALL

        changed: [db1] => (item=Student)
        --- before: /etc/sudoers (content)
        +++ after: /etc/sudoers (content)
        @@ -28,3 +28,4 @@
         # See sudoers(5) for more information on "#include" directives:

         #includedir /etc/sudoers.d
        +student ALL = (ALL) NOPASSWD:ALL

        changed: [web1] => (item=Student)

        TASK [admins : remove old unix admin users authorized_keys (root)] ***********************************
        ok: [db1] => (item=Toto)
        ok: [web1] => (item=Toto)

        TASK [delete unix users for old admins] **************************************************************
        ok: [web1] => (item=Toto)
        ok: [db1] => (item=Toto)

        TASK [delete unix groups for old admins] *************************************************************
        ok: [web1] => (item=Toto)
        ok: [db1] => (item=Toto)

        TASK [remove old admins from sudoers file] ***********************************************************
        ok: [db1] => (item=Toto)
        ok: [web1] => (item=Toto)

        TASK [create root .ssh directory] ********************************************************************
        --- before
        +++ after
        @@ -1,5 +1,5 @@
         {
        -    "mode": "0755",
        +    "mode": "0750",
             "path": "/root/.ssh",
        -    "state": "absent"
        +    "state": "directory"
         }

        changed: [db1]
        --- before
        +++ after
        @@ -1,5 +1,5 @@
         {
        -    "mode": "0755",
        +    "mode": "0750",
             "path": "/root/.ssh",
        -    "state": "absent"
        +    "state": "directory"
         }

        changed: [web1]

        TASK [ssh : Config SSH daemon] ***********************************************************************
        fatal: [db1]: FAILED! => {"msg": "'ssh_port' is undefined"}
        fatal: [web1]: FAILED! => {"msg": "'ssh_port' is undefined"}

        PLAY RECAP *******************************************************************************************
        db1                        : ok=12   changed=5    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
        web1                       : ok=12   changed=5    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0

Ok, it seems that we have a problem. Our admin user has been created, but now we are stuck at the SSH configuration. Remember when we told there are 2 missing parts in this basic roles ? Here is the second one !

SSH port configuration
^^^^^^^^^^^^^^^^^^^^^^

So, Ansible tells us that a variable *ssh_port* is undefined : we could provide it several ways, but here we will use a *defaults* folder inside the role one.

.. code:: shell

        $ vim roles/ssh/defaults/main.yml

.. admonition:: SSH port configuration

        Fill the main.yml file to provide the required variable to your role.

Once you have provided the missing variable, you can relaunch your playbook :

.. code:: shell

        $ ansible-playbook playbooks/base.yml -D

        PLAY [ema] *******************************************************************************************

        [...]

        RUNNING HANDLER [restart ssh] ************************************************************************
        changed: [web1]
        changed: [db1]

        PLAY RECAP *******************************************************************************************
        db1                        : ok=17   changed=3    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
        web1                       : ok=17   changed=3    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0 

As you can see, as some modification has been applied to the SSH configuration, Ansible applied the according handler and restarted the SSH daemon of each concerned machine. 

.. note::

        Starting from now, you won't be able to connect as *root* anymore. If required, remember to fix your *ansible_user* variable in your inventory to avoid having to specify it manually for each Ansible run.

Toto
