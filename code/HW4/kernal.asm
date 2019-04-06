extern CommandOn
extern CommandKeyPress

global _start
global GetFileInfo
global RevalInt
global SetInt
global CallInt33
global CallInt34
global CallInt35
global CallInt36

FILE_LIST		equ 0x7C00
FILE_BIAS		equ 16
COOLWHEEL_DELAY equ 10

[BITS 16]
[SECTION .text]
_start:
	;设置数据段
	mov ax, cs
	mov ds, ax
	
	mov ss, ax
	mov sp, 0xFFF0

	push 0 ;函数调用兼容s
	call SetInt
	
Commander:
	push 0 ;C函数调用兼容
	call CommandOn
	
	.getChar:
	xor eax, eax
	mov ah,01h
	int 16h
	cmp al, 0x00
	jz .getChar
	
	and eax,0x000000FF
	push eax
	push 0 ;C函数调用兼容
	call CommandKeyPress
	add esp,BIAS_ARG*1
	
	; 从缓冲区除去当前字符
	mov ah,00h
	int 16h
	jmp .getChar
	
SetInt:
	cli
	push ax
	push es

	xor ax,ax
	mov es,ax
	;时钟中断储存
	push word[es:8*4]
	pop word[TimeInt]
	push word[es:8*4+2]
	pop word[TimeInt+2]
	;中断覆盖
	mov word[es:8*4], WindFireWheelWithoutEnemy
	mov word[es:8*4+2], cs
	mov word[es:33*4], CustomInt33
	mov word[es:33*4+2], cs
	mov word[es:34*4], CustomInt34
	mov word[es:34*4+2], cs
	mov word[es:35*4], CustomInt35
	mov word[es:35*4+2], cs
	mov word[es:36*4], CustomInt36
	mov word[es:36*4+2], cs
	
	pop es
	pop ax
	sti
	o32 ret
	
RevalInt:
	cli
	push ax
	push es
	
	xor ax,ax
	mov es,ax
	;时钟中断恢复
	mov ax, word[TimeInt]
	mov word[es:8*4], ax
	mov ax, word[TimeInt+2]
	mov word[es:8*4+2], ax
	
	pop es
	pop ax
	sti
	o32 ret
	
WindFireWheelWithoutEnemy:
	nop
	nop
	push eax
	push bx
	push cx
	push ds
	push gs
	
	mov bx,cs
	mov ds,bx
	
	dec byte[CoolWheelCounter]
	mov bl, byte[CoolWheelCounter]
	jnz .back
	mov byte[CoolWheelCounter], COOLWHEEL_DELAY
	
	cmp byte[BigFanCount],0xFF
	jne BigFireWind
	.BulletCheck:
	cmp byte[BulletPosX],0xFF
	jne Bullet
	
	.SmallLoop:
	inc word[CoolWheelCharIndex]
	and word[CoolWheelCharIndex],00000011b
	mov bx,word[CoolWheelCharIndex]
	mov	ax,0B800h						; 文本窗口显存起始地址
	mov	gs,ax							; GS = B800h
	mov ah,0Fh							; 0000：黑底、1111：亮白字（默认值为07h）
	mov al,[bx+CoolWheel]				; AL = 显示字符值（默认值为20h=空格符）
	mov [gs:((80*12+39)*2)],ax			; 屏幕第 24 行, 第 79 列
	
	.back:
	mov al,20h			; AL = EOI
	out 20h,al			; 发送EOI到主8529A
	out 0A0h,al			; 发送EOI到从8529A
	
	pop gs
	pop ds
	pop cx
	pop bx
	pop eax
	iret
	
Bullet:
	dec byte[BulletPosX]
	jnz .BulletCheck
	mov byte[BulletPosX],0xFF
	jmp .BulletJmp
	
	.BulletCheck:
	xor cx,cx
	mov bx, BulletStr
	mov cl, byte[BulletPosX]
	cmp cl, BulletLen
	jg .BulletShow
	mov cl, BulletLen
	add bx, BulletLen
	xor ax,ax
	mov al, byte[BulletPosX]
	sub bx, ax

	.BulletShow:
	sub cx, BulletLen
	mov ax,BulletPosY	;行
	push eax
	mov ax, cx	        ;列
	push eax
	mov ax,bx
	push eax
	push 0 ;函数调用兼容
	call ScreenPrintf
	add esp,BIAS_ARG*3
	
	.BulletJmp:
	jmp WindFireWheelWithoutEnemy.SmallLoop
	
	
BigFireWind:
	mov ax,10	;行
	push eax
	mov ax,37	;列
	push eax
	mov al,byte[BigFanCount]
	jmp .CheckFanType

	.FanType1:
	mov ax,BigFanOne
	inc byte[BigFanCount]
	jmp .ShowFan
	.FanType2:
	mov ax,BigFanTwo
	inc byte[BigFanCount]
	jmp .ShowFan
	.FanType3:
	mov ax,BigFanThree
	inc byte[BigFanCount]
	jmp .ShowFan
	.FanType4:
	mov ax,BigFanFour
	inc byte[BigFanCount]
	jmp .ShowFan
	.FanType5:
	mov ax,BigFanFive
	inc byte[BigFanCount]
	jmp .ShowFan
	.FanType6:
	mov ax,BigFanSix
	mov byte[BigFanCount],0x00
	jmp .ShowFan
	
	.CheckFanType:
	cmp al,0x00
	je .FanType1
	cmp al,0x01
	je .FanType2
	cmp al,0x02
	je .FanType3
	cmp al,0x03
	je .FanType4
	cmp al,0x04
	je .FanType5
	cmp al,0x05
	je .FanType6

	.ShowFan:
	push eax
	push 0 ;函数调用兼容
	call ScreenPrintf
	add esp,BIAS_ARG*3
	
	jmp WindFireWheelWithoutEnemy.BulletCheck
	
