
SELECTOR_KERNEL_CS	equ	8

; ���뺯����ȫ�ֱ���
extern cstart
extern gdt_ptr

[section .bss]
StackSpace	resb	2*1024
StackTop:

[section .text]	; �����ڴ�

global _start	; ���� _start

_start:
	mov	esp, StackTop	; ��ջ�� bss ����

	sgdt	[gdt_ptr]	; cstart() �н����õ� gdt_ptr
	call	cstart		; �ڴ˺����иı���gdt_ptr������ָ���µ�GDT
	lgdt	[gdt_ptr]	; ʹ���µ�GDT

	jmp	SELECTOR_KERNEL_CS:csinit
	
csinit:
	push	0
	popfd	; Pop top of stack into EFLAGS

	hlt
