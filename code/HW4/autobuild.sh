# nasm showstr.asm -f elf32 -o ./bin/showstr.o 
# gcc -fno-PIC -march=i386 -m16 -mpreferred-stack-boundary=2 -ffreestanding -c upper.c -o ./bin/upper.o
# ld -m i386pe -s -N ./bin/showstr.o ./bin/upper.o -Ttext 0x7c00 -Tdata 0x7d00 -o ./bin/show.tmp
# objcopy -O binary ./bin/show.tmp ./bin/boot.bin

nasm boost.asm -f bin -o ./bin/boost.bin
nasm fileList.asm -f bin -o ./bin/fileList.bin
nasm kernal.asm -f elf32 -o ./bin/kernal.o
nasm pong.asm -f bin -o ./bin/pong.bin
gcc -fno-PIC -march=i386 -m16 -c -mpreferred-stack-boundary=2 -ffreestanding Commander.c -o ./bin/cmd.o
ld -m i386pe -N -s ./bin/kernal.o ./bin/cmd.o -Ttext 0x100 -Tdata 0x1B00 -o ./bin/kernal.tmp
objcopy -O binary ./bin/kernal.tmp ./bin/kernal.bin
dd if=/dev/zero of=./fnn.flp bs=1474560 count=1
dd if=./bin/boost.bin of=./fnn.flp bs=512 count=1 conv=notrunc
dd if=./bin/kernal.bin of=./fnn.flp bs=512 seek=1 count=17 conv=notrunc
dd if=./bin/fileList.bin of=./fnn.flp bs=512 seek=18 count=1 conv=notrunc
dd if=./bin/pong.bin of=./fnn.flp bs=512 seek=19 count=1 conv=notrunc
dd if=./bin/pong.bin of=./fnn.flp bs=512 seek=20 count=1 conv=notrunc
dd if=./batch.b of=./fnn.flp bs=512 seek=21 count=1 conv=notrunc

cp ./fnn.flp ../../fnn.flp