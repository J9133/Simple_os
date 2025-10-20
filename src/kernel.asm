[org 0x8000]
section .data
msg db "Kernel loaded!",0
command: times 50 db 0
file_name: times 8 db 0
file_parent_name: times 64 db 0
file_pos: dw 0
file_size: dw 0
file_type: db 0
file_count: dw 0
file_data: times 1024 db 0
file_name_find: times 8 db 0
current_dir: times 64 db 0
folder: times 64 db 0
folder_air: times 64 db 0
folder_axist: times 64 db 0
fx: times 2 db 0
section .text

start:
	cli
	xor ax, ax
	mov ds, ax
	mov si, msg
	call print
	mov ah, 0x00
	mov al, 0x03
	int 0x10
	mov byte [folder], '/'
	mov si, buffer
	call input
	jmp $

file:
    dw '', 0

new_file_table:
    entry0_name: times 8 db 0
    entry0_parent: times 64 db 0
    entry0_start: dw 0
    entry0_size: dw 0
    entry0_type: db 0
    entry0_flags: db 0
    entry0_resv: dw 0

file_table:
    times 1024 db 0

print_file_table:
	mov cx, [file_count]
	cmp cx, 0
	je .done
	mov si, file_table
	.loop:
		push cx
		push si
		mov di, si
		add di, 8
		push si
		mov si, folder
		mov cx, 64
		repe cmpsb
		pop si
		jne .skip
		push si
		push si
		pop di
		mov cx, 8
		.print_name:
			mov al, [di]
			inc di
			cmp al, 0
			je .done_print
			mov ah, 0x0E
			int 0x10
			loop .print_name
		.done_print:
		pop si
		add si, 72
		mov al, [si]
		cmp al, 0
		je .is_folder
		mov ah, 0x0E
		mov al, '.'
		int 0x10
		mov al, 't'
		int 0x10
		mov al, 'x'
		int 0x10
		mov al, 't'
		int 0x10
		jmp .continue
	.is_folder:
		mov ah, 0x0E
		mov al, '/'
		int 0x10
	.continue:
		call new_laen
	.skip:
		pop si
		add si, 80
		pop cx
		loop .loop
	.done:
		ret

get_parent_name:
	xor ax, ax
	xor bx, bx
	.loop:
		mov si, file_table
		mov cx, 80
		mov ax, bx
		mul cx
		add si, ax
		mov di, file_name
		mov cx, 8
		repe cmpsb
		je .found
		inc bx
		cmp bx, [file_count]
		jb .loop
		ret
	.found:
		mov ax, bx
		mov cx, 80
		mul cx
		add ax, 8
		mov si, file_table
		add si, ax
		mov di, file_parent_name
		mov cx, 8
		rep movsb
		ret

get_siz_pos:
	push si
	mov di, file_table
	mov cx, [file_count]
	cmp cx, 0
	je .not_found
	.loop:
		push cx
		push di
		mov cx, 8
		push si
		repe cmpsb
		pop si
		je .found
		pop di
		add di, 80
		pop cx
		loop .loop
	.not_found:
		pop si
		mov word [file_pos], 0
		mov word [file_size], 0
		mov byte [file_type], 0
		ret
	.found:
		pop di
		pop cx
		mov si, di
		add si, 72
		mov ax, [si]
		mov [file_pos], ax
		add si, 2
		mov ax, [si]
		mov [file_size], ax
		add si, 2
		mov al, [si]
		mov [file_type], al
		pop si
		ret

