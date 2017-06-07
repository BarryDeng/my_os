 
 [section .text]
 
 global memcpy
 
 ; void* memcpy(void* es:pDest, void* ds:pSrc, int iSize);
 memcpy:
	push	ebp
	mov	ebp, esp
	
	push	esi
	push	edi
	push	ecx
	
	mov	edi, [ebp + 8]	;pDest
	mov esi, [ebp + 12]	;pSrc
	mov ecx, [ebp + 16]	;iSize
	
.1:
	cmp ecx, 0
	jz .2
	
	mov al, [ds:edi]
	inc edi

	mov byte [es:esi], al
	dec	ecx
	jmp .1	
.2:
	mov eax, [ebp + 8]
	
	pop ecx
	pop edi
	pop esi
	mov esp, ebp
	pop ebp
	
	ret
	
	
	