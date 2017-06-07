
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
	mov	ah, 0Fh				
	mov	al, 'W'
	mov	[gs:((80 * 1 + 39) * 2)], ax	
	
	mov	esp, StackTop	; ��ջ�� bss ����

	sgdt	[gdt_ptr]	; cstart() �н����õ� gdt_ptr
	call	cstart		; �ڴ˺����иı���gdt_ptr������ָ���µ�GDT
	lgdt	[gdt_ptr]	; ʹ���µ�GDT

	jmp	SELECTOR_KERNEL_CS:csinit
	
csinit:
	mov	ah, 0Fh				
	mov	al, 'W'
	mov	[gs:((80 * 2 + 39) * 2)], ax	
	push	0
	popfd	; Pop top of stack into EFLAGS

	hlt
