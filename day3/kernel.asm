
; nasm -f elf -o kernel.o kernel.asm
; ld -s -Ttext 0x30400 -o kernel.bin kernel.o

[section .text]	; 代码在此

global _start	; 导出 _start

_start:
	mov	ah, 0Fh				
	mov	al, 'W'
	mov	[gs:((80 * 1 + 39) * 2)], ax	
	jmp	$
