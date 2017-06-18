%include	"sconst.inc"
_NR_get_ticks	equ	0
_NR_read		equ 1
INT_VECTOR_SYS_CALL	equ	0x90

; 导出符号
global	get_ticks
global	read


bits 32
[section .text]

get_ticks:
	mov	eax, _NR_get_ticks
	int	INT_VECTOR_SYS_CALL
	ret

read:
	mov eax, _NR_read
	int INT_VECTOR_SYS_CALL
	ret

