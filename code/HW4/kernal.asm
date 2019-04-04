extern CommandOn
extern CommandKeyPress

global _start
global GetFileInfo
global RevalInt
global SetInt

FILE_LIST		equ 0x7e00
FILE_BIAS		equ 16
COOLWHEEL_DELAY equ 5

[BITS 16]
[SECTION .data]
CoolWheel dw "/-\|"
CoolWheelCounter dw COOLWHEEL_DELAY
CoolWheelCharIndex dw 0
TimeInt	dw 0x0000,0x0000


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
	push ax
	push bx
	push gs
	
	dec word[CoolWheelCounter]
	mov bx, word[CoolWheelCounter]
	jnz .back
	mov word[CoolWheelCounter], COOLWHEEL_DELAY


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
	pop bx
	pop ax
	iret

  
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
	
%include "Utils.asm"
