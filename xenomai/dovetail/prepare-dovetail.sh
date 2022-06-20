#!/bin/bash
set -e

KVER=5.10
KDIR=$HOME/linux-dovetail
XENOVER=3.2.1
XENODIR=$HOME/xenomai-dovetail
SCRIPTDIR=$HOME/src/robot_deployment/xenomai

# clone patched kernel
cd $HOME

# prepare kernel
kernel() {
    cd $HOME
    if [ ! -d linux-dovetail ]; then
        git clone --branch v$KVER.y-dovetail --depth 1 https://source.denx.de/Xenomai/linux-dovetail.git $KDIR
    fi

    $XENODIR/scripts/prepare-kernel.sh --linux=$KDIR --arch=x86

    # copy config
    cp $SCRIPTDIR/config-4.19.89-xeno-ipipe-3.1@com-exp-hhcm $KDIR/.config
    cd $KDIR
    make olddefconfig
    make -j 6 bzImage modules
    sudo make modules_install install
    sudo cp $SCRIPTDIR/dflt_grub /etc/default/grub
    sudo update-grub
}

# compile xenomai
xeno() {
    cd $HOME

    # install dependency
    sudo apt install cmake autogen autoconf libtool
    # clone xenomai 3.2
    if [ ! -d xenomai-dovetail ]; then
        # NOTE SSL hack for GIT
	export GIT_SSL_NO_VERIFY=1
	git config --global http.sslverify false

        git clone --branch v$XENOVER --depth 1 https://source.denx.de/Xenomai/xenomai.git $XENODIR
        cd $XENODIR
        ./scripts/bootstrap
        cd $HOME
    fi

    cd $XENODIR
    ./configure --enable-pshared --enable-tls --enable-dlopen-libs --enable-async-cancel --enable-smp --disable-dependency-tracking
    make -j8
    sudo make install
    
    # apply cmake patch
    cd $HOME
    if [ ! -d cmake_xenomai ]; then
        git clone https://github.com/nolange/cmake_xenomai.git
    fi

    TARGETDIR=/usr/xenomai/lib/cmake/xenomai
    sudo mkdir -p $TARGETDIR
    cd cmake_xenomai
    sudo ./config/install_cmakeconfig.sh --version $XENOVER -- $TARGETDIR

    # finish setup
    cd $SCRIPTDIR
    sudo groupadd -f xenomai
    sudo usermod -a -G xenomai $USER
    # TODO: echo "<gid>" > /sys/module/xenomai/parameters/allowed_group

    echo /usr/xenomai/lib/ > xenomai.conf
    sudo cp -f xenomai.conf /etc/ld.so.conf.d/
    sudo ldconfig
    sudo cp -f /usr/xenomai/etc/udev/rules.d/rtdm.rules /etc/udev/rules.d/
    sudo cp -f /usr/xenomai/etc/udev/rules.d/00-rtnet.rules /etc/udev/rules.d/
    sudo udevadm control --reload-rules
    sudo udevadm trigger
        
    sudo cp ec_xeno3.sh /usr/local/bin
    sudo cp -f xeno.service /lib/systemd/system/
    sudo systemctl enable xeno
    sudo systemctl start xeno || true
    
}

xeno

