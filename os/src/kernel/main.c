// os/src/kernel/main.c

#include "print.h"
#include "init.h"

int main(void) {
    init_all();
    // asm volatile("sti");	     
    while (1) ;
    return 0;
}
