org 0
cpu 8086

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
    db fx0,fx1,fx2,fx3,fx4,fx5,fx0,fx1

fx0: ; y+t
    mov al,y
    add al,t
    ret

fx1: ; xor
    mov al,x
    xor al,y
    add al,t
    sub al,7
    ret

fx2: ; sin(x+y+t)
    mov al,x
    add al,y
    add al,t
    ; call sin
    ret

fx3: ; bitmap_data[i+t]
    push bx
    mov al,i
    add al,t
    mov bx,bitmap_data
    xlat
    pop bx
    ret

fx4: ; ((y-x)*-8)+t
    mov al,y
    sub al,x
    mov cl,-8
    mul cl
    ; call limit
    add al,t
    ret

fx5: 
    mov al,x
    add al,y
    add al,t
    ret

setup:                      ; starting point of code

    xor bp,bp

generate_chars:
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
        shr ax,1
        .sk
        stosw
        stosw
    loop .lp

    xor dx,dx               ; t=i=0 (clear time and index)

draw:
    and bp,7
    mov di,TOP              ; left top corner to center tixy
dot:
    mov al,i                ; al=index
    xor ah,ah               ; ah=0
    mov cl,16
    div cl                  ; calculate x and y from i
    xchg ax,bx              ; bh=x, bl=y

  .cont:
   
    push bp
    push bx
    xchg bx,bp
    mov bl,[bx+fx_table]
    xor bh,bh
    xchg bx,bp
    pop bx
    call bp                 ; call the effect function
    
    ; out 0x3a,al

    pop bp
 
draw_char_color:
    cmp al,0
    pushf
    jge .red
    neg al
  .red:
    mov cx,RED << 8              ; ch=0xf0, cl=0
    call draw_char
    popf
    jge .green_blue
    xor al,al               ; if negative then just red so clear (al=0) green and blue
  .green_blue:
    mov ch,GREEN
    call draw_char
    mov ch,BLUE
    call draw_char
  .next:  
    inc i                   ; i++
    ; add i,3

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
    push ax
    push di

    push cx
    pop es                  ; es=bp (color channel now cx)
    push cs
    pop ds                  ; ds=cs

    mov cx,4
    push cx
    push cx

    and al,15               ; limit al to 15
    cbw                     ; ah=0
   
    shl al,cl               ; al*=16
    add ax,bitmap_data
    mov si,ax              ; si = source address of rendered bitmap char

    pop cx                  ;cx=4
    rep movsw
    add di,4*COLS-8

    pop cx                  ;cx=4

    mov si,ax 
    rep movsw

    pop di                    
    pop ax
    ret

%assign num $-$$
%warning total num

bitmap_data:                          ; destination for 128 bytes rendered bitmap data

times (180*1024)-num db  0                 ; fill up with zeros until file size=180k
