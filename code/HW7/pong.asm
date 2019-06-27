org 0x100
[section .text]
ballstart:
	sti	;不知道为什么中断被关了……
	;设置数据段
	mov ax, cs
	mov ds, ax
	
	;中断覆盖
	xor ax,ax
	mov es,ax
	mov word[es:22h*4], looper
	mov word[es:22h*4+2], cs
	mov ax, cs
	mov es, ax
	
	; 清屏
	mov	ax, 0600h			; AH = 6,  AL = 0
	mov	bx, 0700h			; 黑底白字(BL = 7)
	mov	cl, BOUND_X_MIN		
	mov ch, BOUND_Y_MIN		; 左上角
	mov	dl, BOUND_X_MAX		
	mov	dh, BOUND_Y_MAX		; 右下角
	int	10h					; 调用中断
	
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
	cmp byte[back],1
	jne .check
	
	; 退出线程
	; 清屏
	mov	ax, 0600h			; AH = 6,  AL = 0
	mov	bx, 0700h			; 黑底白字(BL = 7)
	mov	cl, BOUND_X_MIN		
	mov ch, BOUND_Y_MIN		; 左上角
	mov	dl, BOUND_X_MAX		
	mov	dh, BOUND_Y_MAX		; 右下角
	int	10h					; 调用中断
	
	; 线程退出中断调用
	mov ah, 6
	int 21h
	jmp $


looper:
	;速度计数器
	dec DWORD[counter]
	jnz .outi
	mov DWORD[counter], MOVE_DELAY
	dec WORD[back]
	jz .backKernal

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
	
	.backKernal:
		mov byte[back],1
		jmp .outi

[section .data]
;constant
DISPLAYSEG  equ 0xB800  	;显存地址
MOVE_DELAY  equ 100   		;字符移动耗时
BOUND_X_MIN equ 0    		;边界X起始
BOUND_Y_MIN equ 0     		;边界Y起始
BOUND_X_MAX equ 40   	    ;边界X终止
BOUND_Y_MAX equ 12   	    ;边界Y终止
SCREEN_X    equ 80   	    ;屏幕宽度
SCREEN_Y    equ 25     		;屏幕高度
BALL_NORMAL equ 'o'    		;平常样式
BALL_PONG   equ '*'     	;撞墙样式
MAXCOUNT    equ 200     	;跳回次数

;variable
counter dd MOVE_DELAY
back    dw MAXCOUNT
posX    dw BOUND_X_MIN
posY    dw BOUND_Y_MIN
faceX   dw 1
faceY   dw 1
color	dw 0
ball    db BALL_NORMAL
mystr   db "Created by Weng tianjun 16307064"
mylen   dw 32

KeyInput db 0xFF
KeyInt	 dw 0x0000,0x0000