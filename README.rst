What is webserver project?
==========================

It is a bash script that:

* installs basic things you need on linux web server
* configures vim with reasonable minimal set of settings
* installs and configure database servers (mysql, posgtres, mongodb, redis)
* installs nginx
* installs python environment (uwsgi, virtualenv, pipi, py2, py3)

This script does things I need. It is good idea to use it as start point
to write a script for your own purposes.


How to use it?
==============

1) Get some clean debian server. Set up authentication by key::

    ssh-copy-id root@your-server

2) Upload the script::

    scp install.sh root@your-server:/root/

3) Log in to VPS as root

4) Check your /etc/apt/sources.list. It should contain jessie (stable) repository.

To speed up apt operations you may choose debian repo mirror close to your
server.  For example, if your server located in Nederlands that has
code NL then you might replace ftp.us.debian.org, if such string exists in
your config, with ftp.nl.debian.org.

Do not forget to add "contrib non-free" components.

Example of original digitalocean sources.list::

    deb http://ftp.nl.debian.org/debian jessie main
    deb http://security.debian.org/ jessie/updates
    
After modification::

    deb http://ftp.nl.debian.org/debian jessie main contrib non-free
    deb http://security.debian.org/ jessie/updates main contrib non-free


5) Update install.sh script. Change INSTALL_* variables to allow or disallow
    installation of specific software.
    
6) Run the script::

    $ bash install.sh

During installation process you'll need to confirm installation of various software packages
(and resolve issues if any).

7) Reboot server.



Documentation?
==============

Read source code :)

Some extra comments in russian could be found here: http://habrahabr.ru/blogs/django/120363/


Feedback?
=========

Create ticket on github http://github.com/lorien/webserver or drop mail to lorien@lorien.name
