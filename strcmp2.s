# This is a simple version of a qsort-ready strcmp written in assembly
# just for testing. Because it's designed for qsort, it dereferences
# the pointer arguments

        .global simple_asm_strcmp

        .text
simple_asm_strcmp:
        mov (%rdi), %rdi
        mov (%rsi), %rsi
        xor %rax, %rax
        xor %rdx, %rdx

loop_start:
        movb (%rsi), %dl
        movb (%rdi), %al
        
        cmpb $0, %dl
        je done_loop

        cmpb $0, %al
        je done_loop

        # a - b
        cmpb %al, %dl
        jne done_loop

        inc %rsi
        inc %rdi
        jmp loop_start

done_loop:
        sub %rdx, %rax
        ret
