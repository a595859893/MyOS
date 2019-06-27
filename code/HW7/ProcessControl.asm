global SwitchImmediately
global BackKernal
global MemoryCopy
global ForkPrepare

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
extern tmp_timercs
extern tmp_timerip

extern allowSwitch
extern readyHead

INT_DELAY		equ 20

[section .text]
ForkPrepare:
;int ForkPrepare(int tgt_ss);
	; 寄存器入栈
	push bx
	push cx
	push dx
	push si
	push di
	push fs
	push gs
	push ds
	push es
	push fs
	push gs
	
	; 中断入栈
	mov ax,word[es:22h*4+2]
	push ax
	mov ax,word[es:22h*4]
	push ax
	mov ax, word[bp + (BIAS_CALL+BIAS_PUSH*1+BIAS_ARG*0)]
	push ax
	
	

	
	push bp
	
	;栈复制
	mov bp,sp
	push 0 ;32位调用兼容
	push 0x100
	push dword[bp + (BIAS_CALL+BIAS_PUSH*1+BIAS_ARG*0)]
	push 0 ;32位调用兼容
	push ss
	push 0 ;32位调用兼容
	call MemoryCopy
	add sp, BIAS_ARG*3
	
	push sp
	mov word[tmp_sp],sp
	
	; 返回值拷贝
	pushf
	push cs
	push .finish
	
	pop word[tmp_ip]
	pop word[tmp_cs]
	pop word[tmp_flags]
	
	;栈复制
	; mov word[tmp_ss],ax	;ss存在ax中（上方参数获取）
	; mov word[tmp_sp],sp
	;寄存器复制（bp入栈了，所以不用管）
	; mov word[tmp_bx],bx
	; mov word[tmp_cx],cx
	; mov word[tmp_dx],dx
	; mov word[tmp_si],si
	; mov word[tmp_di],di
	; mov word[tmp_fs],fs
	; mov word[tmp_gs],gs
	; mov word[tmp_ds],ds
	; mov word[tmp_es],es
	; mov word[tmp_fs],fs
	; mov word[tmp_gs],gs
	
	; mov ax,word[es:22h*4+2]
	; mov word[tmp_timercs],ax
	; mov ax,word[es:22h*4]
	; mov word[tmp_timerip],ax
	



	;用于标记子线程
	mov word[tmp_ax],1
	;用于标记父线程
	mov ax, 0
	
	.finish:
	pop bp
	o32 ret

MemoryCopy:
;void memcpy(void *src,void *tgt,int offset);
	push bp
	push es
	push ds
	push ax
	push esi
	push edi
	push ecx
	
	xor esi,esi
	xor edi,edi
	xor ecx,ecx
	
	mov bp,sp
	mov ax,word[bp + (BIAS_CALL+BIAS_PUSH*10+BIAS_ARG*1)]
	mov es,ax
	mov ax,word[bp + (BIAS_CALL+BIAS_PUSH*10+BIAS_ARG*0)]
	mov ds,ax
	mov si,0
	mov di,0
	
	mov cx,word[bp + (BIAS_CALL+BIAS_PUSH*10+BIAS_ARG*2)]
	rep movsb
	
	pop ecx
	pop edi
	pop esi
	pop ax
	pop ds
	pop es
	pop bp
	o32 ret

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
	mov es,word[tmp_es]
	mov ds,word[tmp_ds]
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