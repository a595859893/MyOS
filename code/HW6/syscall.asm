extern DisposeThread

global CallSysInt

[SECTION .text]
;ah 功能号码
;	0 打印字符串至屏幕
;		es 字符串段偏移
;		bx 字符串地址
;		dl 打印行
;		dh 打印列
;	1 打印Ouch到屏幕中间
;	2 召唤Alice
;	3 展示个人信息
;	4 让风火轮变成电风扇
;	5 来一条弹幕
;	6 退出当前进程

SysInt:
	push ds
	push ecx
	
	cmp ah, 0
	je .PrintScreen
	cmp ah, 1
	je .PrintOuch
	cmp ah, 2
	je .SummonAlice
	cmp ah, 3
	je .PrintPersonInfo
	cmp ah, 4
	je .BigFan
	cmp ah, 5
	je .Bullet
	cmp ah, 6
	je .Dispose
	
	jmp .ExitRet
	
	.PrintScreen:
		mov cx, es
		mov ds, cx
		
		xor ecx,ecx
		mov cl,dl
		push ecx	;row
		mov cl,dh
		push ecx	;col
		mov cx, bx
		push ecx	;msg
		
		push 0		;函数调用兼容
		call ScreenPrintf
		add esp,BIAS_ARG*3
		
		jmp .ExitRet
		
	.PrintOuch:
		mov bx, ouchStr
		mov dl, SCREEN_HEIGHT/2-1
		mov dh, SCREEN_WIDTH/2-10
		mov bx, cs
		mov es, bx
		mov bx, ouchStr
		jmp .PrintScreen
		
	.SummonAlice:
		push eax
		
		mov ax,5	;行
		push eax
		mov ax,40	;列
		push eax
		mov ax, Alice
		push eax
		push 0 ;函数调用兼容
		call ScreenPrintf
		add esp,BIAS_ARG*3
		
		pop eax
		jmp .ExitRet
		
	.PrintPersonInfo:
		push eax
		
		mov ax,24	;行
		push eax
		mov ax,0	;列
		push eax
		mov ax,PersonalInfomation
		push eax
		push 0 ;函数调用兼容
		call ScreenPrintf
		add esp,BIAS_ARG*3
		
		pop eax
		jmp .ExitRet
		
	.BigFan:
		mov byte[BigFanCount], 0
		jmp .ExitRet
		
	.Bullet:
		mov byte[BulletPosX], SCREEN_WIDTH-40
		jmp .ExitRet
		
	.Dispose:
		mov ax,cs
		mov ds,ax
		add esp,6		;栈回退
		push 0
		call DisposeThread
		jmp .ExitRet	;应该不会触发，但是保险起见……

	.ExitRet:
		sti
		pop ecx
		pop ds
		iret
		
CallSysInt:
;void CallSysInt(int number);
	push bp
	push ax
	
	mov	bp, sp
	
	xor ax, ax
	mov	ah, byte[bp + (BIAS_CALL+BIAS_PUSH*2+BIAS_ARG*0)]
	int 0x21
	
	pop ax
	pop bp
	o32 ret
	
[SECTION .data]
ouchStr db "Ouch! Ouch!",0x00

PersonalInfomation:
db "Hi! I'm Weng Tianjun from SDCS!",0x00

Alice:
db " \                                / ",0x0A
db "   \ H i !  I ' m   A l i c e ! /   ",0x0A
db "     \                        /     ",0x0A
db "             'l:.                   ",0x0A
db "           .:0WXd'                  ",0x0A
db "          .oNMMMMOc.   .',;coo:.    ",0x0A
db "         .oNMMMMMWXOldk0NWWWMMWd.   ",0x0A
db "       .,o:.           .'oKWMM0,    ",0x0A
db "    .,::.                 'xNM0'    ",0x0A
db "  .cxx:.                   .:ko.    ",0x0A
db "    .lo.,doxx'  .o.o,...     .l'    ",0x0A
db "    :0Ocd..:ox, ..o.Xx,,.  .':d;    ",0x0A
db "    oXKx Xk':d:'' kK kdc.  ;l;:;    ",0x0A
db "    .;d: Ol    '  OX ,co. .;;',,    ",0x0A
db "     .l, .,       .d  ,;  ,'  .,    ",0x0A
db "     :l.    ,l:,.     '' ':.  .c.   ",0x0A
db "    .ok:...;kdlxc    .,..;,   .c,   ",0x0A
db "    ;ddd0KKX0dodollld0d:olloc:;:;   ",0x0A
db "...,x0c,xWW0,   :KWWMXdc'..;:clloc,.",0x0A
db ",.  ..  'od,    .cddOk;         .';;",0x00