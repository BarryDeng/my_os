# my_os

《自己动手写操作系统》的学习代码


BIOS -> MBR -> OBR -> kernel

### day1 
&emsp;&emsp;在引导扇区写入boot，通过boot在root扇区范围寻找loader，加载进内存后，执行loader寻找kernel
### day2 
&emsp;&emsp;进入保护模式，识别kernel的elf文件头后，读取program header将kernel使用memcp复制到指定内存，执行kerbel
### day3
&emsp;&emsp;扩展内核代码，更新GDT，添加disp_str打印字符串函数，建立目录树，添加Makefile
