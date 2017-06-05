
org	0100h
	jmp LABEL_START
	nop

%include	"fat12hdr.inc"
%include	"pm.inc"
%include	"load.inc"

; GDT
; --------------------------------------------------------------------------
LABEL_GDT:	Descriptor	0,	0,	0,
LABEL_DESC_FLAT_C:	Descriptor	0,	0fffffh,	DA_CR | DA_32 | DA_LIMIT_4K		; 可执行段
LABEL_DESC_FLAT_RW:	Descriptor	0,	0fffffh,	DA_DRW | DA_32 | DA_LIMIT_4K	; 读写段
LABEL_DESC_VIDEO:	Descriptor	0B8000h,	0fffffh,	DA_DRW | DA_DPL3
; --------------------------------------------------------------------------
GdtLen 	equ	$ - LABEL_GDT
GdtPtr	dw	GdtLen							;段界
		dd	BaseOfLoaderPhyAddr + LABEL_GDT	;基址

; Selector
; --------------------------------------------------------------------------
SelectorFlatC	equ	LABEL_DESC_FLAT_C	- LABEL_GDT
SelectorFlatRW	equ	LABEL_DESC_FLAT_RW	- LABEL_GDT
SelectorVideo	equ	LABEL_DESC_VIDEO	- LABEL_GDT + SA_RPL3
; --------------------------------------------------------------------------

; 基址
BaseOfStack	equ	0100h
PageDirBase	equ	100000h	; 页目录开始地址:	1M
PageTblBase	equ	101000h	; 页表开始地址:		1M + 4K

LABEL_START:
	mov ax,	cs
	mov es,	ax
	mov ds,	ax
	mov ss,	ax
	mov sp,	BaseOfStack
	
	mov dh, 0
	call	DispStr
	
; 根目录下寻找Kernel.bin
	mov word [wSectorNo], SectorNumOfRootDir
	xor ah, ah
	xor dl, dl
	int 13h
	
LABEL_SEARCH_INT_ROOT_DIR_BEGIN:
	cmp word [wRootDirSizeForLoop], 0
	jz	LABEL_NO_KERNEL
	dec	word [wRootDirSizeForLoop]
	
	;调用ReadSector 读取ax开始的扇区号的cl个扇区的信息 -> es:bx
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
	
	;保存kernel大小
	push	eax
	mov eax, [es:di + 01ch]
	mov dword [dwKernelSize], eax
	pop eax
	
	add di, 01Ah	;di->first Sector
	mov cx, word [es:di]
	push	cx
	add cx, ax
	add cx, DeltaSectorNum	;cl是loader.bin的起始扇区号
	
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
; 32位代码段
[SECTION .s32]

ALIGN 32

[BITS 32]

LABEL_PM_START:
	mov ah, 0Fh
	mov al, 'N'
	mov [gs:((80 * 0 + 20) * 2)], ax
	jmp $
	
;============================================================================
;变量
;----------------------------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	; Root Directory 占用的扇区数, 在循环中会递减至零.
wSectorNo		dw	0		; 要读取的扇区号
dwKernelSize	dw	0		; 内核大小
bOdd			db	0		; 奇数还是偶数
;============================================================================
;字符串
;----------------------------------------------------------------------------
KernelFileName		db	"KERNEL  BIN", 0	; 

MessageLength	equ	9
LoadingMessage:	db	"Loading  "; 9字节, 不够则用空格补齐. 序号 0
Message1		db	"Ready.   "; 9字节, 不够则用空格补齐. 序号 1
Message2		db	"No KERNEL"; 9字节, 不够则用空格补齐. 序号 2
;============================================================================


;----------------------------------------------------------------------------
; 函数名: DispStr
;----------------------------------------------------------------------------
; 作用:
;	显示一个字符串, 函数开始时 dh 中应该是字符串序号(0-based)
DispStr:
	mov	ax, MessageLength
	mul	dh
	add	ax, LoadingMessage
	mov	bp, ax			; ┓
	mov	ax, ds			; ┣ ES:BP = 串地址
	mov	es, ax			; ┛
	mov	cx, MessageLength	; CX = 串长度
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 0007h		; 页号为0(BH = 0) 黑底白字(BL = 07h)
	mov	dl, 0
	add dh, 3
	int	10h			; int 10h
	ret
	
