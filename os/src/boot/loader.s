; os/src/boot/loader.s
%include "boot.inc" 
section loader vstart=LOADER_BASE_ADDR 
.begin_loader:
    mov byte [gs:0x00],'L'  ; 字符为M的ascii值
    mov byte [gs:0x01],0x0F	; 11100001b 即背景色为黑，字体为白，不闪烁 
    mov byte [gs:0x02],'O'  ;
    mov byte [gs:0x03],0x0F	; 
    mov byte [gs:0x04],'A'  ;
    mov byte [gs:0x05],0x0F	;
    mov byte [gs:0x06],'D'  ;
    mov byte [gs:0x07],0x0F	;
    mov byte [gs:0x08],'E'  ;
    mov byte [gs:0x09],0x0F	;
    mov byte [gs:0x0A],'R'  ;
    mov byte [gs:0x0B],0x0F	;

; 程序在此处卡住
jmp $
