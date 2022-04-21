#!/bin/bash
set -e

KVER_MAJOR=5
KVER_MINOR=11
KVER=$KVER_MAJOR.$KVER_MINOR.4
KDIR=$HOME/preemptrt/linux-$KVER
SCRIPTDIR=$HOME/some_scripts

# get vanilla kernel
cd $HOME
mkdir -p preemptrt
cd preemptrt

if [ ! -f linux-$KVER.tar.gz ]; then
    wget https://mirrors.edge.kernel.org/pub/linux/kernel/v$KVER_MAJOR.x/linux-$KVER.tar.gz -O linux-$KVER.tar.gz
fi

if [ ! -d linux-$KVER ]; then
    tar -xf linux-$KVER.tar.gz
fi

# get patch
wget https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt/$KVER_MAJOR.$KVER_MINOR/patch-$KVER-rt11.patch.xz

# patch kernel
cd $KDIR
xzcat ../patch-$KVER-rt11.patch.xz | patch -p1

exit

# clone xenomai 3.2
if [ ! -d xenomai-dovetail ]; then
    git clone --branch v$XENOVER --depth 1 https://source.denx.de/Xenomai/xenomai.git $XENODIR
    cd $XENODIR
    ./scripts/bootstrap
    cd $HOME
fi

# prepare kernel
kernel() {
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
    cd $XENODIR
    ./configure --enable-pshared --enable-tls --enable-dlopen-libs --enable-async-cancel --enable-smp
    make -j8
    sudo make install

    # finish setup
    cd $SCRIPTDIR
    sudo groupadd -f xenomai
    sudo usermod -a -G xenomai $USER
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

# apply cmake patch
cd $HOME
if [ ! -d cmake_xenomai ]; then
    git clone https://github.com/nolange/cmake_xenomai.git
fi

TARGETDIR=/usr/xenomai/lib/cmake/xenomai
sudo mkdir -p $TARGETDIR
cd cmake_xenomai
sudo ./config/install_cmakeconfig.sh --version $XENOVER -- $TARGETDIR

