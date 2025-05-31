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

fx0: ; y+t
    mov al,t
    ; sub al,i
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
    ;geen ret hier



fx7:
    mov al,x
    ; mov cl,y
    inc al
    mul y
    add al,t
    and al,31
    sub al,15
    ret

setup:                      ; starting point of code


; generate_chars:
    push cs
    pop ds                  ; ds:si in code segment
    push cs
    pop es                  ; es:di in code segment


    mov di,bitmap_data
    mov cx,16*4*4
    mov ax,-1
.lp:
    test cx,3
    jnz .sk
    ; xchg ah,al
    ; mov ax,0x5555
    shr ax,1
.sk:
    stosw
    stosw
    loop .lp





    xor bp,bp
    xor dx,dx               ; t=i=0 (clear time and index)

draw:
    and bp,7
    mov di,TOP              ; left top corner to center tixy
dot:
    mov al,i                ; al=index
    xor ah,ah               ; ah=0
    mov cl,16
    div cl                  ; calculate x and y from i
    ; xchg ax,bx              ; bh=x, bl=y
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
    

    ;more red!
    ; and al,31
    ; sub al,15

    ; out 0x3a,al
    
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

    mov cx,RED << 8              ; ch=0xf0, cl=0
    call draw_char

    popf
    jge .green_blue
    ; xor al,al               ; if negative then just red so clear (al=0) green and blue
    mov ax,bitmap_data ; this is the same as al=0 (empty character)

  .green_blue:
    mov cx,GREEN<<8
    call draw_char
    mov cx,BLUE<<8
    call draw_char

    ; mov ch,GREEN
    ; call draw_char
    ; mov ch,BLUE
    ; call draw_char
    

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
    ; push si
    ; push cx

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
    add di,4*COLS-8

    pop cx                  ;cx=4

    mov si,ax 
    rep movsw

    ; pop cx
    ; pop si
    pop di                    
    ret


bitmap_data:                          ; destination for 128 bytes rendered bitmap data
    ; incbin "Tixy-mini-char-Sheet.spr"

%assign num $-$$
%warning total num

times (180*1024)-num db  0                 ; fill up with zeros until file size=180k
