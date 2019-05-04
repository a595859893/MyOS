# nasm showstr.asm -f elf32 -o ./bin/showstr.o 
# gcc -fno-PIC -march=i386 -m16 -mpreferred-stack-boundary=2 -ffreestanding -c upper.c -o ./bin/upper.o
# ld -m i386pe -s -N ./bin/showstr.o ./bin/upper.o -Ttext 0x7c00 -Tdata 0x7d00 -o ./bin/show.tmp
# objcopy -O binary ./bin/show.tmp ./bin/boot.bin

nasm boost.asm -f bin -o ./bin/boost.bin
nasm fileList.asm -f bin -o ./bin/fileList.bin
nasm kernal.asm -f elf32 -o ./bin/kernal.o
nasm pong.asm -f bin -o ./bin/pong.bin
gcc -fno-PIC -march=i386 -m16 -c -mpreferred-stack-boundary=2 -ffreestanding Comprehensive.c -o ./bin/comp.o
ld -m i386pe -N -s ./bin/kernal.o ./bin/comp.o -Ttext 0x100 -Tdata 0x2500 -o ./bin/kernal.tmp
objcopy -O binary ./bin/kernal.tmp ./bin/kernal.bin
dd if=/dev/zero of=./fnn.flp bs=1474560 count=1
dd if=./bin/boost.bin of=./fnn.flp bs=512 count=1 conv=notrunc
dd if=./bin/kernal.bin of=./fnn.flp bs=512 seek=1 count=29 conv=notrunc
dd if=./bin/fileList.bin of=./fnn.flp bs=512 seek=30 count=1 conv=notrunc
dd if=./batch.b of=./fnn.flp bs=512 seek=31 count=1 conv=notrunc
dd if=./bin/pong.bin of=./fnn.flp bs=512 seek=32 count=2 conv=notrunc
dd if=./bin/pong.bin of=./fnn.flp bs=512 seek=34 count=2 conv=notrunc
dd if=./bin/pong.bin of=./fnn.flp bs=512 seek=36 count=2 conv=notrunc
dd if=./bin/pong.bin of=./fnn.flp bs=512 seek=38 count=2 conv=notrunc

cp ./fnn.flp ../../fnn.flp