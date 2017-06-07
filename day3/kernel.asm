
SELECTOR_KERNEL_CS	equ	8

; 导入函数和全局变量
extern cstart
extern gdt_ptr

[section .bss]
StackSpace	resb	2*1024
StackTop:

[section .text]	; 代码在此

global _start	; 导出 _start

_start:
	mov	esp, StackTop	; 堆栈在 bss 段中

	sgdt	[gdt_ptr]	; cstart() 中将会用到 gdt_ptr
	call	cstart		; 在此函数中改变了gdt_ptr，让它指向新的GDT
	lgdt	[gdt_ptr]	; 使用新的GDT

	jmp	SELECTOR_KERNEL_CS:csinit
	
csinit:
	push	0
	popfd	; Pop top of stack into EFLAGS

	hlt
