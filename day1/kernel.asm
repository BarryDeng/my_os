 [section .text]
 
 global _start
 _start:
	mov ah, 0Fh
	mov al, 'W'
	mov [gs:((80 * 20 + 0) * 2)], ax
	
	jmp $