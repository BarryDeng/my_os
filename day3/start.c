#include "type.h"
#include "const.h"
#include "protect.h"
 
PUBLIC void* memcpy(void* pDst, void* Psrc, int iSize);
PUBLIC void disp_str (char* pszInfo);
  
PUBLIC t_8	gdt_ptr[6];
PUBLIC	DESCRIPTOR	gdt[GDT_SIZE];

PUBLIC void cstart()
{	 // 将loader中的GDT复制到新GDT中
	disp_str("\n\n\n\n\n\n\n\n\n\n\n------\"cstart\" begins-----\n");
	memcpy(	&gdt, 
		(void*)(*((t_32*)(&gdt_ptr[2]))),   
		*((t_16*)(&gdt_ptr[0])) + 1	    
		);
	t_16* p_gdt_limit = (t_16*)(&gdt_ptr[0]);
	t_32* p_gdt_base  = (t_32*)(&gdt_ptr[2]);
	*p_gdt_limit = GDT_SIZE * sizeof(DESCRIPTOR) - 1;
	*p_gdt_base  = (t_32)&gdt;
}
 