org 0xA100

ballstart:
  ;设置数据段
  xor ax, ax
  mov ds, ax

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

.looper:
  ;时钟计数器
  dec WORD[timer]
  jnz .looper
  mov WORD[timer], PRIOD        
  
  ;速度计数器
  dec WORD[counter]
  jnz .looper
  mov WORD[counter], MOVE_DELAY

  ;跳回计数器
  dec WORD[back]
  jz .back

  ;切换颜色和重置形状
  mov BYTE[ball], BALL_NORMAL
  add WORD[color], 1
  and WORD[color], 00000111b

  ;触墙换向
.vertical:
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
  jmp .looper

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

.back:
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

  jmp JUMPADDR


;constant
DISPLAYSEG  equ 0xB800  ;显存地址
PRIOD       equ 50000   ;基本计时器单位
MOVE_DELAY  equ 100     ;字符移动速度
BOUND_X_MIN equ 0       ;边界X起始
BOUND_Y_MIN equ 13      ;边界Y起始
BOUND_X_MAX equ 40      ;边界X终止
BOUND_Y_MAX equ 25      ;边界Y终止
SCREEN_X    equ 80      ;屏幕宽度
SCREEN_Y    equ 25      ;屏幕高度
BALL_NORMAL equ 'o'     ;平常样式
BALL_PONG   equ '*'     ;撞墙样式
MAXCOUNT    equ 100     ;跳回时间
JUMPADDR    equ 0x7c00  ;跳回地址

;variable
timer   dw PRIOD
counter dw MOVE_DELAY
back    dw MAXCOUNT
posX    dw BOUND_X_MIN
posY    dw BOUND_Y_MIN
faceX   dw 1
faceY   dw 1
ball    db BALL_NORMAL
mystr   db "Created by Weng tianjun 16307064"
mylen   dw 32
color   dw 00000000b

times 510-($-$$) db 0   ;方便测试时文件覆盖
dw 0xFFFF