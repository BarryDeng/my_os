#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "string.h"
#include "proc.h"
#include "global.h"



PUBLIC void init_8259A()
{
	out_byte(INT_M_CTL,	0x11);						
	out_byte(INT_M_CTLMASK,	INT_VECTOR_IRQ0);
	out_byte(INT_M_CTLMASK,	0x4);
	out_byte(INT_M_CTLMASK,	0x1);	
	
	out_byte(INT_S_CTL,	0x11);	
	out_byte(INT_S_CTLMASK,	INT_VECTOR_IRQ8);			
	out_byte(INT_S_CTLMASK,	0x2);							
	out_byte(INT_S_CTLMASK,	0x1);			

	out_byte(INT_M_CTLMASK,	0xFF);	
	out_byte(INT_S_CTLMASK,	0xFF);	
	
	//8253
	out_byte(TIMER_MODE, RATE_GENERATOR);
	out_byte(TIMER0, (t_8) (TIMER_FREQ/HZ));
	out_byte(TIMER0, (t_8) (TIMER_FREQ/HZ) >> 8);

	int i;
	for(i=0;i<NR_IRQ;i++){
		irq_table[i]	= spurious_irq;
	}
}

/*======================================================================*
                            put_irq_handler
 *======================================================================*/
PUBLIC void put_irq_handler(int irq, t_pf_irq_handler handler)
{
	disable_irq(irq);
	irq_table[irq] = handler;
}

/*======================================================================*
                           spurious_irq
 *======================================================================*/
PUBLIC void spurious_irq(int irq)
{
	disp_str("spurious_irq: ");
	disp_int(irq);
	disp_str("\n");
}
