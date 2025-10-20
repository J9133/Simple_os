#!/bin/bash
mkdir -p ./bin
nasm -f bin ./src/boot.asm -o ./bin/boot.bin
nasm -f bin ./src/kernel.asm -o ./bin/kernel.bin
dd if=/dev/zero of=./bin/os.img bs=512 count=8 2>/dev/null
dd if=./bin/boot.bin of=./bin/os.img conv=notrunc 2>/dev/null
dd if=./bin/kernel.bin of=./bin/os.img seek=1 conv=notrunc 2>/dev/null
qemu-system-i386 -drive format=raw,file=./bin/os.img