; os/src/boot/loader.s
%include "boot.inc" 
section loader vstart=LOADER_BASE_ADDR ; 程序开始的地址

jmp loader_start

LOADER_STACK_TOP equ LOADER_BASE_ADDR ; 栈顶地址

;构建gdt及其内部的描述符
GDT_BASE:  dd    0x00000000 
	       dd    0x00000000

CODE_DESC: dd    0x0000FFFF 
	       dd    DESC_CODE_HIGH4

DATA_STACK_DESC:  dd    0x0000FFFF
		          dd    DESC_DATA_HIGH4

VIDEO_DESC: dd    0x80000007	       ; limit=(0xbffff-0xb8000)/4k=0x7
	        dd    DESC_VIDEO_HIGH4     ; 此时dpl为0

GDT_SIZE   equ   $ - GDT_BASE
GDT_LIMIT  equ   GDT_SIZE -	1 
times 60 dq 0					 ; 此处预留60个描述符的slot
SELECTOR_CODE  equ (0x0001<<3) + TI_GDT + RPL0   ; 第一个选择子
SELECTOR_DATA  equ (0x0002<<3) + TI_GDT + RPL0	 ; 第二个选择子
SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0	 ; 第三个选择子

; 以下是定义gdt的指针，前2字节是gdt界限，后4字节是gdt起始地址
gdt_ptr  dw  GDT_LIMIT 
	     dd  GDT_BASE

loader_start:
    mov byte [gs:160],'L'
    mov byte [gs:161],0x0F
    mov byte [gs:162],'O'
    mov byte [gs:163],0x0F
    mov byte [gs:164],'A'
    mov byte [gs:165],0x0F   
    mov byte [gs:166],'D'
    mov byte [gs:167],0x0F
    mov byte [gs:168],'E'
    mov byte [gs:169],0x0F
    mov byte [gs:170],'R'
    mov byte [gs:171],0x0F

; 打开A20地址线
open_A20:
    in   al,0x92
    or   al,0000_0010B
    out  0x92,al

; 加载gdt描述符
load_gdt:
    lgdt [gdt_ptr]

; 修改cr0标志寄存器的PE位
change_cr0_PE:
    mov  eax, cr0
    or   eax, 0x00000001
    mov  cr0, eax

jmp SELECTOR_CODE:p_mode_start ; 刷新流水线，避免分支预测的影响
					           ; 远跳将导致之前做的预测失效，从而起到了刷新的作用。

; 下面就是保护模式下的程序了
[bits 32]
p_mode_start:
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp,LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO
    mov gs, ax

    mov byte [gs:320], 'O'
    mov byte [gs:321],0x0F
    mov byte [gs:322], 'K'
    mov byte [gs:323],0x0F

jmp $