input:
	;call print_file_table_raw
	mov di, command
	mov cx, 50
	xor al, al
	rep stosb
	mov di, buffer
	mov cx, 256
	xor al, al
	rep stosb
	call new_laen
	mov si, file_name
	mov di, file_name_find
	mov cx, 8
	rep movsb
	mov ah, 0x0E
	mov al, 0xDA
	int 0x10
	mov al, 0xC4
	int 0x10
	mov al, '['
	int 0x10
	mov si, folder
	call print
	mov al, ']'
	int 0x10
	call new_laen
	mov al, 0xC0
	int 0x10
	mov al, 0xC4
	int 0x10
	mov al, '>'
	int 0x10
	mov al, ' '
	int 0x10
	mov si, buffer
	mov bx, si
	.wait:
		mov ah, 0
		int 0x16
		cmp al, 13
		je .next
		cmp al, 8
		je .backspace
		mov [si], al
		inc si
		mov ah, 0x0E
		int 0x10
		jmp .wait
	.next:
		mov byte [si], 0
		push si
		mov si, buffer
		mov di, command
		mov cx, 50
		rep movsb
		pop si
		mov si, buffer
		cmp byte [command + 0], 'l'
		jne .mk
		cmp byte [command + 1], 's'
		jne .mk
		cmp byte [command + 2], 0
		je com_ls
		jmp input
	.mk:
		cmp byte [command + 0], 'm'
		jne .cat
		cmp byte [command + 1], 'k'
		jne .cat
		cmp byte [command + 2], 'd'
		je .mkdir
		cmp byte [command + 2], ' '
		je com_mk
		jmp input
	.mkdir:
		cmp byte [command + 3], 'i'
		jne input
		cmp byte [command + 4], 'r'
		jne input
		cmp byte [command + 5], ' '
		je com_mkdir
		jmp input
	.cat:
		cmp byte [command + 0], 'c'
		jne .nano
		cmp byte [command + 1], 'a'
		jne .nano
		cmp byte [command + 2], 't'
		jne .nano
		cmp byte [command + 3], ' '
		je com_cat
		jmp input
	.nano:
		cmp byte [command + 0], 'n'
		jne .clear
		cmp byte [command + 1], 'a'
		jne .clear
		cmp byte [command + 2], 'n'
		jne .clear
		cmp byte [command + 3], 'o'
		jne .clear
		cmp byte [command + 4], ' '
		je com_nano
		jmp input
	.clear:
		cmp byte [command + 0], 'c'
		jne .cd
		cmp byte [command + 1], 'l'
		jne .cd
		cmp byte [command + 2], 'e'
		jne .cd
		cmp byte [command + 3], 'a'
		jne .cd
		cmp byte [command + 4], 'r'
		jne .cd
		je com_clear
		jmp .cd
	.cd:
		cmp byte [command + 0], 'c'
		jne .rm
		cmp byte [command + 1], 'd'
		jne .rm
		je com_cd
		jmp input
	.rm:
		cmp byte [command + 0], 'r'
		jne input
		cmp byte [command + 1], 'm'
		jne input
		je com_rm
		jmp input
	.backspace:
		cmp si, bx
		jle .wait
		dec si
		mov ah, 0x0E
		mov al, 8
		int 0x10
		mov al, ' '
		int 0x10
		mov al, 8
		int 0x10
		jmp .wait

com_rm:
	call clear_rig
	mov di, file_name
	mov cx, 8
	xor al, al
	rep stosb
	xor bx, bx
	.get_name:
		mov al, [command + 3 + bx]
		cmp al, ' '
		je .main
		cmp al, 0
		je .main
		mov [file_name + bx], al
		inc bx
		cmp bx, 8
		jl .get_name
	.main:
		call clear_rig
		xor di, di
	.loop:
		cmp cx, [file_count]
		jae .done
		cmp bx, 8
		jae .done_loop
		mov al, [file_table + di]
		cmp al, [file_name + bx]
		jne .done_loop
		inc dx
		inc bx
		inc di
		jmp .loop
	.add_one:
		inc dx
		jmp .loop
	.done_loop:
		cmp dx, 8
		je .found
		xor bx, bx
		xor dx, dx
		inc cx
		mov ax, cx
		mov si, 80
		mul si
		mov di, ax
		jmp .loop
	.found:
		sub di, 8
		mov ax, [file_count]
		sub ax, cx
		push cx
		dec ax
		mov cx, 80
		mul cx
		pop cx
		push ax
		mov ax, cx
		mov bx, 80
		mul bx
		mov di, file_table
		add di, ax
		mov si, di
		add si, 80
		pop ax
		rep movsb
		dec word [file_count]
		call clear_rig
		jmp .done
	.rm_loop:
		
	.done:
		call clear_rig
		jmp input

