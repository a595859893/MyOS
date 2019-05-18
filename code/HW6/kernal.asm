[BITS 16]
extern CommandOn
extern CommandKeyPress
extern CommandCortorlKeyPress

global _start
global GetFileInfo
global SetInt
global PutChar
global Clear
global Printf
global UpdateCursor

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
	shr	eax,8
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

Printf:
;void Printf(char* msg);
	push bp
	push es
	push ax
	push bx
	push di
	push si
	
	mov ax, 0b800h
	mov es, ax
	mov	bp, sp

	mov	si, word[bp+(BIAS_CALL+BIAS_PUSH*6)]
	mov	di, word[screenCusor]
	mov	ah, 0Fh
	.1:
	mov al,byte[si]
	inc si
	test al, al
	jz	.2
	cmp	al, 0Ah ;回车
	jnz	.3
	push ax
		mov	ax, di
		mov	bl, 160
		div	bl
		and	ax, 0FFh
		inc	ax
		mov	bl, 160
		mul	bl
		mov	di, ax
	pop	ax
	jmp	.1
	.3:
	mov	[es:di], ax
	add	di, 2
	jmp	.1

	.2:
	mov	[screenCusor], di
		
	;当前游标显示
	mov	ax, di
	mov	bl, 160
	div	bl			;余数在ah
	mov dh,al

	mov al, ah
	xor ah, ah
	mov bh, 2
	div bh
	mov dl,al
	
	mov bh, 0
	mov ah, 02h
	int 10h
	
	;退出
	pop si
	pop di
	pop bx
	pop ax
	pop es
	pop	bp
	o32 ret
	

PutChar:
;void PutChar(char ch);
	push bp
	push es
	push ax
	mov bp,sp
	
	;打印字符
	mov ax,0b800h
	mov es,ax
	mov al,BYTE[bp+(BIAS_CALL+BIAS_PUSH*3)]
	mov ah,00000111b
	mov di,[screenCusor]
	mov	[es:di], ax

	;退出
	mov sp,bp
	pop ax
	pop es
	pop bp
	o32 ret
	
UpdateCursor:
;void UpdateCursor();
	push bp
	push es
	push ax
	mov bp,sp
	
	;当前游标显示
	mov di,[screenCusor]
	mov	ax, di
	mov	bl, 160
	div	bl			;余数在ah
	mov dh,al

	mov al, ah
	xor ah, ah
	mov bh, 2
	div bh
	mov dl,al
	
	mov bh, 0
	mov ah, 02h
	int 10h

	;退出
	mov sp,bp
	pop ax
	pop es
	pop bp
	o32 ret
	
Clear:
;void Clear();
	push bx
	push ax
	push bx
	push cx
	push dx		
	mov	ax, 600h	; AH = 6,  AL = 0
	mov	bx, 700h	; 黑底白字(BL = 7)
	mov	cx, 0		; 左上角: (0, 0)
	mov	dx, 184fh	; 右下角: (24, 79)
	int	10h		; 显示中断
	mov word[screenCusor],0
	
	;当前游标显示
	mov dx, 0
	mov bh, 0
	mov ah, 02h
	int 10h
	
	pop dx
	pop cx
	pop bx
	pop ax
	pop bx
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

	
%include "Utils.asm"
%include "syscall.asm"
%include "ProcessControl.asm"
%include "Extra.asm"