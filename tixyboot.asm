; ___________________________________________
;  ▗▄▄▖ ▗▄▖ ▗▖  ▗▖▗▖  ▗▖▗▄▖ ▗▖  ▗▖ ▗▄▖ ▗▖  ▗▖2
; ▐▌   ▐▌ ▐▌▐▛▚▖▐▌ ▝▚▞▘▐▌ ▐▌▐▛▚▞▜▌▐▌ ▐▌▐▛▚▖▐▌
;  ▝▀▚▖▐▛▀▜▌▐▌ ▝▜▌  ▐▌ ▐▌ ▐▌▐▌  ▐▌▐▛▀▜▌▐▌ ▝▜▌ 
; ▗▄▄▞▘▐▌ ▐▌▐▌  ▐▌  ▐▌ ▝▚▄▞▘▐▌  ▐▌▐▌ ▐▌▐▌  ▐▌
;
; ───────────────p r e s e n t s─────────────
;
; _256_bytes_oLdSkool_iNtRo_for OUTLINE 2025
; TIXY in 256 bytes  Sanyo MBC-555 bootsector
; grTz 2 aem1k,nanochess,superogue,zeroZshadow
; ───────────────────────────────────────────

; I love my Sanyo MBC-555 computer from 1983. 
; It's a NOT-so-IBM-compatible 8088 PC. It has
; no real ROM-BIOS and a very inconvenient 
; VRAM mapping. It shipped with MS-DOS 1.25,
; Sanyo BASIC and DEBUG.COM. That got me into
; 8088 assembly programming. My version of DEBUG
; had no 'assemble'-command,so back then I had
; to enter my progams as HEX values.

; My contrib to Outline 2025 is a 256 byte
; Oldskool Intro inspired by tixy.land by aem1k.
; It runs in the bootsector of the Sanyo
; without BIOS or OS.

; During the party I had to reduce my code 
; from 512 to 256 to join the compo. 
; Thanks for all the help and fun!

; Sanyoman aka RickyboyII / 0x03.nl


; The sourcecode for the 512 byte bootsector version
; with circles/dots instead blocks/lines is available at
; https://github.com/companje/tixy.boot


org 0

COLS  equ 72
TOP   equ 9*4*COLS+20*4    ; row=9,col=20
RED   equ 0xf0
GREEN equ 0x08
BLUE  equ 0xf4

; using dx and bx registers as t,i,x,y variables
%define t dh
%define i dl
%define x bh
%define y bl

jmp setup

fx_table:      
    db fx0,fx1,fx2,fx3,fx4,fx5,fx6,fx7

fx0: ; t+x+y
    mov al,t
    add al,x
    add al,y
    ret

fx1: ; x+y+t
    mov al,x
    add al,y
    add al,t
    and al,31
    sub al,15
    ret

fx2: 
    mov al,x
    sub al,y
    sub al,t
    and al,31
    sub al,15
    ret

fx3:
    add al,t
    and al,31
    sub al,15
    ret

fx4: ; xor
    mov al,x
    xor al,y
    add al,t
    and al,31
    sub al,15
    ret

fx5: ; 
    mov al,y
    sub al,x
    mov cl,-8
    mul cl
    add al,t
    and al,31
    sub al,15
    ret

fx6: ; ((y-x)*-8)+t
    mov al,y
    sub al,x
    mov cl,-8
    mul cl
    ;no ret

fx7:
    mov al,x
    inc al
    mul y
    add al,t
    and al,31
    sub al,15
    ret

setup:
    push cs
    pop ds                  ; ds:si in code segment
    push cs
    pop es                  ; es:di in code segment
    xor bp,bp
    xor dx,dx               ; t=i=0 (clear time and index)

.generate_chars:
    mov di,bitmap_data
    mov cx,16*4*4
    mov ax,-1
.lp:
    test cx,3
    jnz .sk
    shr ax,1
.sk:
    stosw
    stosw
    loop .lp

draw:
    and bp,7
    mov di,TOP              ; left top corner to center tixy