com_cd:
	xor bx, bx
	mov di, file_name
	mov cx, 8
	xor al, al
	rep stosb
	mov di, file_parent_name
	mov cx, 64
	xor al, al
	rep stosb
	cmp byte [command + 2], 0
	je input
	cmp byte [command + 3], 0
	je input
	cmp byte [command + 3], ' '
	je input
	cmp byte [command + 3], '/'
	je .absolute
	mov di, file_name
	mov si, command
	add si, 3
	xor cx, cx
	.copy_name:
		lodsb
		cmp al, 0
		je .check
		cmp al, ' '
		je .check
		cmp al, '/'
		je .check
		stosb
		inc cx
		cmp cx, 8
		jl .copy_name
	jmp .check
	.absolute:
		mov di, file_name
		mov si, command
		add si, 4
		xor cx, cx
	.copy_abs_name:
		lodsb
		cmp al, 0
		je .check_abs
		cmp al, ' '
		je .check_abs
		cmp al, '/'
		je .check_abs
		stosb
		inc cx
		cmp cx, 8
		jl .copy_abs_name
	.check_abs:
		cmp cx, 0
		je .go_root
		mov di, file_parent_name
		mov cx, 64
		xor al, al
		rep stosb
		mov byte [file_parent_name], '/'
		call check_folder_iroot
		cmp ax, 1
		jne input
		mov di, folder
		xor al, al
		mov cx, 64
		rep stosb
		mov di, folder
		mov byte [di], '/'
		inc di
		mov si, file_name
		mov cx, 8
	.copy_abs_folder:
		lodsb
		cmp al, 0
		je input
		stosb
		loop .copy_abs_folder
		jmp input
	.go_root:
		mov di, folder
		xor al, al
		mov cx, 64
		rep stosb
		mov byte [folder], '/'
		jmp input
	.check:
		mov di, file_parent_name
		mov si, folder
		mov cx, 64
		rep movsb
		call check_folder_iroot
		cmp ax, 1
		jne input
		mov di, folder
		call find_folder_end
		cmp byte [di - 1], '/'
		je .no_slash
		mov al, '/'
		stosb
	.no_slash:
		mov si, file_name
		mov cx, 8
	.copy_to_folder:
		lodsb
		cmp al, 0
		je input
		stosb
		loop .copy_to_folder
		jmp input

check_folder_iroot:
	mov al, [file_name]
	cmp al, 0
	je .not_found
	xor bx, bx
	mov cx, [file_count]
	cmp cx, 0
	je .not_found
	.main_loop:
		push cx
		mov ax, bx
		mov cx, 80
		mul cx
		mov si, file_table
		add si, ax
		mov di, file_name
		mov cx, 8
		push si
		repe cmpsb
		pop si
		jne .next
		add si, 8
		mov di, file_parent_name
		mov cx, 64
		push si
		repe cmpsb
		pop si
		jne .next
		add si, 64
		mov al, [si]
		cmp al, 0
		je .found_folder
		pop cx
		xor ax, ax
		ret
	.found_folder:
		pop cx
		mov ax, 1
		ret
	.next:
		pop cx
		inc bx
		loop .main_loop
	.not_found:
		xor ax, ax
		ret

find_folder_end:
	mov di, folder
	.loop:
		mov al, [di]
		cmp al, 0
		je .done
		inc di
		jmp .loop
	.done:
		ret

com_clear:
	mov ah, 0x00
	mov al, 0x03
	int 0x10
	jmp input

com_cat:
	call new_laen
	mov di, file_name_find
	mov cx, 8
	xor al, al
	rep stosb
	mov si, command
	add si, 4
	mov di, file_name_find
	xor cx, cx
	.copy:
		lodsb
		cmp al, ' '
		je .done_copy
		cmp al, 0
		je .done_copy
		stosb
		inc cx
		cmp cx, 8
		jl .copy
	.done_copy:
		mov si, file_name_find
		call get_siz_pos
		cmp word [file_size], 0
		je .cleanup
		mov si, file_table
		mov cx, [file_count]
		xor bx, bx
	.find_file:
		push cx
		push si
		mov di, file_name_find
		mov cx, 8
		repe cmpsb
		je .check_parent
		pop si
		add si, 80
		pop cx
		inc bx
		loop .find_file
		jmp .cleanup
	.check_parent:
		pop si
		add si, 8
		mov di, folder
		mov cx, 64
		repe cmpsb
		pop cx
		jne .cleanup
		mov si, file_data
		add si, [file_pos]
		mov cx, [file_size]
		call print_size
	.cleanup:
		mov di, file_name_find
		mov cx, 8
		xor al, al
		rep stosb
		mov word [file_pos], 0
		mov word [file_size], 0
		mov byte [file_type], 0
		jmp input

print_size:
    push cx
    push si
	.loop:
		cmp cx, 0
		je .done
		lodsb
		mov ah, 0x0E
		int 0x10
		dec cx
		jmp .loop
	.done:
		pop si
		pop cx
		ret

print_file_table_raw:
	mov bx, [file_count]
	cmp bx, 0
	je .done
	mov si, file_table
	.loop:
		push bx
		mov cx, 80
	.byte_loop:
		push cx
		lodsb
		call print_hex_byte
		mov ah, 0x0E
		mov al, ' '
		int 0x10
		pop cx
		loop .byte_loop
		call new_laen
		pop bx
		dec bx
		jnz .loop
	.done:
		ret
