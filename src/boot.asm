; boot.asm
[org 0x7c00]

start:
    xor ax, ax
    mov ss, ax
    mov sp, 0x7c00
    xor ax, ax
    mov ds, ax
    mov si, msg
    call print

    xor ax, ax
    mov es, ax
    mov bx, 0x8000
    mov ah, 0x02
    mov al, 7
    mov ch, 0
    mov cl, 2
    mov dh, 0
    int 0x13
    jc disk_error
    jmp 0x0000:0x8000

disk_error:
    mov si, err
    call print
    jmp $

print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print
.done:
    ret

msg db "Bootloader loaded...",0
err db "Disk error",0
times 510-($-$$) db 0
dw 0xAA55
