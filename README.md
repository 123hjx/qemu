# qemu
## 1. 安装交叉编译器 arm-linux-gnueabi-gcc
- 下载地址：https://releases.linaro.org/components/toolchain/binaries/
- 版本：gcc-linaro-11.2.1-2021.10-x86_64_arm-linux-gnueabihf
- 配置：
``` 下载并解压到 prebuilt 目录    -Jxvf


## 2. 下载busybox
- 下载地址：https://git.busybox.net/busybox/?h=1_34_stable
- 版本：busybox-1_32_1.tar.bz2
- 配置：
``` 下载并解压到 prebuilt 目录    -jxvf
 
## 3. 功能
- 单运行 uboot
  make uboot
- 单运行 kernel
  make busybox
  make rootfs_dir
  make rootfs_bin
  make kernel
- uboot 启动 kernel
  make uboot
  make busybox
  make rootfs_dir
  make kernel
  make sdcard_dir
  make sdcard_disk
- 编译kernel内部ko
  make modules
- 编译定义ko
  make drivers 