print_hex_byte:
	push ax
	shr al, 4
	call print_hex_nibble
	pop ax
	and al, 0x0F
	call print_hex_nibble
	ret
print_hex_nibble:
	cmp al, 9
	jle .digit
	add al, 'A' - 10
	jmp .print
	.digit:
		add al, '0'
	.print:
		mov ah, 0x0E
		int 0x10
		ret

com_mk:
	mov di, entry0_name
	mov cx, 80
	xor al, al
	rep stosb
	mov di, file_name
	mov cx, 8
	xor al, al
	rep stosb
	mov di, file_parent_name
	mov cx, 64
	xor al, al
	rep stosb
	mov word [file_pos], 0
	mov word [file_size], 0
	mov byte [file_type], 0
	mov si, command
	add si, 3
	mov di, file_name
	xor cx, cx
	.copy_name:
		lodsb
		cmp al, ' '
		je .get_pos
		cmp al, 0
		je .build_entry
		stosb
		inc cx
		cmp cx, 8
		jl .copy_name
	.skip_name:
		lodsb
		cmp al, ' '
		je .get_pos
		cmp al, 0
		je .build_entry
		jmp .skip_name
	.get_pos:
		xor ax, ax
		xor bx, bx
	.pos_loop:
		lodsb
		cmp al, 's'
		je .pos_sector
		cmp al, ' '
		je .get_size
		cmp al, 0
		je .build_entry
		cmp al, '0'
		jl .get_size
		cmp al, '9'
		jg .get_size
		sub al, '0'
		mov bl, al
		mov ax, [file_pos]
		mov dx, 10
		mul dx
		add ax, bx
		mov [file_pos], ax
		jmp .pos_loop
	.pos_sector:
		mov ax, [file_pos]
		mov cx, 512
		mul cx
		mov [file_pos], ax
		jmp .pos_loop
	.get_size:
		xor ax, ax
		xor bx, bx
	.size_loop:
		lodsb
		cmp al, 's'
		je .size_sector
		cmp al, ' '
		je .get_parent
		cmp al, 0
		je .build_entry
		cmp al, '0'
		jl .get_parent
		cmp al, '9'
		jg .get_parent
		sub al, '0'
		mov bl, al
		mov ax, [file_size]
		mov dx, 10
		mul dx
		add ax, bx
		mov [file_size], ax
		jmp .size_loop
	.size_sector:
		mov ax, [file_size]
		mov cx, 512
		mul cx
		mov [file_size], ax
		jmp .size_loop
	.get_parent:
		mov di, file_parent_name
		xor cx, cx
	.copy_parent:
		lodsb
		cmp al, ' '
		je .build_entry
		cmp al, 0
		je .build_entry
		stosb
		inc cx
		cmp cx, 64
		jl .copy_parent
	.skip_parent:
		lodsb
		cmp al, 0
		je .build_entry
		jmp .skip_parent
	.build_entry:
		mov al, [file_parent_name]
		cmp al, 0
		jne .parent_ok
		mov di, file_parent_name
		mov si, folder
		mov cx, 64
		rep movsb
	.parent_ok:
		mov di, entry0_name
		mov si, file_name
		mov cx, 8
		rep movsb
		mov di, entry0_parent
		mov si, file_parent_name
		mov cx, 64
		rep movsb
		mov ax, [file_pos]
		mov [entry0_start], ax
		mov ax, [file_size]
		mov [entry0_size], ax
		mov al, [file_type]
		mov [entry0_type], al
		mov ax, [file_count]
		mov bx, 80
		mul bx
		mov di, file_table
		add di, ax
		mov si, entry0_name
		mov cx, 80
		rep movsb
		inc word [file_count]
		mov di, file_name
		mov cx, 8
		xor al, al
		rep stosb
		mov di, file_parent_name
		mov cx, 64
		xor al, al
		rep stosb
		mov word [file_pos], 0
		mov word [file_size], 0
		mov byte [file_type], 0
		jmp input

