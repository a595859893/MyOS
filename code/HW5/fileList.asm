;kernal
db "kernal ",0x0;名字，固定8字节
dw 2		 	;开始扇区
dw 17		 	;扇区数
dw 5			;时间
dw 1			;类型
;flist
db "flist  ",0x0;名字，固定8字节
dw 18		 	;开始扇区
dw 1		 	;扇区数
dw 0			;时间
dw 0			;类型
;pong1
db "pong1  ",0x0;名字，固定8字节
dw 19		  	;开始扇区
dw 1		  	;扇区数
dw 8			;时间
dw 2			;类型
;pong2
db "pong2  ",0x0;名字，固定8字节
dw 20	  	  	;开始扇区
dw 1		 	;扇区数
dw 10			;时间
dw 2			;类型
;batch
db "batch.b",0x0;名字，固定8字节
dw 21	  	  	;开始扇区
dw 1		 	;扇区数
dw 22			;时间
dw 3			;类型
;end
dw 0xFFFF		;结束标志