;----------------------------------------------------------------------------
; 函数名: ReadSector
;----------------------------------------------------------------------------
; 作用:
;	从第 ax 个 Sector 开始, 将 cl 个 Sector 读入 es:bx 中
ReadSector:
	; -----------------------------------------------------------------------
	; 怎样由扇区号求扇区在磁盘中的位置 (扇区号 -> 柱面号, 起始扇区, 磁头号)
	; -----------------------------------------------------------------------
	; 设扇区号为 x
	;                           ┌ 柱面号 = y >> 1
	;       x           ┌ 商 y ┤
	; -------------- => ┤      └ 磁头号 = y & 1
	;  每磁道扇区数     │
	;                   └ 余 z => 起始扇区号 = z + 1
	push	bp
	mov	bp, sp
	sub	esp, 2			; 辟出两个字节的堆栈区域保存要读的扇区数: byte [bp-2]

	mov	byte [bp-2], cl
	push	bx			; 保存 bx
	mov	bl, [BPB_SecPerTrk]	; bl: 除数
	div	bl			; y 在 al 中, z 在 ah 中
	inc	ah			; z ++
	mov	cl, ah			; cl <- 起始扇区号
	mov	dh, al			; dh <- y
	shr	al, 1			; y >> 1 (其实是 y/BPB_NumHeads, 这里BPB_NumHeads=2)
	mov	ch, al			; ch <- 柱面号
	and	dh, 1			; dh & 1 = 磁头号
	pop	bx			; 恢复 bx
	; 至此, "柱面号, 起始扇区, 磁头号" 全部得到 ^^^^^^^^^^^^^^^^^^^^^^^^
	mov	dl, [BS_DrvNum]		; 驱动器号 (0 表示 A 盘)
.GoOnReading:
	mov	ah, 2			; 读
	mov	al, byte [bp-2]		; 读 al 个扇区
	int	13h
	jc	.GoOnReading		; 如果读取错误 CF 会被置为 1, 这时就不停地读, 直到正确为止

	add	esp, 2
	pop	bp

	ret
	
;----------------------------------------------------------------------------
; 函数名: GetFATEntry
;----------------------------------------------------------------------------
; 作用:
;	找到序号为 ax 的 Sector 在 FAT 中的条目, 结果放在 ax 中
;	需要注意的是, 中间需要读 FAT 的扇区到 es:bx 处, 所以函数一开始保存了 es 和 bx
GetFATEntry:
	push	es
	push	bx
	push	ax
	mov	ax, BaseOfKernelFile	; ┓
	sub	ax, 0100h				; ┣ 在 BaseOfLoader 后面留出 4K 空间用于存放 FAT
	mov	es, ax					; ┛
	pop	ax
	mov	byte [bOdd], 0
	mov	bx, 3
	mul	bx			; dx:ax = ax * 3
	mov	bx, 2
	div	bx			; dx:ax / 2  ==>  ax <- 商, dx <- 余数
	cmp	dx, 0
	jz	LABEL_EVEN
	mov	byte [bOdd], 1
LABEL_EVEN:;偶数
	xor	dx, dx			; 现在 ax 中是 FATEntry 在 FAT 中的偏移量. 下面来计算 FATEntry 在哪个扇区中(FAT占用不止一个扇区)
	mov	bx, [BPB_BytsPerSec]
	div	bx			; dx:ax / BPB_BytsPerSec  ==>	ax <- 商   (FATEntry 所在的扇区相对于 FAT 来说的扇区号)
					;				dx <- 余数 (FATEntry 在扇区内的偏移)。
	push	dx
	mov	bx, 0			; bx <- 0	于是, es:bx = (BaseOfLoader - 100):00 = (BaseOfLoader - 100) * 10h
	add	ax, SectorNumOfFAT1	; 此句执行之后的 ax 就是 FATEntry 所在的扇区号
	mov	cl, 2
	call	ReadSector		; 读取 FATEntry 所在的扇区, 一次读两个, 避免在边界发生错误, 因为一个 FATEntry 可能跨越两个扇区
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
