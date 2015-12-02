#! /bin/bash

require $JAB/src/bash/hub.sh
require $JAB/src/bash/github.sh

run_these_before_running_this_script () {
    babun shell /bin/bash
    cd ~
    mkdir -p ~/src/python
    git config --global user.name "J Alan Brogan"
    git config --global user.email github@al-got-rhythm.net
    mkdir -p $HUB
    cd $HUB
    git clone $GITHUB/jalanb/dotjab
}

setup_symbols () {
    JAB=$HUB/dotjab
}

checkouts () {
    cd $HUB
    git clone $GITHUB/jalanb/dotsite
    cd dotsite
    python setup.py develop
    cd ..
    git clone $GITHUB/jalanb/what
    git clone $GITHUB/jalanb/kd
    git clone $GITHUB/jalanb/ack2vim
    git clone $GITHUB/jeffkaufman/icdiff.git
}

setup_python () {
    cd $HUB/dotsite
    python setup.py develop
    cd
    pip install pudb
    pip install ipython
    pip install virtualenv
    pip install virtualenvwrapper
}

upgrade_git () {
    cd ~/Downloads
    # For latest release see $GITHUB/git/git/releases
    local GIT_VERSION=2.5.2
    local TARBALL=v${GIT_VERSION}.tar.gz
    wget $GITHUB/git/git/archive/$TARBALL
    tar xvf $TARBALL
    cd git-${GIT_VERSION}
    make configure
    ./configure --prefix=/usr
    # This fails due to lack of the command 'msgfmt'
    # Looks like that should be part of the gettext package
    # Installed that - made no difference
    # make install
    cd ~/Downloads
    rm -rf $TARBALL git-${GIT_VERSION}
}

pact_installations () {
    pact install tcl
    pact install gettext
}

server_installations () {
    bash $JAB/server/linux/make_which.sh
    bash $JAB/server/jab/checkout_jab.sh
}

main () {
    bash $JAB/server/jab/clean_directories
    pact_installations
    upgrade_git
    checkouts
    setup_python
    server_installations
}

setup_symbols
# main
