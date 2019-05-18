# nasm showstr.asm -f elf32 -o ./bin/showstr.o 
# gcc -fno-PIC -march=i386 -m16 -mpreferred-stack-boundary=2 -ffreestanding -c upper.c -o ./bin/upper.o
# ld -m i386pe -s -N ./bin/showstr.o ./bin/upper.o -Ttext 0x7c00 -Tdata 0x7d00 -o ./bin/show.tmp
# objcopy -O binary ./bin/show.tmp ./bin/boot.bin

nasm boost.asm -f bin -o ./bin/boost.bin

nasm Kernal.asm -f elf32 -o ./bin/kernal.o
gcc -fno-PIC -march=i386 -m16 -c -mpreferred-stack-boundary=2 -ffreestanding Comprehensive.c -o ./bin/comp.o
ld -m i386pe -N -s ./bin/kernal.o ./bin/comp.o -Ttext 0x100 -Tdata 0x3000 -o ./bin/kernal.tmp

nasm fileList.asm -f bin -o ./bin/fileList.bin
nasm pong.asm -f bin -o ./bin/pong.bin
nasm pong2.asm -f bin -o ./bin/pong2.bin
nasm pong3.asm -f bin -o ./bin/pong3.bin
nasm pong4.asm -f bin -o ./bin/pong4.bin

objcopy -O binary ./bin/kernal.tmp ./bin/kernal.bin
dd if=/dev/zero of=./fnn.flp bs=1474560 count=1
dd if=./bin/boost.bin of=./fnn.flp bs=512 count=1 conv=notrunc
dd if=./bin/kernal.bin of=./fnn.flp bs=512 seek=1 count=72 conv=notrunc
dd if=./bin/fileList.bin of=./fnn.flp bs=512 seek=73 count=1 conv=notrunc
dd if=./batch.b of=./fnn.flp bs=512 seek=74 count=1 conv=notrunc
dd if=./bin/pong.bin of=./fnn.flp bs=512 seek=75 count=2 conv=notrunc
dd if=./bin/pong2.bin of=./fnn.flp bs=512 seek=77 count=2 conv=notrunc
dd if=./bin/pong3.bin of=./fnn.flp bs=512 seek=79 count=2 conv=notrunc
dd if=./bin/pong4.bin of=./fnn.flp bs=512 seek=81 count=2 conv=notrunc

cp ./fnn.flp ../../fnn.flp