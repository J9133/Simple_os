; boot.asm
[org 0x7c00]

start:
    mov si, msg
    call print
    xor ax, ax
    mov ss, ax
    mov sp, 0x7c00
    xor ax, ax
    mov ds, ax

    mov ax, 0x0000
    mov es, ax
    mov bx, 0x8000
    mov ah, 0x02
    mov al, 128
    mov ch, 0
    mov cl, 2
    mov dh, 0
    int 0x13

    jmp 0x0000:0x8000

print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print
.done:
    ret

msg db 'bootloader loaded...'
times 510-($-$$) db 0
dw 0xAA55
