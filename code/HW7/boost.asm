KERNAL_ADDRESS equ 0x8000
KERNAL_OFFSET  equ 0x0100
org 0x7c00
[BITS 16]
start:
	;设置数据段
	mov ax, cs
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7e00

	;读取内核
	mov ah, 02h     										;功能号
	mov dl, 0             									;驱动器号
	mov ch, 0												;柱面号
	mov dh, 0            									;磁头号
	mov cl, 2   											;起始扇区号
	mov al, 17   											;扇区数 
	mov bx, KERNAL_ADDRESS + KERNAL_OFFSET
	int 0x13
	
	mov ah, 02h     										;功能号
	mov dl, 0             									;驱动器号
	mov ch, 0												;柱面号
	mov dh, 1            									;磁头号
	mov cl, 1   											;起始扇区号
	mov al, 18   											;扇区数 
	mov bx, KERNAL_ADDRESS + KERNAL_OFFSET + 512 * 17
	int 0x13
	
	mov ah, 02h     										;功能号
	mov dl, 0             									;驱动器号
	mov ch, 1												;柱面号
	mov dh, 0            									;磁头号
	mov cl, 1   											;起始扇区号
	mov al, 18   											;扇区数 
	mov bx, KERNAL_ADDRESS + KERNAL_OFFSET + 512 * 35
	int 0x13
	
	mov ah, 02h     										;功能号
	mov dl, 0             									;驱动器号
	mov ch, 1												;柱面号
	mov dh, 1            									;磁头号
	mov cl, 1   											;起始扇区号
	mov al, 18   											;扇区数 
	mov bx, KERNAL_ADDRESS + KERNAL_OFFSET + 512 * 35
	int 0x13

	jmp KERNAL_ADDRESS>>4:KERNAL_OFFSET

times 510-($-$$) db 0
dw 0xAA55