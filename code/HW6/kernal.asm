[BITS 16]
extern CommandOn
extern CommandKeyPress

extern threadStart

global _start
global GetFileInfo
global RevalInt
global SetInt

FILE_LIST		equ 0x7C00
FILE_BIAS		equ 16
COOLWHEEL_DELAY equ 10


[SECTION .text]
_start:
	;设置数据段
	mov ax, cs
	mov ds, ax
	
	mov ss, ax
	mov sp, 0xFFF0
	
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
	
	;中断覆盖
	
	;系统时钟中断
	mov al,36h
	out 43h,al
	mov ax,1193182/100	;每秒100次中断
	out 40h,al
	mov al,ah
	out 40h,al
	mov word[es:8*4], 0xfea5
	mov word[es:8*4+2], 0xf000
	
	;系统调用
	mov word[es:0x21*4], SysInt
	mov word[es:0x21*4+2], cs

	;自定义时钟中断
	mov word[es:0x22*4], WindFireWheelWithoutEnemy
	mov word[es:0x22*4+2], cs
	
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
	;自定义时钟中断恢复
	mov word[es:0x22*4], WindFireWheelWithoutEnemy
	mov word[es:0x22*4+2], cs
	
	pop es
	pop ax
	sti
	o32 ret
	
TakeTurnInt:
	cmp threadStart
	jz .finish
	call SaveThreadState
	call RevalThreadState
	
	.finish
	mov al,20h			; AL = EOI
	out 20h,al			; 发送EOI到主8529A
	out 0A0h,al			; 发送EOI到从8529A
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
%include "syscall.asm"
%include "Extra.asm"