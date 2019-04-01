# 当前环境
vscode（x86 and x86_64 Assembly）(文本编辑器)
HxD(16进制编辑器)
https://mh-nexus.de/en/hxd/
NASM(汇编编译器)
https://nasm.us/
VMware Player(虚拟机)


# PPT相关
error: operation size not specified
PPT中代码是全角而非半角，导致复制后代码失败
PPT上前几页的代码是不正确的
B线路



# MASM相关（已无参考价值）
各种报错原因（这是MASM不是NASM）
https://stackoverflow.com/questions/11572307/nasm-error-parsing-instruction-expected
不同点
https://www.nasm.us/doc/nasmdoc2.html#section-2.2

.386 指明指令集
https://zhidao.baidu.com/question/438949076.html

code SEGMENT
code ENDS
两句中夹着的是code段的内容
https://www.zhihu.com/question/22095837

ASSUME cs:code,ds:code
代表cs和ds会从code段中找东西
https://wenku.baidu.com/view/248ba7256edb6f1aff001ff5.html


# NASM相关（需要参考）
第一个扇区会被加载到0x7c00
显存开始地址0xB800
https://blog.csdn.net/sivolin/article/details/40859987

可以运行的例子
https://blog.csdn.net/fjb2080/article/details/7587594

boot开始需要做的事情

org 0x7c00
start:
  xor ax, ax
  mov ds, ax                    ;设置数据段

将数据放在末尾
(好像`mov ax, cs`也可以)

nasm语法规则
https://blog.csdn.net/lirx_tech/article/details/42340619

生成的二进制文件可以直接作为软盘映像进行浏览
不过正确的做法是找一个16进制编辑器将2进制数据挪到第一个扇区（512字节）里面去（末尾加55AA代表是启动程序）

nasm编译参数
https://blog.csdn.net/jiangwei0512/article/details/51636602

equ 声明常量，类似C的宏
https://www.eefocus.com/wang312/blog/12-02/238908_478b3.html

.com程序的加载要加入以下代码
org 100h
所有变量的偏移地址要从100h开始算起（之前的是DOS系统的变量需要储存）
规定程序的起始地址
http://blog.sina.com.cn/s/blog_48a45b950100zrn3.html

mov指令
https://www.jianshu.com/p/c47c4d86d425

mul指令
http://www.cnblogs.com/del/archive/2010/04/15/1712950.html


使用int（中断指令）可调用显示

mov byte[ax:00],'@'
报错原因，ax不是段寄存器，不能使用[dl:eax]操作
https://stackoverflow.com/questions/9652694/nasm-invalid-segment-override


http://flatassembler.net/docs.php?article=manual


调用变量和预想值不同
需要将ds寄存器设置为存储变量的地方
https://stackoverflow.com/questions/28588647/data-in-data-segment-not-accessible
https://stackoverflow.com/questions/4903906/assembly-using-the-data-segment-register-ds
https://www.jianshu.com/p/8cd7f6f0f5b5

赋值要加[]变成值，而不是变量的地址

保护模式关闭，没有提示
现在dos中看看能不能跑，再挪到操作系统中

反弹程序，可扩展，需要显示自己的姓名和学号





