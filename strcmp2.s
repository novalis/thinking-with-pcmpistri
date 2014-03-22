        .global strcmp2

        .text
strcmp2:

loop_start:
        mov $0, %rax
        cmp %al, (%rdi)
        je done_loop

        cmp %al, (%rsi)
        je b_smaller

        movb (%rsi), %al
        # a - b
        cmpb %al, (%rdi)
        jl a_smaller
        jg b_smaller

        inc %rsi
        inc %rdi
        jmp loop_start
        
done_loop:
        # a == 0, so what about b
        movb (%rsi), %al
        cmpb $0, %al
        je equal
        

a_smaller:
        mov $-1, %rax
        ret
b_smaller:
        mov $1, %rax
        ret

equal:
        mov $0, %rax
        ret
