; ===================================================================
; port of starport 2 to nasm. i cannot really tell what setborder is
; supposed to do, but the rest works fine. nasm puts out some opcodes
; that differ from tasm so it does not produce an identical binary at
; the hash level, but it is identical in function. see the diff file.
; ===================================================================




;--------------------------------------------------------------------
;                  StarPort Intro II V1.0
;--------------------------------------------------------------------
;              Copyright (C) 1993 Future Crew
;--------------------------------------------------------------------
;                        code: Psi
;                       music: Skaven
;--------------------------------------------------------------------
;    This code is released to the public domain. You can do
;    whatever you like with this code, but remember, that if
;    you are just planning on making another small intro by
;    changing a few lines of code, be prepared to enter the
;    worldwide lamers' club. However, if you are looking at
;    this code in hope of learning something new, go right 
;    ahead. That's exactly why this source was released. 
;    (BTW: I don't claim there's anything new to find here,
;    but it's always worth looking, right?) 
;--------------------------------------------------------------------
;    The code is optimized mainly for size but also a little
;    for speed. The goal was to get this little bbs intro to
;    under 2K, and 1993 bytes sounded like a good size. Well,
;    it wasn't easy, and there are surely places left one could 
;    squeeze a few extra bytes off...
;      Making a small intro is not hard. Making a small intro
;    with a nice feel is very hard, and you have to sacrifice
;    ideas to fit the intro to the limits you have set. I had
;    a lot of plans (a background piccy for example), but well,
;    the size limit came first.
;      I hope you enjoy my choice of size/feature ratio in this
;    intro! In case you are interested, this was a three evening
;    project (the last one spent testing).
;--------------------------------------------------------------------
;    You can compile this with TASM, but the resulting COM-file
;    will be a lot larger than the released version. This is
;    because all the zero data is included to the result. The
;    released version was first compiled to a COM file, and then
;    a separate postprocessing program was ran which removed all
;    the zero data from the end of the file. If you are just 
;    experimenting, recompiling is as easy as MAKE.BAT. If you
;    want to make this small again, you have to do some work as
;    well, and make your own postprocessor.
;--------------------------------------------------------------------

XORTEXTS equ 0x17	; xor's all text characters with this value.
			; original intro binary used 0x17

BORDERS equ 0	;set to 1 for visible border-timings

[bits 16]
org	100h

start:	cld	;filler to make the filesize exactly 1993 bytes
	cld	;filler to make the filesize exactly 1993 bytes
	jmp	main

;±±±±±±±±±±±±±±±± setborder ±±±±±±±±±±±±±±±±
;descr: debug/change border color
	%macro setborder 1
	%if BORDERS
	push	ax
	push	dx
	mov	dx,3dah
	in	al,dx
	mov	dx,3c0h
	mov	al,11h+32
	out	dx,al
	mov	al,%1
	out	dx,al
	pop	dx
	pop	ax
	%endif
	%endmacro

;€€€€€€€€€€€€€€€€ Simplex Adlib Player €€€€€€€€€€€€€€€€
;this doesn't just read raw data to output to adlib like the one
;used in the last starport intro. This player really does have 
;note & instrument data it reads and processes!

;±±±±±±±±±±±±±±±± output data to adlib ±±±±±±±±±±±±±±
a_lodsboutaw03: ;size optimization related entry (instrument loading)
	call	a_lodsboutaw
	add	ah,3
a_lodsboutaw: ;size optimization related entry (instrument loading)
	lodsb
a_outaw:;: ;ah=reg,al=data
	push	ax
	push	cx
	xchg	al,ah
	mov	dx,388h
	out	dx,al
	mov	cx,7
	call	a_wait
	mov	dx,389h
	mov	al,ah
	out	dx,al
	mov	cx,30
	call	a_wait
	pop	cx
	pop	ax
	ret
a_wait:	in	al,dx
	loop	a_wait
	ret

;±±±±±±±±±±±±±±±± load instrument to adlib ±±±±±±±±±±±±±±
a_loadinstrument:;:
	;bx=channel, ds:si=offset to instrument data
	;mov	ah,ds:a_inst_table[bx]
	mov	ah,[bx+a_inst_table]
	mov	cx,4
.l:	call	a_lodsboutaw03
	add	ah,20h-3
	loop	.l
	add	ah,40h
	call	a_lodsboutaw03
	mov	ah,bl
	add	ah,0c0h
	jmp	a_lodsboutaw


;±±±±±±±±±±±±±±±± set note on/off ±±±±±±±±±±±±±±
a_playnote:;:
	;bx=channel, ax=data
	push	bx
	xchg	ah,bl
	add	ah,0a0h
	call	a_outaw
	mov	al,bl
	add	ah,010h
	pop	bx
	jmp	a_outaw

;±±±±±±±±±±±±±±±± initialize/clear/shutup adlib ±±±±±±±±±±±±±±
a_init:
	mov	ax,00120h
	call	a_outaw
	mov	ax,00800h
	call	a_outaw
	mov	ah,0bdh
	call	a_outaw
	mov	bp,9
	xor	bx,bx
	mov	di,music_instruments
.l:	mov	si,[di]
	add	di,2
	call	a_loadinstrument
	xor	ax,ax
	call	a_playnote
	inc	bx
	dec	bp
	jnz	.l	
	ret

;±±±±±±±±±±±±±±±± advance music one row ±±±±±±±±±±±±±±
a_dorow:
	sub	word [a_musiccnt], byte 1
	jnc	.end
	mov	word [a_musiccnt],music_speed
	mov	cx,music_channels
	mov	di,music_patterns
	xor	bx,bx
.lp1:	sub	byte a_chdelaycnt[bx],1
	jns	.lp2
	mov	si,[di]	
	xor	ax,ax
	call	a_playnote
.ldata:	lodsb	
	or	al,al
	jz	.l7
	jns	.l6
	sub	al,81h
	mov	a_chdelay[bx],al
	lodsb
.l6:	mov	dl,al
	and	ax, strict word 15
	mov	bp,ax
	add	bp,bp
	mov	ax,ds:a_note_table[bp]
	shr	dl,2
	;and	dl,not 3
	and	dl,0xFC
	add	ah,dl
	call	a_playnote
	mov	al,a_chdelay[bx]
	mov	a_chdelaycnt[bx],al
	mov	[di],si
.lp2:	add	di,4
	inc	bx
	loop	.lp1
.end:	ret
.l7:	mov	si,[di+2]
	jmp	.ldata

;€€€€€€€€€€€€€€€ Intro Routines €€€€€€€€€€€€€€€€€€€€

;±±±±±±±±±±±±±±±± sin/cos ±±±±±±±±±±±±±±±±
;entry: ax=angle (0..65535)
; exit: ax=muller (-127..127)
addwcos:add	ax,[bx] ;optimized entry for wavesets
	mov	[bx],ax
cos:	add	ax,16384
sin:	mov	bx,ax
	mov	cx,bx
	and	cx,1023
	neg	cx
	add	cx,1023
	shr	bx,10
	mov	ah,sintable[bx]
	xor	al,al
	imul	cx
	push	ax
	push	dx
	mov	ah,sintable[bx+1]
	xor	al,al
	neg	cx
	add	cx,1023
	imul	cx
	pop	bx
	pop	cx
	add	ax,cx
	adc	dx,bx
	shrd	ax,dx,11
	ret

;±±±±±±±±±±±±±±±± rand ±±±±±±±±±±±±±±±±
;returns a random value in range -4096..4095
rand:
	mov	eax,1107030247
	mul	dword [seed]
	add	eax,97177
	mov	[seed],eax
	shr	eax,15
	and	ax,8191
	sub	ax,4096
;size optimizatin, some code moved from after all rand calls
	add	bx,2
	mov	[bx],ax
	ret

;±±±±±±±±±±±±±±±± timer ±±±±±±±±±±±±±±±±
inittimer:
	mov	eax,fs:[8*4]
	mov	[oldint8],eax
	mov	ax,cs
	shl	eax,16
	mov	ax,intti8 ;TODO ?????
	mov	dx,17000 ;70hz
	jmp	ml1
deinittimer:
	mov	eax,[oldint8]
	xor	dx,dx
ml1:	cli
	mov	fs:[8*4],eax
	mov	al,036h
	out	43h,al
	mov	al,dl
	out	40h,al
	mov	al,dh
	out	40h,al
	sti
	ret

intti8: ;timer interrupt
	push	ax
	mov	al,20h
	out	20h,al
	inc	word cs:framecounter
	pop	ax
	iret

;±±±±±±±±±±±±±±±± load indexed palette ±±±±±±±±±±±±±±
setpal:
	;ds:si=pointer to colorindices
	mov	dx,3c8h
	xor	al,al
	out	dx,al
	inc	dx
	mov	cx,8
.l1:	xor	bh,bh
	mov	bl,[si]
	shr	bl,2
	call	setpl2
	mov	bl,[si]
	shl	bx,2
	call	setpl2
	inc	si
	loop	.l1
	ret
setpl2:	and	bx,15*2
	mov	ax,word col0[bx]
	out	dx,al
	mov	al,ah
	out	dx,al
	mov	al,col0[bx+2]
	out	dx,al
	ret

;±±±±±±±±±±±±±± clear & copy videobuffer to screen ±±±±±±±±±±±±±±
clearcopy:
;---copy/clear buf
	xor	edx,edx
	mov	si,vbuf
	mov	bx,4
	mov	cx,200
	mov	di,-4
.l1:	mov	bp,5
.l2:	;REPT	2
	mov	eax,[si]
	add	di,bx
	mov	[si],edx
	add	si,bx
	mov	es:[di],eax

        mov     eax,[si]
        add     di,bx
        mov     [si],edx
        add     si,bx
        mov     es:[di],eax

	dec	bp
	jnz	.l2
	add	si,bx
	dec	cx
	jnz	.l1
	ret

;±±±±±±±±±±±±±± draw a small pixel ±±±±±±±±±±±±±±
pset1: ;ds:di=destination center, si=xmask offset
	mov	al,colb[si]
	or	[di],al
.l1:	ret

;±±±±±±±±±±±±±± draw a big pixel (depending on Z) ±±±±±±±±±±±±±
pset2: ;ds:di=destination center, si=xmask offset
	mov	ax,colbww[si]
	or	[di+0],ax
	or	[di+44],ax
	cmp	bp,8300 ;zcompare for size
	jl	pset3
	;smaller one
	mov	ax,colbw[si]
	or	[di-44],ax
	or	[di+88],ax
	mov	ax,colbv[si]
	or	[di-88],ax
	or	[di+132],ax
	ret
pset3:	;larger one
	or	[di-44],ax
	or	[di+88],ax
	mov	ax,colbw[si]
	or	[di-88],ax
	or	[di+132],ax
	ret

;±±±±±±±±±±±±±± add a letter composed of big dots to dotlist ±±±±±±±±±±±±±
letter3d:
	;bx=letter
	;si=basex
	;bp=basey
	sub	bx,'A'
	jc	.l0
	shl	bx,3
	mov	di,[nextdot]
	mov	cx,8
.l1:	push	cx
	push	si
	mov	cx,8
.l2:	cmp	byte font[bx],0
	je	.l3
	mov	dots[di],si
	mov	dots[di+2],bp
	;zsinus
	push	si
	add	si,[sinus1]
	sar	si,6
	and	si,63
	mov	al,sintable[si]
	cbw
	pop	si
	shl	ax,2
	mov	dots[di+4],ax
	;
	mov	word dots[di+6], pset2
	add	di,8
	and	di,DOTNUM1*8-1
.l3:	inc	bx
	add	si,LETTERDOTSPACING
	loop	.l2
	pop	si
	add	bx,320-8
	add	bp,LETTERDOTSPACING
	pop	cx
	loop	.l1
	mov	[nextdot],di
.l0:	ret

;±±±±±±±±±±±±±± calc 2x2 rotation matrix ±±±±±±±±±±±±±
set3drot:
	;ax=angle,ds:di=pointer to matrix
	push	ax
	call	sin
	mov	[di+r01-r00],ax
	neg	ax
	mov	[di+ar10-r00],ax
	pop	ax
	call	cos
	mov	[di+r00-r00],ax
	mov	[di+ar11-r00],ax
	ret

;±±±±±±±±±±±± rotate point with 2x2 rotation matrix (innerpart) ±±±±±±±±±±±±±
rotate2x2i:
	;(di,bp)->(cx) with matrix half at ds:si
	;this is the inner part, called twice
	push	bx
	mov	ax,di
	imul	word [si]
	mov	cx,ax
	mov	bx,dx
	mov	ax,bp
	imul	word [si+2]
	add	cx,ax
	adc	bx,dx
	shrd	cx,bx,14
	pop	bx
	add	si,4
	ret

;±±±±±±±±±±±±±± advance demo one frame (raw work) ±±±±±±±±±±±±±
doit:
;======wait for border
	setborder 0
	mov	dx,3dah
.lw1:	in	al,dx
	test	al,8
	jnz	.lw1
.lw2:	in	al,dx
	test	al,8
	jz	.lw2
	setborder 30
;======done
	mov	si,[index]
	push	si
	call	setpal
	pop	si
	add	si,9
	cmp	si, index4
	jbe	.li2
	mov	si, index1
.li2:	mov	[index],si
	mov	al,2
	mov	ah,[si+8]
	mov	dx,3c4h
	out	dx,ax
	call	clearcopy
;======do timer simulation stuff
	setborder 28
	xor	cx,cx
	mov	word [scrollsubber],0
	xchg	cx,[framecounter]
	jcxz	.l78
.l77:	push	cx
	add	word [scrollsubber],SCROLLSPEED
	call	doit70
	pop	cx
	loop	.l77
	setborder 26
.l78:;======
;---redraw dots
	mov	cx,DOTNUM
	mov	bx, dots
.l1:	push	cx
	push	bx
	mov	bp,[bx+2]
	mov	di,[bx+4]
	cmp	word [bx+6], pset2
	jne	.l5
	;ysinus
	mov	cx,[bx]
	mov	si,[sinus2]
	add	si,cx
	sar	si,7
	and	si,63
	mov	al,sintable[si]
	cbw
	shl	ax,2
	add	bp,ax
	;scroll
	sub	cx,[scrollsubber]
	mov	[bx],cx
	cmp	cx,-3900
	jl	.l7
	cmp	cx,3900
	jg	.l7
.l5:	;--rotate coordinates
	mov	si, r00
	call	rotate2x2i
	push	cx
	call	rotate2x2i
	pop	di
	mov	bp,[bx]
	mov	si, p00
	push	cx
	call	rotate2x2i
	push	cx
	call	rotate2x2i
	pop	bp
	pop	di
	;bp=Z, cx=X, di=Y
	add	bp,[zadder]
	cmp	bp,1024
	jl	.l7
	;--project
	mov	ax,256
	imul	di
	idiv	bp
	add	ax, strict word 100
	mov	di,ax
	mov	ax,307
	imul	cx
	idiv	bp
	add	ax,160
	mov	si,ax
	;si=SX, di=SY
	mov	ax,[bx+6]
	cmp	si,319
	ja	.l7
	cmp	di,199
	ja	.l7
	;calc dest address & xmask offset
	add	di,di
	mov	di,rows[di]
	add	si,si
	add	di,cols[si]
	;
	call	ax
.l7:	pop	bx
	pop	cx
	add	bx,8
	dec	cx
	jnz	.l1
	ret

;±±±±±±±±±±±±±± advance demo counters 1/70 sec ±±±±±±±±±±±±±
;a separate routine is used to get frame syncronization for
;slower machines (and slow vga cards)
doit70:
;---add sinuses & udforce
	add	word [sinus1],70
	add	word [sinus2],177
	add	dword [udforced],3000
;---set wave1
	mov	bx, wwave
	mov	ax,77
	call	addwcos
	sar	ax,5
	mov	[wave1],ax
;---set zadder
	mov	bx, zwave
	mov	ax,370
	call	addwcos
	sar	ax,3
	add	ax,8888
	mov	[zadder],ax
;---set 3d rotate YZ
	mov	bx, udwave
	mov	ax,[wave1]
	call	addwcos
	imul	word [udforce]
	shrd	ax,dx,8
	mov	di, r00
	call	set3drot
;---set 3d rotate XZ
	mov	bx, lrwave
	mov	ax,200
	call	addwcos
	sar	ax,1
	mov	di, p00
	call	set3drot
;---add more text to 3d scroller
	sub	word [textcnt],SCROLLSPEED
	jnc	.lt1
	mov	word [textcnt],LETTERDOTSPACING*8-1
	mov	si,[text]
	mov	bl,[si]
	xor	bl,XORTEXTS
	and	bx,255
	jz	.lt3
	inc	si
	mov	[text],si
	cmp	bl,32
	jge	.lt4
	shl	bx,SCROLLDELAYSHL
	mov	[textcnt],bx
	jmp	.lt1
.lt4:	mov	bp,0
	mov	si,4100
	call	letter3d
	jmp	.lt1
.lt3:	mov	si, text0
	mov	[text],si
.lt1:	;;;
;======adlib music
	jmp	a_dorow

;€€€€€€€€€€€€€€€€ Main routine €€€€€€€€€€€€€€€€
;stack @ cs:0fffeh

main:
;ÕÕÕÕÕÕÕÕÕ Zero Zerodata & Init Segs ÕÕÕÕÕÕÕ
[bits 16]
	push	cs
	push	cs
	pop	ds
	pop	es
	mov	cx,(zeroend-zerobeg)/2
	mov	di, zerobeg
	xor	ax,ax ;zero used later
	rep	stosw
	mov	dx,0a000h
	mov	es,dx
;segments now set: DS=code/data ES=vram
;ÕÕÕÕÕÕÕÕÕ Check for 386 ÕÕÕÕÕÕÕÕÕ
	push	sp
	pop	dx
	cmp	dx,sp
	jz	.lo1
.lo2:	jmp	endansi ;80(1)86
.lo1:	mov	bx, rows
	sgdt	[bx]
	cmp	byte [bx+5],0
	js	.lo2
;ÕÕÕÕÕÕÕÕÕ Check for VGA ÕÕÕÕÕÕÕÕÕ
	mov	fs,ax ;ax was zero
;segments now set: DS=code/data ES=vram FS=zeropage
	mov	ax,1a00h
	int	10h
	cmp	al,01ah
	jne	endansi ;no vga
	cmp	bl,7
	jb	endansi ;no vga
;ÕÕÕÕÕÕÕÕÕ Initialize - doinit 0 ÕÕÕÕÕÕÕÕÕ
	;copy vga font to font buffer
	mov	ax,13h
	int	10h
	mov	cx,'Z'-'A'+1
	mov	bx,16
	mov	ax,'A'+0eh*256
.la1:	int	10h
	inc	al
	loop	.la1
	mov	cx,8*320/2
	mov	bx, font
	xor	di,di
.la2:	mov	ax,es:[di]
	mov	[di+bx],ax
	add	di,2
	loop	.la2
;ÕÕÕÕÕÕÕÕÕ Initialize - vga ÕÕÕÕÕÕÕÕÕ
	;init videomode 320x200x16
	mov	ax,0dh
	int	10h
	;set up rows/cols/etc
	mov	si,-2
	mov	di, vbuf-44
	mov	bl,128
	xor	bp,bp
	jmp	.lb5
.lb1:	mov	rows[si],di
	mov	colb[si],bl
	mov	colbww[si],cx
	shr	cl,1
	rcr	ch,1
	mov	colbw[si],dx
	shr	dl,1
	rcr	dh,1
	mov	colbv[si],ax
	shr	al,1
	rcr	ah,1
	mov	cols[si],bp
	ror	bl,1
	jnc	.lb4
	inc	bp
.lb5:	mov	cx,0000000011111110b
	mov	dx,0000000001111100b
	mov	ax,0000000000111000b
.lb4:	add	di,44
	add	si,2
	cmp	si,(320)*2
	jle	.lb1
	;set simplex palette order (16 color mode)
	mov	dx,3dah
	in	al,dx
	mov	dl,0c0h
	xor	ax,ax
	mov	cx,16
.lb2:	out	dx,al
	out	dx,al
	inc	al
	loop	.lb2
	mov	al,20h
	out	dx,al
;ÕÕÕÕÕÕÕÕÕ Initialize - doinit ÕÕÕÕÕÕÕÕÕ
	mov	cx,DOTNUM
	mov	bx, dots-2
.lc1:	push	cx
	call	rand
	call	rand
	call	rand
	sar	ax,2
	mov	[bx],ax
	add	bx,2
	mov	word [bx], pset1
	pop	cx
	loop	.lc1
;ÕÕÕÕÕÕÕÕÕ Initialize - others ÕÕÕÕÕÕÕÕÕ
	call	a_init
	call	inittimer
;ÕÕÕÕÕÕÕÕÕ Do the intro stuff ÕÕÕÕÕÕÕÕÕ
again:	call	doit
	mov	ah,1
	int	16h
	jz	again
	mov	ah,0
	int	16h
;ÕÕÕÕÕÕÕÕÕ DeInitialize ÕÕÕÕÕÕÕÕÕ
	call	deinittimer
	call	a_init ;reinitializing adlib shuts it up
;ÕÕÕÕÕÕÕÕÕ Display end ansi (only thing done if no 386 or vga) ÕÕÕÕÕÕÕÕÕ
endansi:mov	ax,3h
	int	10h
	mov	si, endtext
	push	0b800h	;if the user has an MGA or HGC
	pop	es	;it's not my problem :-)
	xor	di,di
	mov	ah,0eh
.l1:	lodsb
	xor	al,XORTEXTS
	cmp	al,31
	jae	.l2
	mov	ah,al
	jmp	.l1
.l2:	jz	.l3
	stosw
	jmp	.l1
.l3:	mov	ax,4c00h
	int	21h
	
;€€€€€€€€€€€€€€€€ Initialized (nonzero) data €€€€€€€€€€€€€€€€

;pointer & delay counter for scrolltext
text	dw	text0
textcnt	dw	1

;3d rotation values (more in zerodata)
udforced:
	dw	0
udforce	dw	64
lrwave	dw	-20000
zwave	dw	16000

sintable: ;sine table (circle is 64 units)
db 0,12,24,36,48,59,70,80,89,98,105,112,117,121,124,126,127,126
db 124,121,117,112,105,98,89,80,70,59,48,36,24,12,0,-12,-24,-36
db -48,-59,-70,-80,-89,-98,-105,-112,-117,-121,-124,-126,-127
db -126,-124,-121,-117,-112,-105,-98,-89,-80,-70,-59,-48,-36
db -24,-12,0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45,48,51,54
db 57,59,62,65,67,70

;adlib player data
a_inst_table:

	db 20h+0,20h+1,20h+2,20h+8,20h+9,20h+10,20h+16,20h+17,20h+18
NTB equ 8192 ;+1024*1
a_note_table:
	dw NTB+363,NTB+385,NTB+408,NTB+432,NTB+458,NTB+485
	dw NTB+514,NTB+544,NTB+577,NTB+611,NTB+647,NTB+868
	;note: a zero word is expected after this table (found in col0)
	
col0	db	 0, 0, 0 ,0	;background color
col1	db	 0,15,35 ,0	;delay color 3
col2	db	16,30,48 ,0	;delay color 2
col3	db	32,45,55 ,0	;delay color 1
col4	db	60,61,62 	;brightest color
	;1	. x . x . x . x . x . x . x . x
	;2	. . x x . . x x . . x x . . x x
	;4	. . . . x x x x . . . . x x x x
	;8	. . . . . . . . x x x x x x x x
;palette indices for 4 palettes. Last number is bitplane to write
;during the frame having this palette
index1	db	04h,34h,24h,34h,14h,34h,24h,34h	,1 ;1248
index2	db	03h,23h,13h,23h,44h,44h,44h,44h	,8 ;8124
index3	db	02h,12h,44h,44h,33h,33h,44h,44h	,4 ;4812
index4	db	01h,44h,33h,44h,22h,44h,33h,44h	,2 ;2481
index	dw	 index1 ;offset to current index

;################## Music - (tune by skaven/fc) ###################
;generated with ST3->SIMPLEXADLIB, handoptimized by psi (283 bytes)
music_channels equ 8
music_speed equ 8
music_instruments:
dw ains6
dw ains2
dw ains4
dw ains3
dw ains3
dw ains1
dw ains1
dw ains4
ains1:
db 65,194,6,0,35,242,240,240,1,0,4
ains2:
db 145,64,135,128,243,111,35,3,1,1,2
ains3:
db 225,33,17,128,17,19,34,34,0,0,12
ains4:
db 97,33,27,0,98,132,86,85,0,0,14
ains6:
db 145,64,135,136,243,111,35,3,1,1,2
music_patterns:
ach0 dw ach0d, ach0dr
ach1 dw  ach1d, ach1dr
ach2 dw  ach2d, ach2dr
ach3 dw  ach3d, ach3d
ach4 dw  ach4d, ach4d
ach5 dw  ach5d, ach5d
ach6 dw  ach6d, ach6d
ach7 dw  ach7d, ach7d
ach0d:
db 081h
ach0dr:
db 057h,050h,050h,055h,057h,050h,055h,057h
db 050h,055h,057h,050h,055h,057h,050h,055h
db 0
ach1d:
db 081h
ach1dr:
db 050h,055h,057h,050h,055h,057h,050h,055h
db 057h,050h,055h,057h,050h,055h,057h,050h
db 0
ach2d:
db 0C0h,050h,084h
db 030h,020h,030h,020h,02Ah,01Ah,02Ah,01Ah
db 030h,020h,030h,020h,02Ah,01Ah,02Ah,01Ah
ach2dr:
db 030h,020h,030h,020h,02Ah,01Ah,02Ah,01Ah
db 025h,015h,025h,015h,028h,018h,02Ah,01Ah
db 0
ach3d:
db 0A0h,050h,040h,0C0h,040h,088h,040h,040h
db 03Ah,042h,090h,045h,088h,040h,042h,040h
db 047h,090h,04Ah,088h,045h,098h,040h
db 0
ach4d:
db 0A0h,050h,030h,0C0h,047h,088h,047h,043h
db 042h,045h,047h,045h,048h,047h,047h,050h
db 052h,084h,050h,04Ah,088h,050h,098h,045h
db 0
ach5d:
db 0C0h,020h,0A0h,010h,010h,090h,010h,02Ah
db 025h,088h,028h,02Ah,090h,010h,02Ah,025h
db 088h,028h,02Ah
db 0
ach6d:
db 0C0h,020h,0A0h,020h,020h,090h,020h,01Ah
db 015h,088h,018h,01Ah,090h,020h,01Ah,015h
db 088h,018h,01Ah
db 0
ach7d:
db 0C0h,00Ch,0FEh,050h,090h,00Ch,081h,04Ah
db 050h,084h,052h,055h,086h,04Ah,081h,050h
db 04Ah,086h,050h,082h,055h,098h,045h
db 0
;#########################################################

SCROLLSPEED equ	90
SCROLLDELAYSHL equ 9
LETTERDOTSPACING equ 128

db 0fch

text0: ;scrolltext (numbers are delays)
	db  31 ^ XORTEXTS
	db  25 ^ XORTEXTS
	db 'C' ^ XORTEXTS
	db 'A' ^ XORTEXTS
	db 'L' ^ XORTEXTS
	db 'L' ^ XORTEXTS
	db ' ' ^ XORTEXTS
	db 'S' ^ XORTEXTS
	db 'T' ^ XORTEXTS
	db 'A' ^ XORTEXTS
	db 'R' ^ XORTEXTS
	db 'P' ^ XORTEXTS
	db 'O' ^ XORTEXTS
	db 'R' ^ XORTEXTS
	db 'T' ^ XORTEXTS
	db   9 ^ XORTEXTS
	db 'F' ^ XORTEXTS
	db 'U' ^ XORTEXTS
	db 'T' ^ XORTEXTS
	db 'U' ^ XORTEXTS
	db 'R' ^ XORTEXTS
	db 'E' ^ XORTEXTS
	db ' ' ^ XORTEXTS
	db 'C' ^ XORTEXTS
	db 'R' ^ XORTEXTS
	db 'E' ^ XORTEXTS
	db 'W' ^ XORTEXTS
	db ' ' ^ XORTEXTS
	db 'W' ^ XORTEXTS
	db 'O' ^ XORTEXTS
	db 'R' ^ XORTEXTS
	db 'L' ^ XORTEXTS
	db 'D' ^ XORTEXTS
	db ' ' ^ XORTEXTS
	db 'H' ^ XORTEXTS
	db 'Q' ^ XORTEXTS
	db   9 ^ XORTEXTS
	db 'C' ^ XORTEXTS
	db 'D' ^ XORTEXTS
	db 'N' ^ XORTEXTS
	db   9 ^ XORTEXTS
	db 'G' ^ XORTEXTS
	db 'R' ^ XORTEXTS
	db 'A' ^ XORTEXTS
	db 'V' ^ XORTEXTS
	db 'I' ^ XORTEXTS
	db 'S' ^ XORTEXTS
	db ' ' ^ XORTEXTS
	db 'E' ^ XORTEXTS
	db 'U' ^ XORTEXTS
	db 'R' ^ XORTEXTS
	db 'O' ^ XORTEXTS
	db   9 ^ XORTEXTS
	db 'A' ^ XORTEXTS
	db 'N' ^ XORTEXTS
	db 'D' ^ XORTEXTS
	db ' ' ^ XORTEXTS
	db 'M' ^ XORTEXTS
	db 'O' ^ XORTEXTS
	db 'R' ^ XORTEXTS
	db 'E' ^ XORTEXTS
	db   0 ^ XORTEXTS

endtext: ;endansi... well... endansiline (numbers are colors)
	db  15 ^ XORTEXTS
	db 'S' ^ XORTEXTS
	db 't' ^ XORTEXTS
	db 'a' ^ XORTEXTS
	db 'r' ^ XORTEXTS
	db 'P' ^ XORTEXTS
	db 'o' ^ XORTEXTS
	db 'r' ^ XORTEXTS
	db 't' ^ XORTEXTS
	db   3 ^ XORTEXTS
	db ' ' ^ XORTEXTS
	db 'ƒ' ^ XORTEXTS
	db 'ƒ' ^ XORTEXTS
	db ' ' ^ XORTEXTS
	db  11 ^ XORTEXTS
	db 'V' ^ XORTEXTS
	db '3' ^ XORTEXTS
	db '2' ^ XORTEXTS
	db 'b' ^ XORTEXTS
	db 'i' ^ XORTEXTS
	db 's' ^ XORTEXTS
	db ' ' ^ XORTEXTS
	db '+' ^ XORTEXTS
	db '3' ^ XORTEXTS
	db '5' ^ XORTEXTS
	db '8' ^ XORTEXTS
	db '-' ^ XORTEXTS
	db '0' ^ XORTEXTS
	db '-' ^ XORTEXTS
	db '8' ^ XORTEXTS
	db '0' ^ XORTEXTS
	db '4' ^ XORTEXTS
	db '4' ^ XORTEXTS
	db '6' ^ XORTEXTS
	db '2' ^ XORTEXTS
	db '6' ^ XORTEXTS
	db ' ' ^ XORTEXTS
	db '+' ^ XORTEXTS
	db '3' ^ XORTEXTS
	db '5' ^ XORTEXTS
	db '8' ^ XORTEXTS
	db '-' ^ XORTEXTS
	db '0' ^ XORTEXTS
	db '-' ^ XORTEXTS
	db '8' ^ XORTEXTS
	db '0' ^ XORTEXTS
	db '4' ^ XORTEXTS
	db '1' ^ XORTEXTS
	db '1' ^ XORTEXTS
	db '3' ^ XORTEXTS
	db '3' ^ XORTEXTS
	db   3 ^ XORTEXTS
	db ' ' ^ XORTEXTS
	db 'ƒ' ^ XORTEXTS
	db 'ƒ' ^ XORTEXTS
	db ' ' ^ XORTEXTS
	db  15 ^ XORTEXTS
	db 'F' ^ XORTEXTS
	db 'C' ^ XORTEXTS
	db '-' ^ XORTEXTS
	db 'W' ^ XORTEXTS
	db 'H' ^ XORTEXTS
	db 'Q' ^ XORTEXTS
	db  31 ^ XORTEXTS
endtext1:

db 0fch


;€€€€€€€€€€€€€€€€ Uninitialized (zero) data €€€€€€€€€€€€€€€€

zerobeg: ;start zero clear from here

rows	dw	320 dup(0)	;offsets to screen rows
cols	dw	320 dup(0)	;offsets to screen cols
colb	db	320 dup(0,0)	;bitmasks for screen cols
colbv	dw	320 dup(0)	;wide -"-
colbw	dw	320 dup(0)	;wider -"-
colbww	dw	320 dup(0)	;very wide -"-

ALIGN 4
	db	44*8 dup(0) ;negative overflow for videobuffer
vbuf:
	db	44*200 dup(0) ;video buffer
	db	44*8 dup(0) ;positive overflow for videobuffer

ALIGN 4
font:
	db	8 dup(320 dup(0)) ;font buffer


DOTNUM1	equ	256	;number of dots used for text
DOTNUM	equ	444	;total number of dots
ALIGN 4
dots:
	dw	DOTNUM dup(0,0,0,0) ;x,y,z,routine data for each dot
	
;2x2 rotation matrices
r00: 	dw	0
ar10: 	dw	0
r01: 	dw	0
ar11: 	dw	0
p00: 	dw	0
p10: 	dw	0
p01: 	dw	0
p11: 	dw	0

;zero initialized 3d rotation stuff
zadder	dw	0
wave1	dw	0
udwave	dw	0
wwave	dw	0
sinus1	dw	0
sinus2	dw	0

;adlib data
a_musiccnt dw	0
a_chdelaycnt db	9 dup(0)
a_chdelay db	9 dup(0)
ALIGN 2

;misc
nextdot	dw	0
scrollsubber dw	0
framecounter dw	0
oldint8	dd	0
seed	dd	0

padder	db	16 dup(0)
zeroend: ;end zero clear here
