# my_os

《自己动手写操作系统》的学习代码

1. day1 在引导扇区写入boot，通过boot在root扇区范围寻找loader，加载进内存后，执行loader寻找kernel
1. day2 loader进入保护模式，识别kernel的elf文件头后，读取program segment将kernel使用memcp复制到指定内存，执行kerbel
