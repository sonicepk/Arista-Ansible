# Arista-Ansible

This file is taken from the Arista Docker Hub page. The original github page
has been deleted. 

Creating my own version just to have a snap shot as of the 12/6/2019

Original Docker Image
https://hub.docker.com/r/aristanetworks/ansible/Dockerfile

To run an ansible playbook using this image use:
 docker run -it --rm -v $PWD:/home/prod aristanetworks/ansible ansible-playbook
yourplaybook.yaml -i hosts -l some_device -f 70

Help:

docker run -it --rm -v $PWD:/home/prod aristanetworks/ansible /usr/bin/dumb-init --help
dumb-init v1.2.0
Usage: /usr/bin/dumb-init [option] command [[arg] ...]

dumb-init is a simple process supervisor that forwards signals to children.
It is designed to run as PID1 in minimal container environments.

Optional arguments:
   -c, --single-child   Run in single-child mode.
                        In this mode, signals are only proxied to the
                        direct child and not any of its descendants.
   -r, --rewrite s:r    Rewrite received signal s to new signal r before proxying.
                        To ignore (not proxy) a signal, rewrite it to 0.
                        This option can be specified multiple times.
   -v, --verbose        Print debugging information to stderr.
   -h, --help           Print this help message and exit.
   -V, --version        Print the current version and exit.

Full help is available online at https://github.com/Yelp/dumb-init

