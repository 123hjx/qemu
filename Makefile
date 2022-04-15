KERNEL_SOURCE :=linux-4.19.237
UBOOT_SOURCE :=u-boot-2018.09
DRIVERS_SOURCE :=drivers
ROOTFS_DIR :=rootfs
SDCARD_DIR :=sdcard
PREBUILT :=prebuilt
BUSYBOX_SOURCE :=$(PREBUILT)/busybox-1.30.1
OUT :=out

MAKE :=make -j8
export ARCH :=arm
export CROSS_COMPILE :=arm-linux-gnueabihf-

all: zImage rootfs_dir drivers sdcard_dir rootfs_bin sdcard_disk uboot

$(OUT):
	mkdir $@

kernel_clean:
	$(MAKE) mrproper -C $(KERNEL_SOURCE)

kernel_config:
	$(MAKE) vexpress_defconfig -C $(KERNEL_SOURCE)
#	$(MAKE) menuconfig -C $(KERNEL_SOURCE)

zImage: kernel_config $(OUT)
	$(MAKE) -C $(KERNEL_SOURCE) bzImage dtbs
	cp $(KERNEL_SOURCE)/arch/arm/boot/zImage $(OUT)/
	cp $(KERNEL_SOURCE)/arch/arm/boot/dts/vexpress-v2p-ca9.dtb $(OUT)/

modules:
	$(MAKE) -C $(KERNEL_SOURCE) modules

.PHONY: drivers
drivers:
	$(MAKE) M=$(DRIVERS_SOURCE) -C $(KERNEL_SOURCE)
	find $(DRIVERS_SOURCE) -name "*.ko" -exec cp \{\} $(ROOTFS_DIR)/home/ \;

drivers_clean:
	find $(DRIVERS_SOURCE) -name "*.o" |xargs rm -f
	find $(DRIVERS_SOURCE) -name "*.ko" |xargs rm -f
	find $(DRIVERS_SOURCE) -name "*.mod.c" |xargs rm -f
	find $(DRIVERS_SOURCE) -name "*.order" |xargs rm -f
	find $(DRIVERS_SOURCE) -name "*.symvers" |xargs rm -f
	find $(DRIVERS_SOURCE) -name "*.cmd" |xargs rm -f
	find $(DRIVERS_SOURCE) -name "*.mod" |xargs rm -f

uboot_clean:
	$(MAKE) mrproper -C $(UBOOT_SOURCE)

uboot_config:
	$(MAKE) -C $(UBOOT_SOURCE) vexpress_ca9x4_defconfig
#	$(MAKE) -C $(UBOOT_SOURCE) menuconfig

uboot: $(OUT) uboot_config
	$(MAKE) -C $(UBOOT_SOURCE)
	cp $(UBOOT_SOURCE)/u-boot $(OUT)/

busybox:
	$(MAKE) -C $(BUSYBOX_SOURCE) clean
	$(MAKE) -C $(BUSYBOX_SOURCE) menuconfig
	$(MAKE) -C $(BUSYBOX_SOURCE) 
	$(MAKE) -C $(BUSYBOX_SOURCE) install

rootfs_dir:
	$(shell if [ -d $(ROOTFS_DIR) ]; then rm -rf $(ROOTFS_DIR); fi)
	cp -r $(BUSYBOX_SOURCE)/_install $(ROOTFS_DIR)/
	cp -p $(PREBUILT)/init.sh $(ROOTFS_DIR)/
	mkdir $(ROOTFS_DIR)/proc
	mkdir $(ROOTFS_DIR)/sys
	mkdir $(ROOTFS_DIR)/dev
	mkdir $(ROOTFS_DIR)/tmp
	mkdir $(ROOTFS_DIR)/home

rootfs_bin: $(OUT)
	genext2fs -U -b 131072 -D $(PREBUILT)/dev.txt -d $(ROOTFS_DIR) $(OUT)/rootfs.bin
	/sbin/tune2fs -j $(OUT)/rootfs.bin
	/sbin/tune2fs -O extents,uninit_bg,dir_index $(OUT)/rootfs.bin

sdcard_dir:
	$(shell if [ -d $(SDCARD_DIR) ]; then rm -rf $(SDCARD_DIR); fi)
	mkdir $(SDCARD_DIR)
	mkdir $(SDCARD_DIR)/kernel
	mkdir $(SDCARD_DIR)/rootfs
	sudo cp $(OUT)/zImage $(SDCARD_DIR)/kernel/
	sudo cp $(OUT)/vexpress-v2*.dtb $(SDCARD_DIR)/kernel/
	sudo cp -raf $(ROOTFS_DIR)/* $(SDCARD_DIR)/rootfs/

loopdev := $(shell losetup -f)

sdcard_disk: $(OUT)
	mkdir p1_kernel p2_rootfs
	dd if=/dev/zero of=$(OUT)/sdcard.disk bs=1M count=1024
	sgdisk -n 0:0:+10M -c 0:kernel $(OUT)/sdcard.disk
	sgdisk -n 0:0:0 -c 0:rootfs $(OUT)/sdcard.disk
	sudo losetup $(loopdev) $(OUT)/sdcard.disk
	sudo partprobe $(loopdev)
	sudo mkfs.ext4 $(loopdev)p1
	sudo mkfs.ext4 $(loopdev)p2
	sudo mount -t ext4 $(loopdev)p1 p1_kernel
	sudo mount -t ext4 $(loopdev)p2	p2_rootfs
	sudo cp -raf $(SDCARD_DIR)/kernel/* p1_kernel
	sudo cp -raf $(SDCARD_DIR)/rootfs/* p2_rootfs
	sudo umount p1_kernel p2_rootfs
	sudo losetup -d $(loopdev)
	rm -rf p1_kernel p2_rootfs

clean: kernel_clean drivers_clean uboot_clean
	rm -fr $(OUT) $(ROOTFS_DIR) $(SDCARD_DIR)
	
