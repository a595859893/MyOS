global SwitchImmediately
global BackKernal

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
extern allowSwitch

INT_DELAY		equ 20

[section .text]
BackKernal:
;void BackKernal();
	mov word[allowSwitch],1
	mov ax, 0
	mov es, ax
	mov ax, 0xffff
	mov word[es:22h*4+2],ax
	mov word[es:22h*4],ax
	jmp 0x100

SwitchImmediately:
;void SwitchImmediately();
	cli
	add esp,BIAS_CALL	;栈回退
	
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
	
	mov si,word[tmp_si]
	mov di,word[tmp_di]
	mov bp,word[tmp_bp]

	mov fs,word[tmp_fs]
	mov gs,word[tmp_gs]
	mov bx,word[tmp_bx]
	mov cx,word[tmp_cx]
	mov dx,word[tmp_dx]
	mov es,word[tmp_es]
	
	mov sp,word[tmp_sp]	;临时栈
	mov ss,word[tmp_ss]
	jmp .jumpPrepare
	
	.jumpPrepare:		;准备跳至新进程
	push word[tmp_flags]
	push word[tmp_cs]
	push word[tmp_ip]
	
	mov word[allowSwitch],1
	mov word[intTimer],INT_DELAY
	mov ds,word[tmp_ds]	;最后设置ds以确保赋值正确
	sti
	iret
	
SetTimerInt:
	cli
	push ax
	push es

	xor ax,ax
	mov es,ax
	
	;系统时钟中断
	mov al,36h
	out 43h,al
	mov ax,1193182/300	;每秒300次中断
	out 40h,al
	mov al,ah
	out 40h,al
	mov word[es:8*4], TakeTurnInt
	mov word[es:8*4+2], cs
	
	;系统调用
	mov word[es:0x21*4], SysInt
	mov word[es:0x21*4+2], cs
	
	pop es
	pop ax
	sti
	o32 ret
	
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
	
	;进程切换
	.exchange:
	;次数计数
	mov word[intTimer],INT_DELAY
	cmp word[readyHead],-1
	je .finish
	;允许切换
	cmp word[allowSwitch],0
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
	
	
[section .data]
intTimer dw INT_DELAY