CallInt33:
	push ds
	push ax
	mov ax,cs
	mov ds,ax
	int 33
	pop ax
	pop ds
	o32 ret
CallInt34:
	push ds
	push ax
	mov ax,cs
	mov ds,ax
	int 34
	pop ax
	pop ds
	o32 ret
CallInt35:
	push ds
	push ax
	mov ax,cs
	mov ds,ax
	int 35
	pop ax
	pop ds
	o32 ret
CallInt36:
	push ds
	push ax
	mov ax,cs
	mov ds,ax
	int 36
	pop ax
	pop ds
	o32 ret


	
GetFileInfo:
;int GetFileInfo(int fileIndex,char* name,int *sector,int *size,int *time,int *type);
	push bx
	push cx
	push dx
	push es
	push bp
	
	;es和bp初始化
	mov bp, sp
	mov ax, FILE_LIST
	shr ax, 4
	mov es, ax
	
	;计算文件偏移
	mov ax, word[bp + (BIAS_CALL+BIAS_PUSH*5+BIAS_ARG*0)]
	mov bx, FILE_BIAS
	mul bx
	xor esi, esi
	mov si, ax
	
	;判断是否到底
	mov bx, word[es:si]
	cmp bx,0xFFFF
	jnz .read
	mov eax, 0
	jmp .return
	
	;读取文件信息并赋值到指针
	.read:
	push dword[bp + (BIAS_CALL+BIAS_PUSH*5+BIAS_ARG*1)]
	push esi
	xor eax, eax
	mov ax, FILE_LIST
	push eax
	push 0; 调用兼容
	call Readline
	add esp,BIAS_ARG*3
	mov esi,eax
	
	;扇区
	xor eax, eax
	mov bx, word[bp + (BIAS_CALL+BIAS_PUSH*5+BIAS_ARG*2)]
	mov ax, word[es:si]
	mov dword[bx], eax
	add si,2;大小
	mov bx, word[bp + (BIAS_CALL+BIAS_PUSH*5+BIAS_ARG*3)]
	mov ax, word[es:si]
	mov dword[bx], eax
	add si,2;时间
	mov bx, word[bp + (BIAS_CALL+BIAS_PUSH*5+BIAS_ARG*4)]
	mov ax, word[es:si]
	mov dword[bx], eax
	add si,2;类型
	mov bx, word[bp + (BIAS_CALL+BIAS_PUSH*5+BIAS_ARG*5)]
	mov ax, word[es:si]
	mov dword[bx], eax
	;返回读取正确
	mov eax, 1
	
	;函数返回
	.return:
	pop bp
	pop es
	pop dx
	pop cx
	pop bx
	o32 ret

CustomInt33:
	mov byte[BulletPosX], SCREEN_WIDTH-40
	iret
	
CustomInt34:
	mov byte[BigFanCount], 0
	iret
	
CustomInt35:
	push eax
	
	mov ax,5	;行
	push eax
	mov ax,40	;列
	push eax
	mov ax,Alice
	push eax
	push 0 ;函数调用兼容
	call ScreenPrintf
	add esp,BIAS_ARG*3
	
	pop eax
	iret
	
CustomInt36:
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
	iret

%include "Utils.asm"


[BITS 16]
[SECTION .data]
CoolWheel dw "/-\|"
CoolWheelCounter db COOLWHEEL_DELAY
CoolWheelCharIndex dw 0
TimeInt	dw 0x0000,0x0000
;弹幕
BulletStr 	db 	"   Reading for the rise of China!   ",0x00
BulletPosX 	db 	0xFF
BulletPosY	equ 10
BulletLen	equ 36

BigFanCount db 0xFF
BigFanOne:
db "  @@ ",0x0A
db "@ @  ",0x0A
db "@@@@@",0x0A
db "  @ @",0x0A
db " @@  ",0x00
BigFanTwo:
db "@  @@",0x0A
db "@ @  ",0x0A
db " @@@ ",0x0A
db "  @ @",0x0A
db "@@  @",0x00
BigFanThree:
db "@@  @",0x0A
db " @ @@",0x0A
db "  @  ",0x0A
db "@@ @ ",0x0A
db "@  @@",0x00
BigFanFour:
db "@@  @",0x0A
db "  @ @",0x0A
db " @@@ ",0x0A
db "@ @  ",0x0A
db "@  @@",0x00
BigFanFive:
db " @@  ",0x0A
db "  @ @",0x0A
db "@@@@@",0x0A
db "@ @  ",0x0A
db "  @@ ",0x00
BigFanSix:
db "  @  ",0x0A
db "  @  ",0x0A
db "@@@@@",0x0A
db "  @  ",0x0A
db "  @  ",0x00

Alice:
db " \                                / ",0x0A,
db "   \ H i !  I ' m   A l i c e ! /   ",0x0A,
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


PersonalInfomation:
db "Hi! I'm Weng Tianjun from SDCS!"