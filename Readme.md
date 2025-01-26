# Minimal Alpine Build for web self-contained SDCC compilation

This OS is to be run in a browser to compile SDCC projects with help of a V86 without installing anything.

https://kingofthegrid.com/ide/

How was it made?

* Took linux-virt-6.12.10-r0 from Alpine packages
* Extracted vmlinuz-virt (kernel) into `build/boot/vmlinuz-virt-6.12.10-r0` and initramfs-virt (rootfs)
* Prepared `mkisofs` build - copied kernel into build/boot
* Extracted the initramfs-virt into `initramfs`
* Created build/bool/isolinux/isolinux.cfg

  ```shell
  DEFAULT linux
  LABEL linux
      KERNEL /boot/vmlinuz-virt-6.12.10-r0
      APPEND initrd=/boot/initramfs-mini console=ttyS0 modules=virtio_pci,9p,sr_mod,cdrom,iso9660 rw quiet
  EOF
  ```
* Added files from alpine-minirootfs-3.21.2-x86.tar.gz to `initramfs`.
* Modified `./initramfs/init` to simply load few kernel modules and mount very basic directories.

  ```shell
  # mounts 9p filesystem into /work - virtual machine host can pass files there
  mkdir -p /work
  mount -t 9p -o trans=virtio host9p /work

  # mounts cdrom as sdcc is not part of initramfs 
  modprobe sr_mod
  modprobe cdrom
  mount -t iso9660 /dev/sr0 /media/cdrom
  ```

* Added SDCC to `build/sdcc` - mkisofs adds everything in build folder into an ISO!
* Modified `initramfs/etc/profile` to include `/media/cdrom/sdcc/bin` into search path

* Made `initramfs/bin/autologin` to auto-login the VM:

  ```shell
  #!/bin/sh
  hostname v86
  /bin/login -f root
  ```

* Modified `initramfs/etc/inittab` 

  ```shell
  tty1::respawn:/sbin/getty -n -l /bin/autologin 38400 tty1
  ...
  ttyS0::respawn:/sbin/getty -n -l /bin/autologin -L 115200 ttyS0 vt100
  ```

* Made a scipt that assembles initramfs - so any files you change will be the initramfs

  ```shell
  cd initramfs
  find . | cpio -o -H newc | gzip > ../build/boot/initramfs-mini
  ```

* Then generate the bootable iso
  ```shell
  mkisofs -o alpine-virt-x86-sdcc.iso \
      -b boot/isolinux/isolinux.bin \
      -c boot/isolinux/boot.cat \
      -no-emul-boot -boot-load-size 4 -boot-info-table \
      -J -R -V "ALPINE_VIRT_X86" build
  ```
# How To Assemble

To assemble, run './generate.sh'

## Sources

https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86/alpine-minirootfs-3.21.2-x86.tar.gz

## Kernel

From linux-virt-6.12.10-r0

## Alpine Packages

```
linux-virt-6.12.10-r0.apk
binutils-2.43.1-r1.apk
```

## Test

```shell
mkdir -p ./shared && touch ./shared/test.txt
qemu-system-i386 -cdrom alpine-virt-x86-sdcc.iso -serial stdio -virtfs local,path=./shared,mount_tag=host9p,security_model=none
```
