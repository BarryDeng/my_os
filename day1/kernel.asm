
[section .text]	; �����ڴ�

global _start	; ���� _start

_start:
	mov	ah, 0Fh				
	mov	al, 'W'
	mov	[gs:((80 * 1 + 39) * 2)], ax	
	jmp	$
