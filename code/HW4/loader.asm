org 100h

mov ax, 0xB800
mov gs, ax
mov ah, 0Fh
mov al,'L'
mov [gs:(80*0+39)*2],ax

jmp $