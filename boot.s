; assemble this and concatenate sp2.com with it to make it bootable!

[org 0x7C00]
[bits 16]

NUMSEG equ (1993/512)+1 ; filesize is 1993 bytes

mov ax, 0x100
mov ss, ax
mov ds, ax
mov es, ax
mov gs, ax
mov fs, ax
mov bp, 0xF000
mov sp, bp

mov bx, 0x100
mov al, NUMSEG
inc ah
mov cl, ah
xor ch, ch
xor dh, dh
int 13h

xor cx, cx
mov ds, cx
mov word [ds:0x21*4], int21
mov word [ds:0x21*4+2], 0

inc ch
mov ds, cx
push 0x100
push 0x100
retf

int21:
hlt

times 510 - ($-$$) db 0

dw 0xAA55
