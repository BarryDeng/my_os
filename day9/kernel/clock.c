#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "string.h"
#include "proc.h"
#include "global.h"

PUBLIC void init_clock()
{
	//8253
	out_byte(TIMER_MODE, RATE_GENERATOR);
	out_byte(TIMER0, (t_8) (TIMER_FREQ/HZ));
	out_byte(TIMER0, (t_8) (TIMER_FREQ/HZ) >> 8);
	
	put_irq_handler(CLOCK_IRQ, clock_handler);	/* 设定时钟中断处理程序 */
	enable_irq(CLOCK_IRQ);				/* 让8259A可以接收时钟中断 */	
}

PUBLIC void clock_handler(int irq)
{
	if (k_reenter != 0) {
		return;
	}

	p_proc_ready->ticks--;
	ticks++;
	if (p_proc_ready->ticks > 0){
		return;
	}

	schedule();
}

PUBLIC void schedule()
{
	PROCESS* p;
	int greatest_ticks = 0;
	while (!greatest_ticks){
		for (p=proc_table; p<proc_table+NR_TASKS; p++){
			if (p->ticks > greatest_ticks){
				greatest_ticks = p->ticks;
				p_proc_ready = p;
			}
		}
		if (!greatest_ticks){
			for (p=proc_table; p<proc_table+NR_TASKS; p++){
				p->ticks = p->priority;
			}
		}
	}
}
