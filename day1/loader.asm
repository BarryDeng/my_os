
org	0100h
	jmp LABEL_START
	nop

%include	"fat12hdr.inc"
%include	"pm.inc"
%include	"load.inc"

; GDT
; --------------------------------------------------------------------------
LABEL_GDT:	Descriptor	0,	0,	0,
LABEL_DESC_FLAT_C:	Descriptor	0,	0fffffh,	DA_CR | DA_32 | DA_LIMIT_4K		; ��ִ�ж�
LABEL_DESC_FLAT_RW:	Descriptor	0,	0fffffh,	DA_DRW | DA_32 | DA_LIMIT_4K	; ��д��
LABEL_DESC_VIDEO:	Descriptor	0B8000h,	0fffffh,	DA_DRW | DA_DPL3
; --------------------------------------------------------------------------
GdtLen 	equ	$ - LABEL_GDT
GdtPtr	dw	GdtLen							;�ν�
		dd	BaseOfLoaderPhyAddr + LABEL_GDT	;��ַ

; Selector
; --------------------------------------------------------------------------
SelectorFlatC	equ	LABEL_DESC_FLAT_C	- LABEL_GDT
SelectorFlatRW	equ	LABEL_DESC_FLAT_RW	- LABEL_GDT
SelectorVideo	equ	LABEL_DESC_VIDEO	- LABEL_GDT + SA_RPL3
; --------------------------------------------------------------------------

; ��ַ
BaseOfStack	equ	0100h
PageDirBase	equ	100000h	; ҳĿ¼��ʼ��ַ:	1M
PageTblBase	equ	101000h	; ҳ��ʼ��ַ:		1M + 4K

LABEL_START:
	mov ax,	cs
	mov es,	ax
	mov ds,	ax
	mov ss,	ax
	mov sp,	BaseOfStack
	
	mov dh, 0
	call	DispStr
	
; ��Ŀ¼��Ѱ��Kernel.bin
	mov word [wSectorNo], SectorNumOfRootDir
	xor ah, ah
	xor dl, dl
	int 13h
	
LABEL_SEARCH_INT_ROOT_DIR_BEGIN:
	cmp word [wRootDirSizeForLoop], 0
	jz	LABEL_NO_KERNEL
	dec	word [wRootDirSizeForLoop]
	
	;����ReadSector ��ȡax��ʼ�������ŵ�cl����������Ϣ -> es:bx
	mov ax, BaseOfKernelFile
	mov es, ax
	mov bx, OffsetOfkernelFile	;[es:bx]
	mov ax, [wSectorNo]	
	mov cl, 1
	call	ReadSector
	
	mov si, KernelFileName		;[ds:si]
	mov di, OffsetOfkernelFile	;[es:di]
	cld
	mov dx, 10h		
LABEL_SEARCH_FORKERNEL:
	cmp dx, 0
	jz	LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR
	dec dx
	mov cx, 11
LABEL_CMP_FILENAME:
	cmp cx, 0
	jz	LABEL_FOUND
	dec cx
	
	lodsb	;[ds:si] -> al
	cmp al, byte [es:di]
	jz	LABEL_GOON
	jmp	LABEL_DIFFERENT
LABEL_GOON:
	inc di
	jmp LABEL_CMP_FILENAME		
LABEL_DIFFERENT:
	and di, 0FFE0h	;0000 1111 1111 1110B
	
	add di, 20h		;0010 0000B
	mov si, KernelFileName
	jmp LABEL_SEARCH_FORKERNEL
	
LABEL_NO_KERNEL:
	mov dh, 2
	call	DispStr
	jmp	$

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add word [wSectorNo], 1
	jmp LABEL_SEARCH_INT_ROOT_DIR_BEGIN
	
LABEL_FOUND:
	mov ax, RootDirSectors
	and di, 0FFF0h
	
	;����kernel��С
	push	eax
	mov eax, [es:di + 01ch]
	mov dword [dwKernelSize], eax
	pop eax
	
	add di, 01Ah	;di->first Sector
	mov cx, word [es:di]
	push	cx
	add cx, ax
	add cx, DeltaSectorNum	;cl��loader.bin����ʼ������
	
	mov ax, BaseOfKernelFile
	mov es, ax
	mov bx, OffsetOfkernelFile
	mov ax, cx
	
LABEL_GOON_LOADING_FILE:
	;print '.'
	push	ax
	push 	bx
	mov ah, 0Eh
	
	mov al, '.'
	mov ah, 0Fh
	int 10h
	pop bx
	pop ax
	
	mov cl, 1
	call ReadSector
	pop	ax
	call GetFATEntry
	cmp ax, 0FFFh
	jz	LABEL_FILE_LOADED
	push	ax
	mov dx, RootDirSectors
	add ax, dx
	add ax, DeltaSectorNum
	add bx, [BPB_BytsPerSec]
	jmp	LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:	
	call KillMotor
	mov dh, 1
	call DispStr
	
	lgdt	[GdtPtr]
	
	cli
	
	in al, 92h
	or al, 20h
	out 92h, al
	
	mov eax, cr0
	or	eax, 1
	mov cr0, eax
	
	jmp SelectorFlatC:(BaseOfLoaderPhyAddr+LABEL_PM_START)
	
KillMotor:
	push	dx
	mov	dx, 03F2h
	mov	al, 0
	out	dx, al
	pop	dx
	ret
; 32λ�����
[SECTION .s32]

ALIGN 32

[BITS 32]

LABEL_PM_START:
	mov ah, 0Fh
	mov al, 'N'
	mov [gs:((80 * 0 + 20) * 2)], ax
	jmp $
	
