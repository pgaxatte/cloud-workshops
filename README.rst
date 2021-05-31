Build the docs
==============

You need ``make`` in either scenarios, so first:

.. code:: shell

    # On Debian based systems:
    sudo apt-get install make

Build locally using pip
-----------------------

First, install the python3 dependencies:

.. code:: shell

    # On Debian based systems:
    sudo apt-get install python3 python3-pip python3-setuptools python3-virtualenv python3-wheel


Create a virtualenv and install Sphinx:

.. code:: shell

    python3 -m virtualenv -p /usr/bin/python3 .venv

    source .venv/bin/activate

    pip install -r requirements.txt

Now that's done, you can build the docs:

.. code:: shell

    make html

Serve it locally:

.. code:: shell

    cd _build/html
    python3 -m http.server

Read it `here <http://localhost:8000>`__.

Build the docker image
----------------------

That's easy:

.. code:: shell

    make docker
    docker run -e 127.0.0.1:8080:80 workshop-docs

You can now read the docs `here <http://localhost:8080/>`__.
