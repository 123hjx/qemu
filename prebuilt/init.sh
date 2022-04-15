#!/bin/sh
echo "[$0 $LINENO]"
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs none /dev
mount -t tmpfs none /tmp

MY_MODULES=`ls /lib/modules/`
for i in $MY_MODULES;do
	echo "-------> insmod $i"
	insmod /lib/modules/$i
done

#insmod /lib/modules/example.ko x=1 y=2

/sbin/mdev -s

echo "Now running normal rootfs $0 $LINENO"

/bin/sh
