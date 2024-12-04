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