;============================================================================
;����
;----------------------------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	; Root Directory ռ�õ�������, ��ѭ���л�ݼ�����.
wSectorNo		dw	0		; Ҫ��ȡ��������
dwKernelSize	dw	0		; �ں˴�С
bOdd			db	0		; ��������ż��
;============================================================================
;�ַ���
;----------------------------------------------------------------------------
KernelFileName		db	"KERNEL  BIN", 0	; 

MessageLength	equ	9
LoadingMessage:	db	"Loading  "; 9�ֽ�, �������ÿո���. ��� 0
Message1		db	"Ready.   "; 9�ֽ�, �������ÿո���. ��� 1
Message2		db	"No KERNEL"; 9�ֽ�, �������ÿո���. ��� 2
;============================================================================


;----------------------------------------------------------------------------
; ������: DispStr
;----------------------------------------------------------------------------
; ����:
;	��ʾһ���ַ���, ������ʼʱ dh ��Ӧ�����ַ������(0-based)
DispStr:
	mov	ax, MessageLength
	mul	dh
	add	ax, LoadingMessage
	mov	bp, ax			; ��
	mov	ax, ds			; �� ES:BP = ����ַ
	mov	es, ax			; ��
	mov	cx, MessageLength	; CX = ������
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 0007h		; ҳ��Ϊ0(BH = 0) �ڵװ���(BL = 07h)
	mov	dl, 0
	add dh, 3
	int	10h			; int 10h
	ret
	
;----------------------------------------------------------------------------
; ������: ReadSector
;----------------------------------------------------------------------------
; ����:
;	�ӵ� ax �� Sector ��ʼ, �� cl �� Sector ���� es:bx ��
ReadSector:
	; -----------------------------------------------------------------------
	; �������������������ڴ����е�λ�� (������ -> �����, ��ʼ����, ��ͷ��)
	; -----------------------------------------------------------------------
	; ��������Ϊ x
	;                           �� ����� = y >> 1
	;       x           �� �� y ��
	; -------------- => ��      �� ��ͷ�� = y & 1
	;  ÿ�ŵ�������     ��
	;                   �� �� z => ��ʼ������ = z + 1
	push	bp
	mov	bp, sp
	sub	esp, 2			; �ٳ������ֽڵĶ�ջ���򱣴�Ҫ����������: byte [bp-2]

	mov	byte [bp-2], cl
	push	bx			; ���� bx
	mov	bl, [BPB_SecPerTrk]	; bl: ����
	div	bl			; y �� al ��, z �� ah ��
	inc	ah			; z ++
	mov	cl, ah			; cl <- ��ʼ������
	mov	dh, al			; dh <- y
	shr	al, 1			; y >> 1 (��ʵ�� y/BPB_NumHeads, ����BPB_NumHeads=2)
	mov	ch, al			; ch <- �����
	and	dh, 1			; dh & 1 = ��ͷ��
	pop	bx			; �ָ� bx
	; ����, "�����, ��ʼ����, ��ͷ��" ȫ���õ� ^^^^^^^^^^^^^^^^^^^^^^^^
	mov	dl, [BS_DrvNum]		; �������� (0 ��ʾ A ��)
.GoOnReading:
	mov	ah, 2			; ��
	mov	al, byte [bp-2]		; �� al ������
	int	13h
	jc	.GoOnReading		; �����ȡ���� CF �ᱻ��Ϊ 1, ��ʱ�Ͳ�ͣ�ض�, ֱ����ȷΪֹ

	add	esp, 2
	pop	bp

	ret
	
;----------------------------------------------------------------------------
; ������: GetFATEntry
;----------------------------------------------------------------------------
; ����:
;	�ҵ����Ϊ ax �� Sector �� FAT �е���Ŀ, ������� ax ��
;	��Ҫע�����, �м���Ҫ�� FAT �������� es:bx ��, ���Ժ���һ��ʼ������ es �� bx
GetFATEntry:
	push	es
	push	bx
	push	ax
	mov	ax, BaseOfKernelFile	; ��
	sub	ax, 0100h				; �� �� BaseOfLoader �������� 4K �ռ����ڴ�� FAT
	mov	es, ax					; ��
	pop	ax
	mov	byte [bOdd], 0
	mov	bx, 3
	mul	bx			; dx:ax = ax * 3
	mov	bx, 2
	div	bx			; dx:ax / 2  ==>  ax <- ��, dx <- ����
	cmp	dx, 0
	jz	LABEL_EVEN
	mov	byte [bOdd], 1
LABEL_EVEN:;ż��
	xor	dx, dx			; ���� ax ���� FATEntry �� FAT �е�ƫ����. ���������� FATEntry ���ĸ�������(FATռ�ò�ֹһ������)
	mov	bx, [BPB_BytsPerSec]
	div	bx			; dx:ax / BPB_BytsPerSec  ==>	ax <- ��   (FATEntry ���ڵ���������� FAT ��˵��������)
					;				dx <- ���� (FATEntry �������ڵ�ƫ��)��
	push	dx
	mov	bx, 0			; bx <- 0	����, es:bx = (BaseOfLoader - 100):00 = (BaseOfLoader - 100) * 10h
	add	ax, SectorNumOfFAT1	; �˾�ִ��֮��� ax ���� FATEntry ���ڵ�������
	mov	cl, 2
	call	ReadSector		; ��ȡ FATEntry ���ڵ�����, һ�ζ�����, �����ڱ߽緢������, ��Ϊһ�� FATEntry ���ܿ�Խ��������
	pop	dx
	add	bx, dx
	mov	ax, [es:bx]
	cmp	byte [bOdd], 1
	jnz	LABEL_EVEN_2
	shr	ax, 4
LABEL_EVEN_2:
	and	ax, 0FFFh

LABEL_GET_FAT_ENRY_OK:

	pop	bx
	pop	es
	ret
;----------------------------------------------------------------------------
