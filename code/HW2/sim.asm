org 0x100

simstart:
  mov bx,char
  mov ax,0xB800
  mov es,ax

  mov al,'!'
  mov ah,7
  mov [es:0],ax
  jmp $

char db 'k'
times 510-($-$$) db 0
dw 0xAA55