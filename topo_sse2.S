        .global topo_sse2
	      .type	topo_sse2, @function
        .text
topo_sse2:
        .cfi_startproc 
        mov (%rdi), %rdi
        mov (%rsi), %rsi

        # set up constants for comparison
        .section .rodata.cst16,"aM",@progbits,16
        .align 16

range:
        .quad 0x012e012e012e012e
        .quad 0x012e012e012e012e
slash:
        .quad 0x2e2e2e2e2e2e2e2e
        .quad 0x2e2e2e2e2e2e2e2e
one:
        .quad 0x0101010101010101
        .quad 0x0101010101010101
ff:
        .quad 0xffffffffffffffff
        .quad 0xffffffffffffffff
        .previous

        movdqa range(%rip), %xmm7
        movdqa slash(%rip), %xmm6
        movdqa  one(%rip), %xmm5
        movdqa  ff(%rip), %xmm4

        mov $0, %rcx
loop_start:
        #range
        movdqu (%rdi), %xmm1
        pcmpistrm $0x4, %xmm1, %xmm7

        #adjust range
        paddusb %xmm1, %xmm0
        #now we have all of the chars that were in [1-46], with one added,
        #so [2-47], and nothing else
        movdqa %xmm0, %xmm2

        #equals --- collect slashes
        pcmpistrm $0x48, %xmm1, %xmm6
        pand %xmm6, %xmm0
        por %xmm0, %xmm2

        #my, this is a lot of instructions just to do this one silly thing...

        #the other register
        
        #range
        movdqu (%rsi), %xmm1
        pcmpistrm $0x4, %xmm1, %xmm7

        #adjust range
        paddusb %xmm1, %xmm0
        #now we have all of the chars that were in [1-46], with one added,
        #so [2-47], and nothing else
        movdqa %xmm0, %xmm3

        #equals --- collect slashes
        pcmpistrm $0x48, %xmm1, %xmm6
        pand %xmm6, %xmm0
        por %xmm0, %xmm3

        #so now we have xmm2, xmm3...
        pcmpistri $0x38, %xmm2, %xmm3

        #c=0: equal (among valid bytes)
        #c=1: differs (among valid bytes)... I think
        #z=1: string a has a 0
        #s=1: string b has a 0
        
        jz check_a
        js diff #b has a zero, but a could still be smaller
        jnc next
        
        #c=1, unequal (but all bytes non-zero)
diff:
        movb (%rcx,%rdi), %al
        movb (%rcx,%rsi), %dl
        cmp %al, %dl
        je equal
        jl b_smaller
        jmp a_smaller
        
check_a:
        #a has a zero in it -- does b?
        jns a_smaller #nope

        jmp diff
        
next:  
        add %rcx, %rdi
        add %rcx, %rsi
        jmp loop_start

equal:
        xor %rax, %rax
        ret
a_smaller:
        mov $-1, %rax
        ret
b_smaller:
        mov $1, %rax
        ret
        .cfi_endproc 