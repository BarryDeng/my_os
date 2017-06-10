
extern	disp_pos

[SECTION .text]

; 导出函数
global	disp_str
global disp_color_str
global out_byte
global in_byte

; void disp_str(char * info);
disp_str:
	push	ebp
	mov	ebp, esp

	mov	esi, [ebp + 8]	; pszInfo
	mov	edi, [disp_pos]
	mov	ah, 0Fh
.1:
	lodsb
	test	al, al
	jz	.2
	cmp	al, 0Ah	; 是回车吗?
	jnz	.3
	push	eax
	mov	eax, edi
	mov	bl, 160
	div	bl
	and	eax, 0FFh
	inc	eax
	mov	bl, 160
	mul	bl
	mov	edi, eax
	pop	eax
	jmp	.1
.3:
	mov	[gs:edi], ax
	add	edi, 2
	jmp	.1

.2:
	mov	[disp_pos], edi

	pop	ebp
	ret


out_byte:
	mov edx, [esp + 4]	;port
	mov	al,  [esp + 8]	;icw
	out dx, al
	nop
	nop
	ret
	
in_byte:
	mov edx, [esp + 4]
	xor eax, eax
	in al, dx
	nop
	nop
	ret
	

disp_color_str:
	push	ebp
	mov	ebp, esp
	mov esi, [ebp + 8]
	mov edi, [disp_pos]
	mov ah, [ebp + 12]

.1:
	lodsb
	test	al, al
	jz	.2
	cmp	al, 0Ah	; 是回车吗?
	jnz	.3
	push	eax
	mov	eax, edi
	mov	bl, 160
	div	bl
	and	eax, 0FFh
	inc	eax
	mov	bl, 160
	mul	bl
	mov	edi, eax
	pop	eax
	jmp	.1
.3:
	mov	[gs:edi], ax
	add	edi, 2
	jmp	.1

.2:
	mov	[disp_pos], edi

	pop	ebp
	ret