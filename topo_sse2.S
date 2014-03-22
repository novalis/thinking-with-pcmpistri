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
        .quad 0x2e012e012e012e01
        .quad 0x2e012e012e012e01
slash:
        .quad 0x2f2f2f2f2f2f2f2f
        .quad 0x2f2f2f2f2f2f2f2f
ff:
        .quad 0xffffffffffffff00
        .quad 0xffffffffffffffff
one:
        .quad 0x0101010101010101
        .quad 0x0101010101010101
        .previous

        movdqa range(%rip), %xmm7
        movdqa slash(%rip), %xmm6
        movdqa one(%rip), %xmm5

loop_start:
        #range
        lddqu (%rdi), %xmm1
        pcmpistrm $0x44, %xmm1, %xmm7

        #adjust range
        movdqa %xmm1, %xmm2
        psubb %xmm0, %xmm2

        #now we have all of the chars that were in [1-46], with one added,
        #so [2-47], and all else equal

        #equals --- collect (non-)slashes
        pcmpistrm $0x58, %xmm1, %xmm6

        paddusb %xmm5, %xmm0
        #need to mask slashes out of here...
        #...or just adjust the mask to s/47/1

        pand %xmm0, %xmm2

        #my, this is a lot of instructions just to do this one silly thing...

        #the other register

        #range
        lddqu (%rsi), %xmm1
        pcmpistrm $0x44, %xmm1, %xmm7

        #adjust range
        movdqa %xmm1, %xmm3
        psubb %xmm0, %xmm3

        #now we have all of the chars that were in [1-46], with one added,
        #so [2-47], and all else equal

        #equals --- collect (non-)slashes
        pcmpistrm $0x58, %xmm1, %xmm6

        paddusb %xmm5, %xmm0
        #need to mask slashes out of here...
        #...or just adjust the mask to s/47/1

        pand %xmm0, %xmm3

        #so now we have xmm2, xmm3...

        #for testing:
        #pcmpistrm $0x58, %xmm2, %xmm3

        pcmpistri $0x18, %xmm2, %xmm3

        #c=0: equal (among valid bytes)
        #c=1: differs (among valid bytes)... I think
        #z=1: string a has a 0
        #s=1: string b has a 0

        js diff
        jna diff

        #next iteration
        add %rcx, %rdi
        add %rcx, %rsi
        jmp loop_start

        #c=1, unequal (but all bytes non-zero)
diff:
        #if 0
        movdqa ff(%rip), %xmm5
        movq %rcx, %xmm4
        paddb %xmm4, %xmm5

        pshufb %xmm5, %xmm2
        pshufb %xmm5, %xmm3

        movq %xmm2, %rax
        movq %xmm3, %rdx

        cmp %rax, %rdx
        #endif        
        xor %rax, %rax
        xor %rdx, %rdx
        movb (%rcx,%rdi), %al
        movb (%rcx,%rsi), %dl
        cmp %ax, %dx

        je equal
        jl b_smaller
        jmp a_smaller

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