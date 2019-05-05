[BITS 16]
extern CommandOn
extern CommandKeyPress
extern NextThread

extern tmp_ax
extern tmp_bx
extern tmp_cx
extern tmp_dx
extern tmp_si
extern tmp_di
extern tmp_bp
extern tmp_sp
extern tmp_ip
extern tmp_flags
extern tmp_cs
extern tmp_ds
extern tmp_es
extern tmp_ss
extern tmp_fs
extern tmp_gs
extern tmp_state
extern readyHead
extern tmp_timercs
extern tmp_timerip

global _start
global GetFileInfo
global RevalInt
global SetInt

FILE_LIST		equ 0x7C00
FILE_BIAS		equ 16
COOLWHEEL_DELAY equ 10
INT_DELAY		equ 20


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
	
TakeTurnInt:
	nop
	nop
	
	;设置ds保证临时变量正确
	push ax
	push ds
	push es
	
	xor ax,ax
	mov es,ax
	mov ax,cs
	mov ds,ax
	
	mov ax,word[es:22h*4+2]
	mov word[tmp_timercs],ax
	mov ax,word[es:22h*4]
	mov word[tmp_timerip],ax
	
	pop word[tmp_es]
	pop word[tmp_ds]
	pop word[tmp_ax]
	dec word[intTimer]
	jz .exchange
	
	;自定义时钟中断
	cmp word[tmp_timercs],0xf000
	je .finish			;中断不是自定义的，跳过
	
	;执行自定义中断
	push word[tmp_timercs]
	push word[tmp_timerip]
	mov ax,word[tmp_ax]
	mov ds,word[tmp_ds]
	mov es,word[tmp_es]
	retf
	
	;进程切换（10次中断切换1次）
	.exchange:
	mov word[intTimer],INT_DELAY
	cmp word[readyHead],-1
	je .finish
	
	;保存当前寄存器状态至临时变量
	pop word[tmp_ip]
	pop word[tmp_cs]
	pop word[tmp_flags]
	
	mov word[tmp_bx],bx
	mov word[tmp_cx],cx
	mov word[tmp_dx],dx
	mov word[tmp_si],si
	mov word[tmp_di],di
	mov word[tmp_fs],fs
	mov word[tmp_gs],gs
	mov word[tmp_ss],ss
	mov word[tmp_sp],sp
	mov word[tmp_bp],bp
	
	;临时变量转至PCB，并获取下一个寄存器的状态至临时变量
	push 0
	call NextThread
	
	;寄存器状态恢复
	mov si,word[tmp_si]
	mov di,word[tmp_di]
	mov bp,word[tmp_bp]
	mov sp,word[tmp_sp]
	
	mov ss,word[tmp_ss]
	mov fs,word[tmp_fs]
	mov gs,word[tmp_gs]
	mov bx,word[tmp_bx]
	mov cx,word[tmp_cx]
	mov dx,word[tmp_dx]
	mov es,word[tmp_es]
	jmp .jumpPrepare
	
	.jumpPrepare:		;准备跳至新进程
	push word[tmp_flags]
	push word[tmp_cs]
	push word[tmp_ip]
	
	.finish:
	mov al,20h			; AL = EOI
	out 20h,al			; 发送EOI到主8529A
	out 0A0h,al			; 发送EOI到从8529A
	
	xor ax,ax
	mov es,ax
	mov ax,cs
	mov ds,ax
	
	mov ax,word[tmp_timercs]
	mov word[es:22h*4+2],ax
	mov ax,word[tmp_timerip]
	mov word[es:22h*4],ax
	
	mov ax,word[tmp_ax]
	mov es,word[tmp_es]
	mov ds,word[tmp_ds]
	iret
	
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
	mov word[es:8*4], TakeTurnInt
	mov word[es:8*4+2], cs
	
	;系统调用
	mov word[es:0x21*4], SysInt
	mov word[es:0x21*4+2], cs

	;自定义时钟中断
	; mov word[es:0x22*4], WindFireWheelWithoutEnemy
	; mov word[es:0x22*4+2], cs
	
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
	
[section .data]
intTimer dw INT_DELAY
	
%include "Utils.asm"
%include "syscall.asm"
%include "Extra.asm"