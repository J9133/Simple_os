; kernel.asm
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
file_name_find: times 64 db 0
current_dir: times 64 db 0
folder: times 64 db 0
folder_air: times 64 db 0
folder_axist: times 64 db 0
fx: dw 0
command_find: times 64 db 0
temp_command: times 50 db 0
folder_stack: times 64 db 0
folder_stack2: times 64 db 0
path:
	db '/file1'
	times 52 db 0
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
	
	mov si, path
	call get_siz_pos
    add byte [file_count], 3
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
    db 'file1',0,0,0
    db '/',0
    times 62 db 0
    dw 1
    dw 50
    db 0
    db 0
    dw 0

    db 'code',0,0,0,0
    db '/folder',0
    times 56 db 0
    dw 51
    dw 8
    db 0
    db 0
    dw 0

    db 'folder',0,0
    db '/',0
    times 62 db 0
    dw 0
    dw 0
    db 1
    db 0
    dw 0
    times 1600-($-$$) db 0

file_data:
    db 0
	db 'Hello World!'
	times 38 db 0
	db '12345678'
    times 25600-($-$$) db 0

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
	call get_name_path
	mov si, file_parent_name
	call print
	call new_laen
	mov si, file_name
	call print
	mov di, 8
	mov si, 0
	call clear_rig
    mov dx, 16 
	.get_byts:
		mov al, [file_table + di]
		mov si, di
		cmp di, dx
		je .enter_file
		cmp di, [fx]
		je .mcmp_path
		inc di
		jmp .get_byts
	.enter_file:
		cmp cx, [file_count]
		je .end_table
		inc cx
		mov ax, cx
		push cx
		mov cx, 80
		mul cx
		mov [fx], ax
		add word [fx], 8
		mov dx, ax
		add dx, 16
		pop cx
		jmp .get_byts
	.mcmp_path:
		push di
		push bx
		xor bx, bx
		mov di, [fx]
		jmp .cmp_path
	.cmp_path:
		mov al, [file_table + di]
		cmp al, [file_parent_name + bx]
		jne .not_found
		cmp bx, 64
		je .found_path
		inc di
		inc bx
		jmp .cmp_path
	.ecmp_path:
		pop bx
		pop di
		jmp .get_byts
	.not_found:
		pop bx
		pop di
    	jmp .enter_file 
	.end_table:
		ret
	.found_path:
		pop bx
		pop di
		mov ax, cx
		push cx
		mov cx, 80
		mul cx
		pop cx
		mov si, ax
		add si, 72
		mov ax, [file_table + si]
		mov [file_pos], ax
		add si, 2
		mov ax, [file_table + si]
		mov [file_size], ax
		add si, 2
		mov al, [file_table + si]
		mov [file_type], al
		mov si, msg
		call print
		ret

get_name_path:
	call clear_rig
	push si
	.loop:
		mov al, [si]
		cmp al, 0
		je .end_path
		inc si
		jmp .loop
	.end_path:
		mov al, [si]
		cmp al, '/'
		je .pfound_name
		dec si
		jmp .end_path
	.pfound_name:
		pop di
		cmp si, di
		je .mroot_dir
		push di
		mov di, 0
		push si
		inc si
		jmp .mfound_name
	.mroot_dir:
		mov al, 0
		mov di, 0
		jmp .root_dir
	.root_dir:
		cmp di, 8
		je .mroot_dir2
		mov [file_name + di], al
		inc di
		jmp .root_dir
	.mroot_dir2:
		mov al, 0
		mov di, 0
		jmp .root_dir2
	.root_dir2:
		cmp di, 64
		je .root_dir3
		mov [file_parent_name + di], al
		inc di
		jmp .root_dir2
	.root_dir3:
		mov byte [file_parent_name + 0], '/'
		jmp .mroot_dir4
	.mroot_dir4:
		mov al, 0
		mov di, 0
		inc si
		jmp .root_dir4
	.root_dir4:
		cmp di, 9
		je .done
		mov al, [si]
		mov [file_name + di], al
		inc di
		inc si
		jmp .root_dir4
	.mfound_name:
		mov al, 0
		cmp di, 64
		je .m2found_name
		mov [file_name + di], al
		inc di
		jmp .mfound_name
	.m2found_name:
		mov di, 0
		jmp .found_name
	.found_name:
		mov al, [si]
		cmp al, 0
		je .done_name
		mov [file_name + di], al
		inc si
		inc di
		jmp .found_name
	.done_name:
		pop si
		mov di, 0
		mov byte [file_pos], 0
		mov byte [file_size], 0
		jmp .copy_path
	.copy_path:
		mov al, 0
		cmp di, 64
		je .mcp1
		mov [file_parent_name + di], al
		inc di
		jmp .copy_path
	.mcp1:
		pop di
		call clear_rig
		dec si
		jmp .cp1
	.cp1:
		mov al, [di]
		mov [file_parent_name + bx], al
		cmp di, si
		je .done
		inc di
		inc bx
		jmp .cp1
	.done:
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
		je com_cat2
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
		jne .sh
		cmp byte [command + 1], 'm'
		jne .sh
		je com_rm
		jmp input
    .sh:
		cmp byte [command + 0], 's'
		jne input
		cmp byte [command + 1], 'h'
		jne input
		je com_sh
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