com_mkdir:
	mov di, entry0_name
	mov cx, 80
	xor al, al
	rep stosb
	mov di, file_name
	mov cx, 8
	xor al, al
	rep stosb
	mov di, file_parent_name
	mov cx, 64
	xor al, al
	rep stosb
	mov word [file_pos], 0
	mov word [file_size], 0
	mov byte [file_type], 1
	mov si, command
	add si, 6
	mov di, file_name
	xor cx, cx
	.copy_name:
		lodsb
		cmp al, ' '
		je .get_parent
		cmp al, 0
		je .build_entry
		stosb
		inc cx
		cmp cx, 8
		jl .copy_name
	.skip_name:
		lodsb
		cmp al, ' '
		je .get_parent
		cmp al, 0
		je .build_entry
		jmp .skip_name
	.get_parent:
		mov di, file_parent_name
		xor cx, cx
	.copy_parent:
		lodsb
		cmp al, ' '
		je .build_entry
		cmp al, 0
		je .build_entry
		stosb
		inc cx
		cmp cx, 64
		jl .copy_parent
	.skip_parent:
		lodsb
		cmp al, 0
		je .build_entry
		jmp .skip_parent
	.build_entry:
		mov al, [file_parent_name]
		cmp al, 0
		jne .parent_ok
		mov di, file_parent_name
		mov si, folder
		mov cx, 64
		rep movsb
	.parent_ok:
        mov di, entry0_name
        mov si, file_name
        mov cx, 8
        rep movsb
		mov di, entry0_parent
		mov si, file_parent_name
		mov cx, 64
		rep movsb
		mov ax, [file_pos]
		mov [entry0_start], ax
		mov ax, [file_size]
		mov [entry0_size], ax
		mov al, [file_type]
		mov [entry0_type], al
		mov ax, [file_count]
		mov bx, 80
		mul bx
		mov di, file_table
		add di, ax
		mov si, entry0_name
		mov cx, 80
		rep movsb
		inc word [file_count]
		mov di, file_name
		mov cx, 8
		xor al, al
		rep stosb
		mov di, file_parent_name
		mov cx, 64
		xor al, al
		rep stosb
		mov word [file_pos], 0
		mov word [file_size], 0
		mov byte [file_type], 0
		jmp input

com_nano:
	mov di, file_name_find
	mov cx, 8
	xor al, al
	rep stosb
	mov si, command
	add si, 5
	mov di, file_name_find
	xor cx, cx
	.copy_name_check:
		lodsb
		cmp al, ' '
		je .done_name_check
		cmp al, 0
		je .done_name_check
		stosb
		inc cx
		cmp cx, 8
		jl .copy_name_check
	.done_name_check:
		mov si, file_name_find
		call get_siz_pos
		cmp word [file_size], 0
		je .cleanup
		mov si, file_table
		mov cx, [file_count]
		xor bx, bx
	.find_file_check:
		push cx
		push si
		mov di, file_name_find
		mov cx, 8
		repe cmpsb
		je .check_parent
		pop si
		add si, 80
		pop cx
		inc bx
		loop .find_file_check
		jmp .cleanup
	.check_parent:
		pop si
		add si, 8
		mov di, folder
		mov cx, 64
		repe cmpsb
		pop cx
		jne .cleanup
	.start_edit:
		mov di, file_name
		mov cx, 8
		xor al, al
		rep stosb
		mov word [file_pos], 0
		mov word [file_size], 0
		mov bx, 5
		mov di, file_name
	.read_name:
		mov al, [command + bx]
		cmp al, ' '
		je .done_name
		cmp al, 0
		je .done_name
		stosb
		inc bx
		jmp .read_name
	.done_name:
		inc bx
		mov si, file_name
		call get_siz_pos
		mov di, file_data
		add di, [file_pos]
		push di
		mov cx, [file_size]
		xor al, al
		rep stosb
		pop di
		mov si, command
		add si, bx
		mov cx, [file_size]
	.read_data:
		cmp cx, 0
		je .done_data
		lodsb
		cmp al, 0
		je .done_data
		stosb
		dec cx
		jmp .read_data
	.done_data:
		mov di, file_name
		mov cx, 8
		xor al, al
		rep stosb
		mov word [file_pos], 0
		mov word [file_size], 0
		mov byte [file_type], 0
		jmp input
	.cleanup:
		mov di, file_name_find
		mov cx, 8
		xor al, al
		rep stosb
		jmp input

com_ls:
    call new_laen
	call print_file_table
	jmp input

clear_rig:
	xor ax, ax
	mov bx, ax
	mov cx, ax
	mov dx, ax
	mov [fx], ax
	ret

new_laen:
	mov ah, 0x0E
	mov al, 0x0D
	int 0x10
	mov al, 0x0A
	int 0x10
	ret
print:
    lodsb
    test al, al
    jz done
    mov ah, 0x0E
    mov bh, 0
    mov bl, 7
    int 0x10
    jmp print
done:
    ret

section .bss
align 16
buffer: resb 256