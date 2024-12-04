# os/run.sh
rm -rf ~/bochs/bin/hd60M.img  
rm -rf ~/bochs/bin/hd60M.img.lock

cd /home/deepin/bochs/bin

expect_script=$(cat << 'EOF'
spawn ./bximage
expect "*Please choose one*"
send "1\r"
expect "*Do you want to create a floppy disk image or a hard disk image?*"
send "hd\r"
expect "*What kind of image should I create?*"
send "flat\r"
expect "*Choose the size of hard disk sectors*"
send "512\r"
expect "*Enter the hard disk size in megabytes*"
send "60\r"
expect "*What should be the name of the image?*"
send "hd60M.img\r"
expect eof
EOF
)

echo "$expect_script" > temp.expect
expect temp.expect
rm -rf temp.expect
cd -
# 编译main.c 
# -m32 编译为32位程序
mkdir -p build
gcc -Wall -m32 -c -fno-builtin -fno-stack-protector -W -Wstrict-prototypes -Wmissing-prototypes -o build/main.o src/kernel/main.c
# 链接 
# -melf_i386 链接为elf_i386类型
# -Ttext 0xc0001500 指定入口地址
# -e main 指定入口函数
ld -m elf_i386 -T os.lds -e main build/main.o -o bin/kernel.bin 
# 编译mbr
cd src/boot
nasm -o ../../bin/mbr.bin mbr.s
nasm -o ../../bin/loader.bin loader.s
cd -
# 复制mbr二进制程序到硬盘
dd if=bin/mbr.bin of=/home/deepin/bochs/bin/hd60M.img bs=512 count=1 seek=0 conv=notrunc
dd if=bin/loader.bin of=/home/deepin/bochs/bin/hd60M.img bs=512 count=8 seek=1 conv=notrunc
dd if=bin/kernel.bin of=/home/deepin/bochs/bin/hd60M.img bs=512 count=200 seek=10 conv=notrunc
# 启动仿真
/home/deepin/bochs/bin/bochs -f /home/deepin/bochs/bin/bochsrc.disk 
