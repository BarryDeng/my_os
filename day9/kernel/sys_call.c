#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "string.h"
#include "proc.h"
#include "global.h"

PUBLIC int sys_get_ticks()
{
	return ticks;
}

PUBLIC int sys_read()
{
	disp_str("read");
	return 0;
}