com_cat2:
	call com_cat
	jmp input

com_sh:
    call clear_rig
    mov si, command
    add si, 3
    xor di, di
	.copy_name:
		mov al, [si]
		cmp al, 0
		je .done_copy
		cmp al, ' '
		je .done_copy
		mov [file_name_find + di], al
		inc si
		inc di
		jmp .copy_name
	.done_copy:
		call get_file_content
		cmp cx, 0
		je .exit
		xor di, di
	.loop:
		mov al, [si]
		cmp al, 0
		je .exit
		cmp al, '-'
		je .execute_command
		mov [temp_command + di], al
		inc si
		inc di
		jmp .loop
	.execute_command:
		mov byte [temp_command + di], 0
		push si
		push cx
		mov si, temp_command
		mov di, command
		mov cx, 50
		rep movsb
		pop cx
		pop si
		call activ_comand
		push si
		mov di, temp_command
		mov cx, 50
		xor al, al
		rep stosb
		pop si
		xor di, di
		inc si
		jmp .loop
	.exit:
		jmp input

get_file_content:
    xor bx, bx
    mov si, file_table
    mov dx, [file_count]
	.find_file:
		cmp bx, dx
		jae .not_found
		mov di, file_name_find
		mov cx, 8
		repe cmpsb
		jne .next_entry
		mov si, file_table
		add si, bx
		add si, 8
		mov di, folder
		mov cx, 64
		repe cmpsb
		jne .next_entry
		mov si, file_table
		add si, bx
		add si, 72
		mov ax, [si]
		mov [file_pos], ax
		add si, 2
		mov ax, [si]
		mov [file_size], ax
		mov si, file_data
		add si, [file_pos]
		mov di, si
		mov cx, [file_size]
		ret
	.next_entry:
		inc bx
		jmp .find_file
	.not_found:
		xor cx, cx
		ret

activ_comand:
    mov al, [command]
    cmp al, 'l'
    jne check_m
    cmp byte [command+1], 's'
    je com_ls
    jmp check_m

check_m:
    cmp byte [command], 'm'
    jne check_c
    cmp byte [command+1], 'k'
    jne check_c
    cmp byte [command+2], 'd'
    je com_mkdir
    jmp check_c

check_c:
    cmp byte [command], 'c'
    je check_cat_or_clear
    jmp check_n

check_cat_or_clear:
    cmp byte [command+1], 'a'
    je com_cat
    cmp byte [command+1], 'l'
    je com_clear
    jmp check_n

check_n:
    cmp byte [command], 'n'
    jne check_r
    cmp byte [command+1], 'a'
    jne check_r
    cmp byte [command+2], 'n'
    jne check_r
    cmp byte [command+3], 'o'
    je com_nano
    jmp check_r

