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

    mov byte [gs:320], 'M'
    mov byte [gs:322], 'A'
    mov byte [gs:324], 'I'
    mov byte [gs:326], 'N'

    call setup_page ; 创建页目录及页表并初始化页内存位图

    ;要将描述符表地址及偏移量写入内存gdt_ptr,一会用新地址重新加载
    sgdt [gdt_ptr]	      ; 存储到原来gdt的位置

    ;将gdt描述符中视频段描述符中的段基址+0xc0000000
    mov ebx, [gdt_ptr + 2]  
    or dword [ebx + 0x18 + 4], 0xc0000000      ;视频段是第3个段描述符,每个描述符是8字节,故0x18。
					                           ;段描述符的高4字节的最高位是段基址的31~24位

    ;将gdt的基址加上0xc0000000使其成为内核所在的高地址
    add dword [gdt_ptr + 2], 0xc0000000

    add esp, 0xc0000000        ; 将栈指针同样映射到内核地址

    ; 把页目录地址赋给cr3
    mov eax, PAGE_DIR_TABLE_POS
    mov cr3, eax

    ; 打开cr0的pg位(第31位)
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    ;在开启分页后,用gdt新的地址重新加载
    lgdt [gdt_ptr]             ; 重新加载

    mov byte [gs:320], 'V'     ;视频段段基址已经被更新,用字符v表示virtual addr
    mov byte [gs:322], 'i'     ;视频段段基址已经被更新,用字符v表示virtual addr
    mov byte [gs:324], 'r'     ;视频段段基址已经被更新,用字符v表示virtual addr
    mov byte [gs:326], 't'     ;视频段段基址已经被更新,用字符v表示virtual addr
    mov byte [gs:328], 'u'     ;视频段段基址已经被更新,用字符v表示virtual addr
    mov byte [gs:330], 'a'     ;视频段段基址已经被更新,用字符v表示virtual addr
    mov byte [gs:332], 'l'     ;视频段段基址已经被更新,用字符v表示virtual addr

    jmp $

setup_page:                      ; 创建页目录及页表
    mov ecx, 4096
    mov esi, 0
.clear_page_dir:                 ; 清理页目录空间
    mov byte [PAGE_DIR_TABLE_POS + esi], 0
    inc esi
    loop .clear_page_dir

.create_pde:				         ; 创建页目录
    mov eax, PAGE_DIR_TABLE_POS
    add eax, 0x1000 			     ; 此时eax为第一个页表的位置及属性,属性全为0
    mov ebx, eax				     ; 此处为ebx赋值，是为.create_pte做准备，ebx为基址。

    ;   下面将页目录项0和0xc00都存为第一个页表的地址，
    ;   一个页表可表示4MB内存,这样0xc03fffff以下的地址和0x003fffff以下的地址都指向相同的页表，
    ;   这是为将地址映射为内核地址做准备
    or eax, PG_US_U | PG_RW_W | PG_P	      ; 页目录项的属性RW和P位为1,US为1,表示用户属性,所有特权级别都可以访问.
    mov [PAGE_DIR_TABLE_POS + 0x0], eax       ; 第1个目录项,在页目录表中的第1个目录项写入第一个页表的位置(0x101000)及属性(7)
    mov [PAGE_DIR_TABLE_POS + 0xc00], eax     ; 一个页表项占用4字节,0xc00表示第768个页表占用的目录项,0xc00以上的目录项用于内核空间,
					                          ; 也就是页表的0xc0000000~0xffffffff共计1G属于内核,0x0~0xbfffffff共计3G属于用户进程.
    sub eax, 0x1000
    mov [PAGE_DIR_TABLE_POS + 4092], eax	  ; 使最后一个目录项指向页目录表自己的地址

;下面创建第一个页表PTE，其地址为0x101000，也就是1MB+4KB的位置，需要映射前1MB内存
    mov ecx, 256				              ; 1M低端内存 / 每页大小4k = 256
    mov esi, 0
    mov edx, PG_US_U | PG_RW_W | PG_P	      ; 属性为7,US=1,RW=1,P=1
.create_pte:
    mov [ebx+esi*4],edx			              ; 此时的ebx已经在上面成为了第一个页表的地址，edx地址为0，属性为7
    add edx,4096                              ; edx+4KB地址
    inc esi                                   ; 循环256次
    loop .create_pte

;创建内核其它页表的PDE
    mov eax, PAGE_DIR_TABLE_POS
    add eax, 0x2000 		                     ; 此时eax为第二个页表的位置
    or eax, PG_US_U | PG_RW_W | PG_P             ; 页目录项的属性为7
    mov ebx, PAGE_DIR_TABLE_POS
    mov ecx, 254			                     ; 范围为第769~1022的所有目录项数量
    mov esi, 769
.create_kernel_pde:
    mov [ebx+esi*4], eax
    inc esi
    add eax, 0x1000
    loop .create_kernel_pde
    ret