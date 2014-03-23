        .global topo_sse2
	      .type	topo_sse2, @function
        .text
topo_sse2:
        .cfi_startproc
        mov (%rdi), %rdi
        mov (%rsi), %rsi

        /* this bit is from glibc */
	      lea	15(%rdi), %r8 /* this is the addr of the last element in rdi */
	      and	$0xfff, %r8	/* offset into 4K page */
	      sub	$0x1000, %r8	/* subtract 4K pagesize */

	      lea	15(%rsi), %r9 /* similarly rsi */
	      and	$0xfff, %r9
	      sub	$0x1000, %r9

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

table:
        .byte 0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 1, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255

        .previous

        movdqa range(%rip), %xmm7
        movdqa slash(%rip), %xmm6
        movdqa one(%rip), %xmm5

loop_start:
	      add	$16, %r8
	      jg	bytewise_a

	      add	$16, %r9
	      jg	bytewise_b

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
        movdqa ff(%rip), %xmm4
        movq %rcx, %xmm5
        paddb %xmm5, %xmm4

        pshufb %xmm4, %xmm2
        pshufb %xmm4, %xmm3

        movq %xmm2, %rax
        movq %xmm3, %rdx

        cmp %rax, %rdx

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

bytewise_a:
        sub $0x1000, %r8
        add $16, %r9
        jg bytewise_b

        jmp bytewise

bytewise_b:
        jmp bytewise
        sub $0x1000, %r9

bytewise:
        mov $15, %ecx
        xor %rax, %rax
        xor %rdx, %rdx

bytewise_loop:

        movb (%rdi), %al
        movb (%rsi), %dl

        lea table(%rip), %r10
        movb (%r10, %rax), %al

        lea table(%rip), %r10
        movb (%r10, %rdx), %dl

        cmp %rax, %rdx
        jl b_smaller
        jg a_smaller

        inc %rdi
        inc %rsi

        dec %ecx
        jnz bytewise_loop

        jmp loop_start

        .cfi_endproc