dot:
    mov al,i                ; al=index
    xor ah,ah               ; ah=0
    mov cl,16
    div cl                  ; calculate x and y from i
    mov bx,ax

  .cont:
    push bp
    push bx
    xchg bx,bp
    mov bl,[bx+fx_table]
    xor bh,bh
    xchg bx,bp
    pop bx
    call bp                 ; call the effect function
    ; out 0x3a,al           ; sound
    pop bp
 
draw_char_color:
    cmp al,0
    pushf
    jge .red
    neg al
  .red:
    mov cl, 4
    and al,15               ; limit al to 15
    cbw                     ; ah=0
    shl al,cl               ; al*=16
    add ax,bitmap_data

    mov cx,RED << 8         ; ch=0xf0, cl=0
    call draw_char

    popf
    jge .green_blue
    mov ax,bitmap_data ; this is the same as al=0 (empty character)

  .green_blue:
    mov ch,GREEN ; cl is already 0
    call draw_char
    mov ch,BLUE
    call draw_char

  .next:  
    inc i                   ; i++
    add di,8         
    cmp x,15
    jl dot                  ; next col
    add di,4*COLS+160       
    cmp y,15
    jl dot                  ; next line
    inc t
    and t,31
    jnz draw                 ; next frame
    inc bp                  ; inc effect
    jmp draw

draw_char:                  ; es:di=vram (not increasing), al=char 0..15, destroys cx
    push di

    push cx
    pop es                  ; es (color channel was in cx)
    push cs
    pop ds                  ; ds=cs

    mov cx,4
    push cx
    push cx

    mov si,ax              ; si = source address of rendered bitmap char
    pop cx                  ;cx=4
    rep movsw
    
    add di,4*COLS-8         ; next row of 4 lines

    mov si,ax 
    pop cx                  ;cx=4
    rep movsw

    pop di                    
    ret


bitmap_data:  ; destination for 128 bytes rendered bitmap data
    ; there's still a bug in the generate_bitmap code in the setup. 
    ; the bytes below give a better result than generating the dots
    ; but ofcourse it would be much more than 256 bytes
    ; db 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
    ; db 0x0018,0x0018,0x0018,0x0018,0x1800,0x1800,0x1800,0x1800
    ; db 0x001c,0x001c,0x001c,0x001c,0x1c00,0x1c00,0x1c00,0x1c00
    ; db 0x001c,0x001c,0x001c,0x001c,0x1c00,0x1c00,0x1c00,0x1c00
    ; db 0x003c,0x003c,0x003c,0x003c,0x3c00,0x3c00,0x3c00,0x3c00
    ; db 0x003c,0x003c,0x003c,0x003c,0x3c00,0x3c00,0x3c00,0x3c00
    ; db 0x3c3c,0x3c3c,0x3c3c,0x3c3c,0x3c00,0x3c00,0x3c00,0x3c00
    ; db 0x3c3c,0x3c3c,0x3c3c,0x3c3c,0x3c00,0x3c00,0x3c00,0x3c00
    ; db 0x3c3c,0x3c3c,0x3c3c,0x3c3c,0x3c00,0x3c00,0x3c00,0x3c00
    ; db 0x3c3c,0x3c3c,0x3c3c,0x3c3c,0x3c00,0x3c00,0x3c00,0x3c00
    ; db 0x3e3e,0x3e3e,0x3e3e,0x3e3e,0x3e00,0x3e00,0x3e00,0x3e00
    ; db 0x3e3e,0x3e3e,0x3e3e,0x3e3e,0x3e00,0x3e00,0x3e00,0x3e00
    ; db 0x3e3e,0x3e3e,0x3e3e,0x3e3e,0x3e00,0x3e00,0x3e00,0x3e00
    ; db 0xfefe,0xfefe,0xfefe,0xfefe,0xfe00,0xfe00,0xfe00,0xfe00
    ; db 0xffff,0xffff,0xffff,0xffff,0xffff,0xffff,0xffff,0xffff
    ; db 0xffff,0xffff,0xffff,0xffff,0xffff,0xffff,0xffff,0xffff

%assign num $-$$
%warning total num

times (180*1024)-num db  0             
; fill up with zeros until file size=180k to make it work in MAME+GoTek                                                                                                                         π
