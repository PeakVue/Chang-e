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
# 编译mbr
cd src/boot
mkdir -p bin
nasm -o bin/mbr.bin mbr.s
nasm -o bin/loader.bin loader.s

# 复制mbr二进制程序到硬盘
dd if=bin/mbr.bin of=/home/deepin/bochs/bin/hd60M.img bs=512 count=1 seek=0 conv=notrunc
dd if=bin/loader.bin of=/home/deepin/bochs/bin/hd60M.img bs=512 count=4 seek=1 conv=notrunc
cd -
# 启动仿真
/home/deepin/bochs/bin/bochs -f /home/deepin/bochs/bin/bochsrc.disk 
