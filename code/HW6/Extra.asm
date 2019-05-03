[SECTION .text]
Bullet:
	dec byte[BulletPosX]
	jnz .BulletCheck
	mov byte[BulletPosX],0xFF
	jmp .BulletJmp
	
	.BulletCheck:
	xor cx,cx
	mov bx, BulletStr
	mov cl, byte[BulletPosX]
	cmp cl, BulletLen
	jg .BulletShow
	mov cl, BulletLen
	add bx, BulletLen
	xor ax,ax
	mov al, byte[BulletPosX]
	sub bx, ax

	.BulletShow:
	sub cx, BulletLen
	mov ax,BulletPosY	;行
	push eax
	mov ax, cx	        ;列
	push eax
	mov ax,bx
	push eax
	push 0 ;函数调用兼容
	call ScreenPrintf
	add esp,BIAS_ARG*3
	
	.BulletJmp:
	jmp WindFireWheelWithoutEnemy.SmallLoop
	
	
BigFireWind:
	mov ax,10	;行
	push eax
	mov ax,37	;列
	push eax
	mov al,byte[BigFanCount]
	jmp .CheckFanType

	.FanType1:
	mov ax,BigFanOne
	inc byte[BigFanCount]
	jmp .ShowFan
	.FanType2:
	mov ax,BigFanTwo
	inc byte[BigFanCount]
	jmp .ShowFan
	.FanType3:
	mov ax,BigFanThree
	inc byte[BigFanCount]
	jmp .ShowFan
	.FanType4:
	mov ax,BigFanFour
	inc byte[BigFanCount]
	jmp .ShowFan
	.FanType5:
	mov ax,BigFanFive
	inc byte[BigFanCount]
	jmp .ShowFan
	.FanType6:
	mov ax,BigFanSix
	mov byte[BigFanCount],0x00
	jmp .ShowFan
	
	.CheckFanType:
	cmp al,0x00
	je .FanType1
	cmp al,0x01
	je .FanType2
	cmp al,0x02
	je .FanType3
	cmp al,0x03
	je .FanType4
	cmp al,0x04
	je .FanType5
	cmp al,0x05
	je .FanType6

	.ShowFan:
	push eax
	push 0 ;函数调用兼容
	call ScreenPrintf
	add esp,BIAS_ARG*3
	
	jmp WindFireWheelWithoutEnemy.BulletCheck
	
WindFireWheelWithoutEnemy:
	nop
	nop
	push eax
	push bx
	push cx
	push ds
	push gs
	
	mov bx,cs
	mov ds,bx
	
	dec byte[CoolWheelCounter]
	mov bl, byte[CoolWheelCounter]
	jnz .back
	mov byte[CoolWheelCounter], COOLWHEEL_DELAY
	
	cmp byte[BigFanCount],0xFF
	jne BigFireWind
	.BulletCheck:
	cmp byte[BulletPosX],0xFF
	jne Bullet
	
	.SmallLoop:
	inc word[CoolWheelCharIndex]
	and word[CoolWheelCharIndex],00000011b
	mov bx,word[CoolWheelCharIndex]
	mov	ax,0B800h						; 文本窗口显存起始地址
	mov	gs,ax							; GS = B800h
	mov ah,0Fh							; 0000：黑底、1111：亮白字（默认值为07h）
	mov al,[bx+CoolWheel]				; AL = 显示字符值（默认值为20h=空格符）
	mov [gs:((80*12+39)*2)],ax			; 屏幕第 24 行, 第 79 列
	
	.back:
	mov al,20h			; AL = EOI
	out 20h,al			; 发送EOI到主8529A
	out 0A0h,al			; 发送EOI到从8529A
	
	pop gs
	pop ds
	pop cx
	pop bx
	pop eax
	iret
	
[SECTION .data]
CoolWheel dw "/-\|"
CoolWheelCounter db COOLWHEEL_DELAY
CoolWheelCharIndex dw 0
;弹幕
BulletStr 	db 	"   Reading for the rise of China!   ",0x00
BulletPosX 	db 	0xFF
BulletPosY	equ 10
BulletLen	equ 36

BigFanCount db 0xFF
BigFanOne:
db "  @@ ",0x0A
db "@ @  ",0x0A
db "@@@@@",0x0A
db "  @ @",0x0A
db " @@  ",0x00
BigFanTwo:
db "@  @@",0x0A
db "@ @  ",0x0A
db " @@@ ",0x0A
db "  @ @",0x0A
db "@@  @",0x00
BigFanThree:
db "@@  @",0x0A
db " @ @@",0x0A
db "  @  ",0x0A
db "@@ @ ",0x0A
db "@  @@",0x00
BigFanFour:
db "@@  @",0x0A
db "  @ @",0x0A
db " @@@ ",0x0A
db "@ @  ",0x0A
db "@  @@",0x00
BigFanFive:
db " @@  ",0x0A
db "  @ @",0x0A
db "@@@@@",0x0A
db "@ @  ",0x0A
db "  @@ ",0x00
BigFanSix:
db "  @  ",0x0A
db "  @  ",0x0A
db "@@@@@",0x0A
db "  @  ",0x0A
db "  @  ",0x00