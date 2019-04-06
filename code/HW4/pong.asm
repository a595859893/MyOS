org 0x100

ballstart:
	sti	;不知道为什么中断被关了……
	;保存上下文
	push ax
	push bx
	push cx
	push ds
	push es
	mov bx, ss
	mov cx, sp

	;设置数据段
	mov ax, cs
	mov ds, ax
	mov ss, ax
	mov ss, ax
	mov sp, 0xFFF0
	;原栈指针入栈
	push bx
	push cx

	;原中断入栈
	xor ax,ax
	mov es,ax
	push word[es:8*4]
	push word[es:8*4+2]
	; 键盘中断
	push word[es:9*4]
	pop word[KeyInt]
	push word[es:9*4+2]
	pop word[KeyInt+2]
	;中断覆盖
	mov word[es:8*4], looper
	mov word[es:8*4+2], cs
	mov word[es:9*4], KeyPress
	mov word[es:9*4+2], cs
	mov ax, cs
	mov es, ax

	;个人信息
	mov ah, 0x13      ;功能号
	mov al, 1         ;光标至串尾
	mov bh, 0         ;第0页
	mov bl, 7         ;颜色白
	mov dl, 0x0       ;第0列
	mov dh, 0x13      ;第13行
	mov bp, mystr     ;内容
	mov cx, [mylen]   ;串长
	int 0x10
	
	.check:
	cmp WORD[back],0
	jz backKernal
	jmp .check

looper:
	;速度计数器
	dec DWORD[counter]
	jnz .outi
	mov DWORD[counter], MOVE_DELAY

	;切换颜色和重置形状
	mov BYTE[ball], BALL_NORMAL
	add WORD[color], 1
	and WORD[color], 00000111b

	;触墙换向
	cmp WORD[posY], BOUND_Y_MAX-1
	jz .up
	cmp WORD[posY], BOUND_Y_MIN+1
	jz .down
	.horizontal:
	cmp WORD[posX], BOUND_X_MAX-1
	jz .left
	cmp WORD[posX], BOUND_X_MIN+1
	jz .right

	;显示图像
	jmp .show

	.move:
		;计算下一次显示位置
		mov ax, [faceX]
		add [posX], ax
		mov ax, [faceY]
		add [posY], ax
	.outi:
		;跳出中断
		mov al,20h
		out 0x20,al
		out 0xA0,al
		iret

	;碰撞函数
	.left:
		mov WORD[faceX], -1
		mov BYTE[ball], BALL_PONG
		jmp .show
	.right:
		mov WORD[faceX], 1
		mov BYTE[ball], BALL_PONG
		jmp .show
	.up:
		mov WORD[faceY], -1
		mov BYTE[ball], BALL_PONG
		jmp .horizontal
	.down:
		mov WORD[faceY], 1
		mov BYTE[ball], BALL_PONG
		jmp .horizontal

	.show:  
		;计算显示坐标
		mov ax,[posY]
		mov bx,SCREEN_X
		mul bx
		add ax,[posX]
		mov bx,2
		mul bx
		mov bx,ax           ;bx = (y*maxx+x)*2

		;修改显存以显示
		mov ax,DISPLAYSEG
		mov es,ax
		mov al,[ball]
		mov ah,[color]
		mov [es:bx],ax      ;ax = al:ah

		jmp .move
		
KeyPress:
	push ax
	push bx
	push cx
	push dx
	push es
	
	in al, 60h
	pushf
	call far [KeyInt]
	mov byte[KeyInput], al
	
	cmp al,0x39
	jne .KeyRet
	dec WORD[back]
	
	mov ax, cs
	mov es, ax
	mov ah, 0x13      ;功能号
	mov al, 1         ;光标至串尾
	mov bh, 0         ;第0页
	mov bl, 7         ;颜色白
	mov dl, 0x5       ;第5列
	mov dh, 0x8       ;第8行
	mov bp, ouchstr     ;内容
	mov cx, [ouchlen]   ;串长
	int 0x10
	
	.KeyRet:
	pop es
	pop dx
	pop cx
	pop bx
	pop ax
	iret
	
backKernal:
	;清屏
	mov WORD[posY],BOUND_Y_MIN
	mov WORD[posX],BOUND_X_MIN

	.clear:
		;计算显示坐标
		mov ax,[posY]
		mov bx,SCREEN_X
		mul bx
		add ax,[posX]
		mov bx,2
		mul bx
		mov bx,ax           ;bx = (y*maxx+x)*2

		;修改显存以显示
		mov ax,DISPLAYSEG
		mov es,ax
		mov al,' '
		mov ah,0
		mov [es:bx],ax

		inc WORD[posX]
		cmp WORD[posX],BOUND_X_MAX
		jne .clear
		mov WORD[posX],BOUND_X_MIN
		inc WORD[posY]
		cmp WORD[posY],BOUND_Y_MAX
		jne .clear
	
	xor ax, ax
	mov es, ax
	;恢复中断
	cli
	pop word[es:8*4+2]
	pop word[es:8*4]
	mov ax, word[KeyInt]
	mov word[es:9*4], ax
	mov ax, word[KeyInt+2]
	mov word[es:9*4+2], ax
	sti
	;恢复栈指针
	pop ax
	pop bx
	mov sp, ax
	mov ss, bx
	pop es
	pop ds
	pop cx
	pop bx
	pop ax
	retf


;constant
DISPLAYSEG  equ 0xB800  	;显存地址
MOVE_DELAY  equ 30   		;字符移动耗时
BOUND_X_MIN equ 0      		;边界X起始
BOUND_Y_MIN equ 0      		;边界Y起始
BOUND_X_MAX equ 40   	    ;边界X终止
BOUND_Y_MAX equ 12   	    ;边界Y终止
SCREEN_X    equ 80   	    ;屏幕宽度
SCREEN_Y    equ 25     		;屏幕高度
BALL_NORMAL equ 'o'    		;平常样式
BALL_PONG   equ '*'     	;撞墙样式
MAXCOUNT    equ 10    		;跳回次数

;variable
counter dd MOVE_DELAY
back    dw MAXCOUNT
posX    dw BOUND_X_MIN
posY    dw BOUND_Y_MIN
faceX   dw 1
faceY   dw 1
ball    db BALL_NORMAL
mystr   db "Created by Weng tianjun 16307064"
mylen   dw 32
ouchstr db "Ouch! Ouch!"
ouchlen dw 11
color   dw 00000000b

KeyInput db 0xFF
KeyInt	 dw 0x0000,0x0000