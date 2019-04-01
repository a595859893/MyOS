载入的程序不正确显示
经过排查怀疑是变量地址指向错误，但此时org已经在100h了

bat中set不能有空格

bochs调试
http://www.cnblogs.com/hongzg1982/articles/2116643.html
https://www.pediy.com/kssd/pediy11/123767.html

```
r 	查看寄存器
sreg	查看段寄存器
b [地址]	在地址处设置断点
c	继续触发
x [地址]	查看线性地址的内容
xp [地址]	查看物理地址的内容
info cpu	查看各种信息
```

引导扇区例子
https://blog.csdn.net/Lirx_Tech/article/details/42363093

常见错误
https://stackoverflow.com/questions/50193982/reading-sector-from-drive-fails?r=SearchResults

关于ds的设置
https://forum.nasm.us/index.php?topic=60.0

引导扇区例子
https://stackoverflow.com/questions/19935688/how-to-transfer-the-control-from-my-boot-loader-to-the-application-located-in-ha?r=SearchResults
https://stackoverflow.com/questions/7716427/loading-2nd-stage-of-bootloader-and-starting-it?r=SearchResults

dos下要进行100h偏移，但是自己的操作系统不能这么做（我也不知道应该怎么样让它能偏移）
ds要携带过去（有更好的办法吗？）

[]方式括起来的是相对与es:后进行偏移的，没有括起来的地址则不会


mystr 经过显存计算部分时出错

检查输入
https://bbs.csdn.net/topics/280082234
https://zhidao.baidu.com/share/4b3b53cd78e9463db4120474f1687b64.html
https://www.cnblogs.com/bestsheng/p/5659932.html