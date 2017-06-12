#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"

PUBLIC void init_8259A()
{
	//主片8259	ICW1 ~ ICW4
	out_byte(INT_M_CTL, 0x11);
	out_byte(INT_M_CTLMASK, INT_VECTOR_IRQ0);	//主片中断入口地址为 0x20
	out_byte(INT_M_CTLMASK, 0x4);
	out_byte(INT_M_CTLMASK, 0x1);
	//OCW1 关闭所有中断
	out_byte(INT_M_CTLMASK, 0xfe);
	
	
	//从片
	out_byte(INT_S_CTL, 0x11);
	out_byte(INT_S_CTLMASK, INT_VECTOR_IRQ8);	//从片中断入口地址为 0x28
	out_byte(INT_S_CTLMASK, 0x4);
	out_byte(INT_S_CTLMASK, 0x1);
	//OCW1 关闭所有中断
	out_byte(INT_S_CTL, 0xff);
	
}

PUBLIC void spurious_irq(int irq)
{
	disp_str("spurious_irq: ");
	disp_int(irq);
	disp_str("\n");
}
