This is a collection of workshops to learn how to use OpenStack on OVH Public Cloud (although it
can be adapted easily to different cloud provider using OpenStack).

The workshops are organized as follows:
1. **Day 1**: simple two-tier application deployment
    - [**01a**](01_simple_app/01a_manage_instances.md): boot an instance, start using it and
        delete it
    - [**01b**](01_simple_app/01b_):
    - [**01c**](01_simple_app/01c_):

# Prerequisites
## For guided labs
Before beginning the workshops, the following elements should have been communicated to you:
- the address of the lab server
- the password of the lab user (named `student`)

### Connect to the container
With this information you can connect to the bounce server:
```shell
ssh student@XXX.XXX.XXX.XXX
```

Follow the instructions by providing a username of your choice.

You are now logged in.

### Load the credentials
Load the credentials contained in the `openrc` file to access your cloud project:
```shell
source openrc
```

> :fireworks: Congratulations you are now ready to use OpenStack and complete the workshops.

If, during the workshop, you see this message:
```
Missing value auth-url required for auth plugin password
```
It probably means you forgot to load your credentials.

## For other usage
For anyone else wanting to try this, you need:
- a valid OVH Public Cloud project
- a user on this project
- an openrc file for this user
- a terminal with the `openstack` CLI installed or use the terminal app integrated in the OVH
manager.

# OpenStack command line interface

OpenStack is a collection of projects providing an API to manage cloud infrastructure. Each project
has its own API but the community maintains a common command line tool able to manage any part of
the API: `openstack`.

The way it works is pretty consistent across projects and it is generally used in this way:
```shell
openstack {resource} {action} [options]
```

Here are some examples which should help you see the pattern:
```shell
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
```

You can discover what actions are available for each resource using:
```
openstack {resource} --help
```

Then you have help on the actions like so:
```
openstack {resource} {action} --help
```
