cd initramfs

find . | cpio -o -H newc | gzip > ../build/boot/initramfs-mini

cd ../

mkisofs -o alpine-virt-x86-sdcc.iso \
    -b boot/isolinux/isolinux.bin \
    -c boot/isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -J -R -V "ALPINE_VIRT_X86" build
