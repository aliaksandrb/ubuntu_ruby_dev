Ubuntu Ruby Dev [![Build Status](https://travis-ci.org/aliaksandrb/ubuntu_ruby_dev.svg?branch=master)](https://travis-ci.org/aliaksandrb/ubuntu_ruby_dev)
================

This simple bash script will install common packages used in Ruby/Rails development to your empty Ubuntu machine.


Tested on:
----------

* Ubuntu 14.04.1 LTS x86_64 Desktop Edition (Unity DE)
* Ubuntu 14.04.1 LTS x86_64 Minimal Install (without any DE at all)


How to use:
-----------

Download the script to your machine. Then run:

```sh
$ chmod +x ./ubuntu_ruby_dev.sh
$ ./ubuntu_ruby_dev.sh
```

Enter a password, start installation process and select tools you want to install.

After you can drink a cup of coffee or water, automated installation would take 15-20 minutes (depends on the amount of selected packages and Internet connection speed).


Also revert option is available. (Unless you delete the `ubuntu_ruby_dev_revert.txt` file created during the installation.

Run in the same folder:

```sh
$ ./ubuntu_ruby_dev.sh -r
```

Than it will remove all installed packages.

Processing logs will be available in the same folder in the `ubuntu_ruby_dev.log` file.

Also you can use `-v` (`--verbose`) option to print logs to STDOUT additionaly to the log file.


What is included:
----------------

* bash
* awk
* sed
* grep
* ls
* cp
* tar
* curl
* gunzip
* bunzip2
* git
* vim
* imagemagick
* RVM
* Ruby
* NodeJs
* MySQL
* Postgresql
* Redis
* Ag
* Ctags

By default all packages and utilites comming with latest stable versions, inluding Ruby.


TODO:
-----

- [x] ~~ask everything required at the beggining of execution to allow silent install without user iteraction~~
- [x] ~~add automated testing (at least syntax)~~
- [x] ~~refactor script syntax in accordance with Shellcheck style guides (Travis CI build status)~~
- [x] ~~add 'verbose' option to show what is going on not only in log file~~
- [x] ~~add possibility to choose packages for install rather than install everything~~
- [ ] check already installed tools, upgrade them or do nothing if not needed
- [x] ~~add possibility to install specific Ruby version rather than just latest one~~
- [x] ~~add possibility to select default root password to MySQL rather than empty one~~
- [ ] add possibility to read from external source file for additional packages or commands
- [x] ~~implement more intellegent revert process to uninstall only packages installed by script itself~~
- [x] ~~add post install message with information about installation paths and configuration options~~
- [ ] make revert file dynamicly rather than at the end of execution (than if script falls in middle there would be something already)
- [ ] ?additional automated testing (at least syntax)?


Inspired by:
------------

[thoughtbot OS X laptop script](https://github.com/thoughtbot/laptop)


License:
------------
Copyright (c) [MIT](http://choosealicense.com/licenses/mit/) [2015] [[aliaksandrb](https://github.com/aliaksandrb)]
