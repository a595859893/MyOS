extern screenCusor

global GetChar
global Open
global OpenAndJump
global Readline
global DisposeThread

BIAS_CALL equ 4
BIAS_PUSH equ 2
BIAS_ARG  equ 4

SCREEN_WIDTH  equ 80
SCREEN_HEIGHT equ 25

[SECTION .text]
ScreenPrintf:
;void ScreenPrintf(char* msg,int col,int row);
	push bp
	push es
	push ax
	push bx
	push cx
	push di
	push si
	
	mov ax, 0b800h
	mov es, ax
	mov	bp, sp

	mov	si, word[bp+(BIAS_CALL+BIAS_PUSH*7+BIAS_ARG*0)]
	mov bx, word[bp+(BIAS_CALL+BIAS_PUSH*7+BIAS_ARG*1)]
	mov ax, word[bp+(BIAS_CALL+BIAS_PUSH*7+BIAS_ARG*2)]
	
	mov cl, SCREEN_WIDTH
	mul cl
	add ax, bx
	mov cx, 2
	mul cx
	
	mov	di, ax
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
		mov	cl, 160
		div	cl
		and	ax, 0FFh
		inc	ax
		mul	cl
		add ax, bx
		add ax, bx
		mov	di, ax
		
	pop	ax
	jmp	.1
	.3:
	mov	[es:di], ax
	add	di, 2
	jmp	.1

	.2:
	;退出
	pop si
	pop di
	pop cx
	pop bx
	pop ax
	pop es
	pop	bp
	o32 ret
	
GetChar:
;char GetChar();
	mov ah, 0
	int 0x16
	o32 ret
	
Open:
;void Open(int offset,int count,int address);
	push ax
	push bx
	push cx
	push dx
	push bp
	push es
	
	xor ax,ax
	mov es,ax
	mov bp,sp
	
	;计算柱面、磁头、扇区
	;al为商，ah为余数
	mov ax, word[bp + (BIAS_CALL+BIAS_PUSH*6+BIAS_ARG*0)]
	mov bl, 18
	div bl
	mov cl, ah
	add cl, 1	;起始扇区号
	xor ah, ah
	mov bl, 2
	div bl
	mov dh, ah	;磁头号
	mov ch, al	;柱面号
	mov al, byte[bp + (BIAS_CALL+BIAS_PUSH*6+BIAS_ARG*1)]   ;扇区数 
	mov ah, 02h     										;功能号
	mov dl, 0             									;驱动器号
	mov bx, word[bp + (BIAS_CALL+BIAS_PUSH*6+BIAS_ARG*2)]	;地址
	int 0x13
	
	pop es
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	o32 ret
	
OpenAndJump:
;void OpenAndJump(int sector,int head,int count,int address);
	push ax
	push bx
	push cx
	push dx
	push bp
	push es
	
	xor ax,ax
	mov es,ax
	mov bp,sp
	;计算柱面、磁头、扇区
	;al为商，ah为余数
	mov ax, word[bp + (BIAS_CALL+BIAS_PUSH*6+BIAS_ARG*0)]
	mov bl, 18
	div bl
	mov cl, ah
	add cl, 1	;起始扇区号
	xor ah, ah
	mov bl, 2
	div bl
	mov dh, ah	;磁头号
	mov ch, al	;柱面号
	mov al, byte[bp + (BIAS_CALL+BIAS_PUSH*6+BIAS_ARG*1)]   ;扇区数 
	mov ah, 02h     										;功能号
	mov dl, 0             									;驱动器号
	mov bx, word[bp + (BIAS_CALL+BIAS_PUSH*6+BIAS_ARG*2)]	;地址
	add bx, 0x100
	int 0x13
	
	;设置返回地址
	push cs
	push .return
	;利用retf跳转
	sub bx, 0x100
	shr bx, 4
	push bx
	push 0x100
	retf
	
	.return:
	pop es
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	o32 ret

Readline:
;int Readline(int address,int offset,char *target);
	push bx
	push bp
	push si
	push es
	
	mov bp, sp
	mov bx, word[bp+(BIAS_CALL+BIAS_PUSH*4+BIAS_ARG*0)]
	shr bx, 4
	mov es, bx
	mov si, word[bp+(BIAS_CALL+BIAS_PUSH*4+BIAS_ARG*1)]
	mov bx, word[bp+(BIAS_CALL+BIAS_PUSH*4+BIAS_ARG*2)]
	.loop:
		mov ah, byte[es:si]
		mov byte[bx], ah
		inc si
		inc bx
		
		;\0或\n复制终止
		cmp ah, 0
		jz .exitLoop
		cmp ah, 0Ah
		jz .exitLoop
		jmp .loop
		
	.exitLoop:
	mov eax, esi
	
	pop es
	pop si
	pop bp
	pop bx
	o32 ret