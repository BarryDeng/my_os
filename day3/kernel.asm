
SELECTOR_KERNEL_CS	equ	8

; 导入函数和全局变量
extern cstart
extern gdt_ptr

[section .bss]
StackSpace	resb	2*2014
StackTop:

[section .text]	; 代码在此

global _start	; 导出 _start

_start:
	mov	ah, 0Fh				
	mov	al, 'W'
	mov	[gs:((80 * 1 + 39) * 2)], ax	
	
	mov esp, StackTop
	sgdt	[gdt_ptr]
	call cstart
	lgdt	[gdt_ptr]
	jmp	SELECTOR_KERNEL_CS:scinit
	
csinit:
	push	0
	popfd	; Pop top of stack into EFLAGS

	hlt
