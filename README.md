# my_os

《自己动手写操作系统》的代码编写与学习过程


BIOS -> MBR -> OBR -> kernel

### day1 
&emsp;&emsp;在引导扇区写入boot，通过boot在root扇区范围寻找loader，加载进内存后，执行loader寻找kernel
### day2 
&emsp;&emsp;进入保护模式，识别kernel的elf文件头后，读取program header将kernel使用memcp复制到指定内存，执行kernel
### day3
&emsp;&emsp;扩展内核代码，更新GDT，添加disp_str打印字符串函数，建立目录树，添加Makefile
### day4
&emsp;&emsp;初始化8259，打开中断机制，添加中断处理程序
### day5
&emsp;&emsp;建立TSS实现特权级间的跳转，建立进程表保存当前进程的寄存器等信息，为每一个进程初始化LDT，实现OS的第一个进程
### da6
&emsp;&emsp;利用时钟中断实现简单的时间轮转进程调度，即多进程。
