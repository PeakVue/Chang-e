# os/run.sh

rm -rf ~/bochs/bin/hd60M.img  
rm -rf ~/bochs/bin/hd60M.img.lock
cd /home/deepin/bochs/bin
./bximage
cd -
# 编译mbr
cd src/boot
mkdir bin
nasm -o bin/mbr.bin mbr.s
nasm -o bin/loader.bin loader.s

# 复制mbr二进制程序到硬盘
dd if=bin/mbr.bin of=/home/deepin/bochs/bin/hd60M.img bs=512 count=1 seek=0 conv=notrunc
dd if=bin/loader.bin of=/home/deepin/bochs/bin/hd60M.img bs=512 count=2 seek=1 conv=notrunc
cd -
# 启动仿真
/home/deepin/bochs/bin/bochs -f /home/deepin/bochs/bin/bochsrc.disk 
