org 0x7c00

start:
;设置数据段
  xor ax, ax
  mov ds, ax

looper:
  ;时钟计数器
  dec WORD[timer]
  jnz looper
  mov WORD[timer], PRIOD        
  
  ;速度计数器
  dec WORD[counter]
  jnz looper
  mov WORD[counter], MOVE_DELAY

  ;切换颜色和重置形状
  mov BYTE[ball], BALL_NORMAL
  add WORD[color], 1
  and WORD[color], 00000111b

  ;触墙换向
  cmp WORD[posY], SCREEN_Y-1
  jz up
  cmp WORD[posX], SCREEN_X-1
  jz left
  cmp WORD[posY], 1
  jz down
  cmp WORD[posX], 1
  jz right

  ;显示图像
  jmp show

move:
  mov ax, 0
  mov es, ax
  mov ah, 0x13      ;功能号
  mov al, 1         ;光标至串尾
  mov bh, 0         ;第0页
  mov bl, 7         ;颜色白
  mov dl, 0x0       ;第0列
  mov dh, 0x13      ;第13行
  mov bp, mystr     ;内容
  mov cx, [mylen]   ;串长
  int 0x10

  ;计算下一次显示位置
  mov ax, [faceX]
  add [posX], ax
  mov ax, [faceY]
  add [posY], ax
  jmp looper

;碰撞函数
left:
  mov WORD[faceX], -1
  mov BYTE[ball], BALL_PONG
  jmp show
right:
  mov WORD[faceX], 1
  mov BYTE[ball], BALL_PONG
  jmp show
up:
  mov WORD[faceY], -1
  mov BYTE[ball], BALL_PONG
  jmp show
down:
  mov WORD[faceY], 1
  mov BYTE[ball], BALL_PONG
  jmp show

show:
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

  jmp move


;constant
DISPLAYSEG  equ 0xB800  ;显存地址
PRIOD       equ 50000   ;基本计时器单位
MOVE_DELAY  equ 500     ;字符移动速度
SCREEN_X    equ 80      ;屏幕宽度
SCREEN_Y    equ 25      ;屏幕高度
BALL_NORMAL equ 'o'     ;平常样式
BALL_PONG   equ '*'     ;撞墙样式

;variable
timer   dw PRIOD
counter dw MOVE_DELAY
posX    dw 0
posY    dw 0
faceX   dw 1
faceY   dw 1
ball    db BALL_NORMAL
color   db 00000111b
mystr   db "Created by Weng tianjun 16307064"
mylen   dw 32

times 510-($-$$) db 0
dw 0xAA55
