BaseOfLoader	equ	09000h	;loader.bin段地址
OffsetOfloader	equ	0100h	;loader.bin偏移
 
BaseOfLoaderPhyAddr	equ	BaseOfLoader * 10h	;物理地址
 
BaseOfKernelFile	equ	08000h
OffsetOfkernelFile	equ	0h
