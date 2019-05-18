;boost
db "boost  ",0x0;名字，固定8字节
dw 1		 	;开始扇区
dw 1		 	;扇区数
dw 0			;时间
dw 1			;类型
;kernal
db "kernal ",0x0;名字，固定8字节
dw 2		 	;开始扇区
dw 72		 	;扇区数
dw 5			;时间
dw 1			;类型
;flist
db "flist  ",0x0;名字，固定8字节
dw 73		 	;开始扇区
dw 1		 	;扇区数
dw 0			;时间
dw 0			;类型
;batch
db "batch.b",0x0;名字，固定8字节
dw 74	  	  	;开始扇区
dw 1		 	;扇区数
dw 22			;时间
dw 3			;类型
;pong1
db "pong1  ",0x0;名字，固定8字节
dw 75		  	;开始扇区
dw 2		  	;扇区数
dw 8			;时间
dw 2			;类型
;pong2
db "pong2  ",0x0;名字，固定8字节
dw 77		  	;开始扇区
dw 2		  	;扇区数
dw 8			;时间
dw 2			;类型
;pong3
db "pong3  ",0x0;名字，固定8字节
dw 79		  	;开始扇区
dw 2		  	;扇区数
dw 8			;时间
dw 2			;类型
;pong4
db "pong4  ",0x0;名字，固定8字节
dw 81		  	;开始扇区
dw 2		  	;扇区数
dw 8			;时间
dw 2			;类型

dw 0xFFFF		;结束标志