#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "string.h"
#include "proc.h"
#include "global.h"


/*======================================================================*
                            tinix_main
 *======================================================================*/
PUBLIC int tinix_main()
{
	disp_str("-----\"tinix_main\" begins-----\n");
	TASK*		p_task		= task_table;
	PROCESS*	p_proc		= proc_table;
	char*		p_task_stack	= task_stack + STACK_SIZE_TOTAL;
	t_16		selector_ldt	= SELECTOR_LDT_FIRST;
	int i;

	for(i=0;i<NR_TASKS;i++){
		strcpy(p_proc->p_name, p_task->name);	// name of the process
		p_proc->pid	= i;			// pid

		p_proc->ldt_sel	= selector_ldt;
		memcpy(&p_proc->ldts[0], &gdt[SELECTOR_KERNEL_CS >> 3], sizeof(DESCRIPTOR));
		p_proc->ldts[0].attr1 = DA_C | PRIVILEGE_TASK << 5;	// change the DPL
		memcpy(&p_proc->ldts[1], &gdt[SELECTOR_KERNEL_DS >> 3], sizeof(DESCRIPTOR));
		p_proc->ldts[1].attr1 = DA_DRW | PRIVILEGE_TASK << 5;	// change the DPL
		p_proc->regs.cs		= ((8 * 0) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
		p_proc->regs.ds		= ((8 * 1) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
		p_proc->regs.es		= ((8 * 1) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
		p_proc->regs.fs		= ((8 * 1) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
		p_proc->regs.ss		= ((8 * 1) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
		p_proc->regs.gs		= (SELECTOR_KERNEL_GS & SA_RPL_MASK) | RPL_TASK;
		p_proc->regs.eip	= (t_32)p_task->init_eip;
		p_proc->regs.esp	= (t_32)p_task_stack;
		p_proc->regs.eflags	= 0x1202;	// IF=1, IOPL=1, bit 2 is always 1.

		p_task_stack -= p_task->stacksize;
		p_proc++;
		p_task++;
		selector_ldt += 1 << 3;
	}

	k_reenter = 0;
	
	proc_table[0].ticks = proc_table[0].priority = 15;
	proc_table[1].ticks = proc_table[1].priority = 5;
	proc_table[2].ticks = proc_table[2].priority = 3;	
	
	p_proc_ready	= proc_table;
	
	put_irq_handler(CLOCK_IRQ, clock_handler);	/* 设定时钟中断处理程序 */
	enable_irq(CLOCK_IRQ);				/* 让8259A可以接收时钟中断 */

	restart();


	while(1){}
}


void TestA()
{
	while(1){
		disp_color_str("A.",BRIGHT | MAKE_COLOR(BLACK, RED));
		milli_delay(10);
	}
}


void TestB()
{
	int i=0;
	while(1){
		disp_color_str("B.",BRIGHT | MAKE_COLOR(BLACK, GREEN));
		milli_delay(10);
	}
}


void TestC()
{
	while(1){
		disp_color_str("C.",BRIGHT | MAKE_COLOR(BLACK, BLUE));
		milli_delay(10);
	}
}

