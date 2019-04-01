org 0x7c00

PAGE_OFFSET equ 0xA100

start:
;设置数据段
  xor ax, ax
  mov ds, ax
  mov ss, ax
  mov es, ax
  mov sp, 0x7c00

showtext:
  mov ah, 0x13      ;功能号
  mov al, 1         ;光标至串尾
  mov bh, 0         ;第0页
  mov bl, 00001010b ;颜色亮绿
  mov dl, 0x10      ;第10列
  mov dh, 0x9       ;第9行
  mov bp, mystr     ;内容
  mov cx, [mylen]   ;串长
  int 0x10

  mov ah, 0x13      ;功能号
  mov al, 1         ;光标至串尾
  mov bh, 0         ;第0页
  mov bl, 00001101b ;颜色分红
  mov dl, 0x10      ;第10列
  mov dh, 0x10      ;第10行
  mov bp, tapstr    ;内容
  mov cx, [taplen]  ;串长
  int 0x10

load:
  ;装入并运行扇区内容
  mov ax, cs
  mov es, ax            ;段地址

  ;等待任意键
  mov ah, 0
  int 0x16

  ;扇区获取
  sub al, '0'
  mov ah, al
  ;扇区参数检验
  sub ah, 1
  jb start
  sub ah, 3
  ja start
  mov cl,al             ;起始扇区号
  add cl,1

  mov bx, PAGE_OFFSET   ;偏移地址
  mov al, 1             ;扇区数
  mov ah, 2             ;功能号
  mov dl, 0             ;驱动器号
  mov dh, 0             ;磁头号
  mov ch, 0             ;柱面号
  int 0x13
  
  jmp PAGE_OFFSET
  
afterRun:
  jmp $

  
mystr   db "Created by Weng tianjun 16307064"
mylen   dw 32
tapstr  db "Press 1,2,3,4 to load different ball"
taplen  dw 36
times 510-($-$$) db 0
dw 0xAA55