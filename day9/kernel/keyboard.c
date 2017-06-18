#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "string.h"
#include "proc.h"
#include "global.h"
#include "keymap.h"

PRIVATE KB_INPUT kb_in;
PRIVATE t_bool	code_with_E0 = FALSE;
PRIVATE	t_bool	shift_l = FALSE;
PRIVATE	t_bool	shift_r = FALSE;
PRIVATE	t_bool	alt_l	= FALSE;
PRIVATE	t_bool	alt_r	= FALSE;
PRIVATE	t_bool	ctrl_l	= FALSE;
PRIVATE	t_bool	ctrl_r	= FALSE;
PRIVATE	int		column = 0;

PUBLIC void init_keyboard()
{
	kb_in.count = 0;
	kb_in.p_head = kb_in.p_tail = kb_in.buf;
	
	put_irq_handler(KEYBOARD_IRQ, keyboard_handler);
	enable_irq(KEYBOARD_IRQ);
}

PUBLIC void keyboard_handler(int irq)
{
	t_8 scan_code = in_byte(KB_DATA);
	
	if (kb_in.count < KB_IN_BYTES){ //32
		*(kb_in.p_head) = scan_code;
		kb_in.p_head++;
		if (kb_in.p_head == kb_in.buf + KB_IN_BYTES){
			kb_in.p_head = kb_in.buf;
		}
		kb_in.count++;
	}
}

PRIVATE t_8 get_byte_from_kb_buf()	/* 从键盘缓冲区中读取下一个字节 */
{
	t_8	scan_code;

	while (kb_in.count <= 0) {}

	disable_int();
	scan_code = *(kb_in.p_tail);
	kb_in.p_tail++;
	if (kb_in.p_tail == kb_in.buf + KB_IN_BYTES) {
		kb_in.p_tail = kb_in.buf;
	}
	kb_in.count--;
	enable_int();

	return scan_code;
}

PUBLIC void in_process(t_32 key)
{
	char output[2];
	memset(output, 0, 2);
	
	if (!(key & FLAG_EXT)){
		output[0] = key & 0xFF;
		disp_str(output);
	}
}

PUBLIC void keyboard_read()
{
	t_8 scan_code;
	t_bool	make;
	t_32 key = 0;
	t_32* keyrow;
	
	
	if (kb_in.count > 0){
		
		scan_code = get_byte_from_kb_buf();
		
		if (scan_code ==  0xE1){
			int i;
			t_8 pausebreak_scan_code[] = {0xE1, 0x1D, 0x45, 0xE1, 0x9D, 0xC5};
			t_bool is_pausebreak = TRUE;
			for(i=1;i<6;i++){
				if (get_byte_from_kb_buf() != pausebreak_scan_code[i]) {
					is_pausebreak = FALSE;
					break;
				}
			}
			if (is_pausebreak) {
				key = PAUSEBREAK;
			}	
		}
		else if (scan_code == 0xE0){
			scan_code = get_byte_from_kb_buf();

			/* PrintScreen 被按下 */
			if (scan_code == 0x2A) {
				if (get_byte_from_kb_buf() == 0xE0) {
					if (get_byte_from_kb_buf() == 0x37) {
						key = PRINTSCREEN;
						make = TRUE;
					}
				}
			}

			/* PrintScreen 被释放 */
			if (scan_code == 0xB7) {
				if (get_byte_from_kb_buf() == 0xE0) {
					if (get_byte_from_kb_buf() == 0xAA) {
						key = PRINTSCREEN;
						make = FALSE;
					}
				}
			}

			/* 不是 PrintScreen。此时 scan_code 为 0xE0 紧跟的那个值。 */
			if (key == 0) {
				code_with_E0 = TRUE;
			}			
		}
		else{
			make = (scan_code & FLAG_BREAK ? FALSE : TRUE);	//因为mask中0x80处为0，break的0x80位是1
			keyrow = &keymap[(scan_code & 0x7F) * MAP_COLS];
			
			column = 0;
			if (shift_l || shift_r){
				column = 1;
			}
			if (code_with_E0){
				column = 2;
				code_with_E0 = FALSE;
			}
			
			key = keyrow[column];	
			switch(key){
				case SHIFT_L:	shift_l	= make; break;
				case SHIFT_R:	shift_r	= make; break;
				case CTRL_L:	ctrl_l	= make; break;
				case CTRL_R:	ctrl_r	= make; break;
				case ALT_L: 	alt_l	= make; break;
				case ALT_R:		alt_r	= make; break;
				default:
					if (!make){
						key = 0;
					}			
			}
			
			if(make){ /* 忽略 Break Code */
				key |= shift_l	? FLAG_SHIFT_L	: 0;
				key |= shift_r	? FLAG_SHIFT_R	: 0;
				key |= ctrl_l	? FLAG_CTRL_L	: 0;
				key |= ctrl_r	? FLAG_CTRL_R	: 0;
				key |= alt_l	? FLAG_ALT_L	: 0;
				key |= alt_r	? FLAG_ALT_R	: 0;

				in_process(key);
			}
		}
	}
}