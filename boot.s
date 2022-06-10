; assemble this and concatenate sp2.com with it to make it bootable!

[org 0x7C00]
[bits 16]

NUMSEG equ (1993/512)+1 ; filesize is 1993 bytes

mov ax, 0x100
mov ss, ax
mov es, ax
mov gs, ax
mov fs, ax
xor bp, bp
mov sp, bp
push ax
push ax
push ax
mov bx, ax
mov al, NUMSEG
inc ah
xor cx, cx
mov ds, cx
mov word [ds:0x21*4], int21
mov word [ds:0x21*4+2], cx
mov cl, ah
xor dh, dh
int 13h
pop ds
retf

int21:
hlt

times 510 - ($-$$) db 0

dw 0xAA55