check_r:
    cmp byte [command], 'r'
    jne check_s
    cmp byte [command+1], 'm'
    je com_rm
    jmp check_s

check_s:
    cmp byte [command], 's'
    jne end_command
    cmp byte [command+1], 'h'
    je com_sh
    jne end_command

end_command:
    jmp com_sh

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
		ret

print_size:
    xor dx, dx
    push cx
    push si
	.loop:
        mov di, dx
		cmp cx, 0
		je .done
		lodsb
		mov ah, 0x0E
		int 0x10
        mov [command_find + di], al
		dec cx
        inc dx
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

print_char:
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
		jmp .cmp_div
	.cmp_div:
		cmp byte [command + 5], '/'
		je .div
		mov di, 0
		call clear_rig
		jmp .nd1
	.nd1:
		cmp bx, 64
		je .mnd2
		mov al, [folder + di]
		mov [folder_stack + di], al
		inc di
		inc bx
		jmp .nd1
	.mnd2:
		mov si, 5
		mov di, 0
		call clear_rig
		jmp .nd2
	.nd2:
		mov al, [command + si]
		cmp al, 0
		je .mnd3
		mov [folder + di], al
		inc si
		inc di
		jmp .nd2
	.mnd3:
		mov si, 0
		mov di, 0
		call clear_rig
		call add_dir
		mov si, folder
		jmp .div
	.div:
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
		jmp .mrefolder
	.cleanup:
		mov di, file_name_find
		mov cx, 8
		xor al, al
		rep stosb
		jmp .mrefolder
	.mrefolder:
		mov si, 0
		mov di, 0
		call clear_rig
		jmp .refolder
	.refolder:
		cmp bx, 64
		je input
		mov al, [folder_stack + di]
		mov [folder + di], al
		inc di
		inc bx
		jmp .refolder

add_dir:
	call clear_rig
	jmp .main
	.main:
		mov si, 0
		mov di, 0
		jmp .loop
	.loop:
		cmp bx, 64
		je .m_loop2
		mov al, [folder + si]
		mov [folder_stack2 + si], al
		inc si
		inc bx
		jmp .loop
	.m_loop2:
		mov si, 0
		mov di, 0
		call clear_rig
		jmp .loop2
	.loop2:
		mov al, [folder_stack + si]
		cmp al, 0
		je .mloop3
		cmp bx, 64
		je .done
		mov [folder + si], al
		inc si
		inc bx
		jmp .loop2
	.mloop3:
		xor si, si
		inc di
		jmp .loop3
	.loop3:
		mov al, [folder_stack2 + si]
		cmp al, 0
		je .done
		cmp bx, 64
		je .done
		mov [folder + di], al
		inc si
		inc di
		inc bx
		jmp .loop3
	.done:	
		ret

com_ls:
	call clear_rig
    call new_laen
	cmp byte [command + 3], 0
	jne .root_dir
	call print_file_table
	jmp input
	.root_dir:
		mov di, 0
		mov si, 0
		jmp .loop
	.loop:
		cmp bx, 64
		je .mloop2
		mov al, [folder + di]
		mov [folder_stack + di], al
		inc di
		inc bx
		jmp .loop
	.mloop2:
		mov di, 0
		mov si, 3
		xor bx, bx
		jmp .loop2
	.loop2:
		cmp bx, 64
		je .print_t
		mov al, [command + si]
		mov [folder + di], al
		inc si
		inc di
		inc bx
		jmp .loop2
	.print_t:
		cmp byte [command + 3], '/'
		jne .m_add_dir
		call print_file_table
		jmp .mrefolder
	.mrefolder:
		mov si, 0
		mov di, 0
		xor bx, bx
		jmp .refolder
	.refolder:
		cmp bx, 64
		je .done
		mov al, [folder_stack + si]
		mov [folder + si], al
		inc si
		inc bx
		jmp .refolder
	.m_add_dir:
		call add_dir
		call print_file_table
		jmp .mrefolder
	.done:
		jmp input

clear_rig:
	xor ax, ax
	mov bx, ax
	mov cx, ax
	mov dx, ax
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