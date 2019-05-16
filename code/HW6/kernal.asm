[BITS 16]
extern CommandOn
extern CommandKeyPress
extern CommandCortorlKeyPress

global _start
global GetFileInfo
global SetInt

FILE_LIST		equ 0x7C00
FILE_BIAS		equ 16

[SECTION .text]
_start:
	;设置数据段
	mov ax, cs
	mov ds, ax
	
	mov ss, ax
	mov sp, 0x100
	
	;自定义时钟中断
	mov word[es:0x22*4], WindFireWheelWithoutEnemy
	mov word[es:0x22*4+2], cs
	
Commander:
	push 0 ;C函数调用兼容
	call SetTimerInt
	push 0 ;C函数调用兼容
	call CommandOn
	
	.getChar:
	xor eax, eax
	mov ah,01h
	int 16h
	
	
	cmp al, 0x00
	jne .keyPress
	cmp al;, 0x00
	jne .keyPress
	cmp ah, 0x01
	jne .controlPress
	jmp .getChar
	
	.keyPress:
	and eax,0x000000FF
	push eax
	push 0 ;C函数调用兼容
	call CommandKeyPress
	add esp,BIAS_ARG*1
	jmp .clearCache
	
	.controlPress:
	and eax,0x0000FF00
	shr	eax,2
	push eax
	push 0 ;C函数调用兼容
	call CommandCortorlKeyPress
	add esp,BIAS_ARG*1
	jmp .clearCache
	
	
	.clearCache:
	; 从缓冲区除去当前字符
	mov ah,00h
	int 16h
	jmp .getChar

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
%include "ProcessControl.asm"
%include "Extra.asm"