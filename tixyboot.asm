; tixyboot.asm by Rick Companje, 2021-2022, MIT licence
; a tribute to Martin Kleppe's beautiful https://tixy.land
; as well as a tribute to the Sanyo MBC-550/555 PC (1984)
; which forced me to be creative with code since 1994.
;
; The Sanyo MBC-55x has a very limited ROM BIOS. After some 
; hardware setup by the ROM BIOS a RAM BIOS loaded from
; floppy takes over. This means that we don't have any BIOS
; functions when running our own code from the bootsector. 
;
; The Sanyo has no display mode 13 (not even with the original
; RAM BIOS). It uses a 6845 video chip with three bitmapped 
; graphics planes and is organized as 50 rows by 72 (or 80) columns.
; One column consists of 4 bytes. Then the next column starts.
; After 72 columns a new row starts. A bitmap of 16x8 pixels 
; is made up of 2 columns on row 1 and 2 columns on row 2...
;
; To run this code write the compiled code to the bootsector of a
; Sanyo MBC-55x floppy or use an emulator like the one written
; in Processing/Java in this repo.
;
; Add your own visuals by adding your own functions to the fx_table.
;
; t = time  0..255
; i = index 0..255
; x = x-pos 0..15
; y = y-pos 0..15
;
; result: al -15..15 (size and color)
;         al<0 red, al>0 white

org 0
cpu 8086

COLS  equ 72
TOP   equ 9*4*COLS+20*4    ; row=9,col=20
RED   equ 0xf0
GREEN equ 0x08
BLUE  equ 0xf4

; effect_timeout equ 20      ; every 30 frames another effect
; isqrt_table    equ 1000    ; available location in code segment
; NUM_EFFECTS equ 6


; using dx and bx registers as t,i,x,y variables
%define t dh
%define i dl
%define x bh
%define y bl

jmp setup

fx_table:      
    db fx0,fx1,fx2, fx3,fx4,fx5,fx0, fx1
    ; db fx0,fx0,fx0,fx0,fx0

; sin_table: ;31 bytes, (input -15..15 index=0..31)
;     db 0,-3,-6,-9,-11,-13,-15,-15,-15,-15,-13,-11,-9,-6,-3,
;     db 0, 3, 6, 9, 11, 13, 15, 15, 15, 15, 13, 11, 9, 6, 3,0  
;     ; tried to mirror the second line of the sine table with code 
    ; but would take a same of amount of bytes


fx0: ; y+t
    mov al,y
    add al,t
    ret

fx1: ; xor
    mov al,x
    xor al,y
    add al,t
    sub al,7

    ; cmp i,128
    ; jne .r
.r:
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

fx5: ; sin(sqrt(x^2+y^2))-t)
    ; mov al,i   ; isqrt_table[i] = sqrt(x^2+y^2)
    ; push bx
    ; mov bx,isqrt_table
    ; xlat
    ; pop bx
    ; sub al,t
    ; call sin
    mov al,x
    add al,y
    add al,t
    
    ; mov cl,3
    ; shl al,cl
    ; times 4 add al,t

    ; cbw
    ; xor al,ah
    ; mov cl,2
    ; shr al,cl

    ; call wrap
    ; call sin
    ret

; sin: ; sine function
;     call wrap
;     push bx
;     add al,15 ; sin(-15) = sin_table[0]
;     mov bx,sin_table
;     xlat 
;     pop bx
;     ret

; wrap: ; while (al>15) al-=15; while (al<-15) al+=15
;     cmp al,15
;     jg .sub16
;     cmp al,-15
;     jl .add16
;     ret
;   .sub16:
;     sub al,31
;     jmp wrap
;   .add16:
;     add al,31
;     jmp wrap




; limit: ; if (al>15) al=15; else if (al<-15) al=-15;
;     cmp al,15
;     jg .pos16
;     cmp al,-15
;     jnl .ret
;     mov al,-15
;     ret
;   .pos16:
;     mov al,15
;   .ret:
;     ret

; calc_isqrt_xx_yy: ; isqrt_table[i] = sqrt(x^2+y^2)
;     push dx
;     push di
;     mov di,isqrt_table      ; di=isqrt_table[0]
;     add di,dx               ; di+=i
;     mov al,x
;     inc al
;     mul al                  ; x*x
;     xchg ax,cx
;     mov al,y
;     inc al
;     mul al                  ; y*y
;     add ax,cx               ; + 
;   .isqrt:  ; while((L+1)^2<=y) L++; return L
;     xchg cx,ax              ; cx=y
;     xor ax,ax               ; ax=L=0
;   .loop:
;     inc ax
;     push ax
;     mul ax
;     cmp ax,cx
;     pop ax
;     jl .loop
;     dec ax
;   .end_isqrt:
;     mov [di],al             ; store al
;     pop di
;     pop dx
;     ret

setup:                      ; starting point of code

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

;     mov si,img
;     mov cl,12
; .lp:
;     push cx
;     mov cl,3
; .lp2:
;     push si
;     movsw
;     movsw
;     pop si
;     loop .lp2
;     pop cx
;     movsw
;     movsw
;     loop .lp

    ; mov cl,8
    ; mov ax,-1
    ; rep stosw

    ; ret


    ;no need to clear the screen. ROM BIOS does this already.

    ;set ds and es segments to cs
    ; push cs
    ; pop ds                  ; ds:si in code segment
    ; push cs
    ; pop es                  ; es:di in code segment

    ; generate 16x8 bitmap data for 16 sizes of dots.
    ; Because the dots are symmetric we can save at least
    ; 97 bytes by mirroring the left-top corner 3 times

    ; call generate_chars

    ; xor bp,bp               ; start with effect 0
    xor dx,dx               ; t=i=0 (clear time and index)

draw:
    and bp,7
    mov di,TOP              ; left top corner to center tixy
dot:
    ; push dx
    mov al,i                ; al=index
    xor ah,ah               ; ah=0
    mov cl,16
    div cl                  ; calculate x and y from i
    xchg ax,bx              ; bh=x, bl=y
    ; pop dx

    ;on the first frame calc sqrt table for every i
    ;reusing the i,x,y loop here. this saves some bytes.
    ; or t,t
    ; jnz .cont
    ; call calc_isqrt_xx_yy
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
    ; add t,4
    ; cmp t,effect_timeout
    jnz draw                 ; next frame
    inc bp                  ; inc effect
    ; xor t,t                 ; reset time
    ; cmp bp,NUM_EFFECTS                 
    
    ; jl draw                 ; next effect
    ; xor bp,bp               ; reset effect
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



img:
    ; incbin "Tixy-mini-char-Sheet.spr"

%assign num $-$$
%warning total num

bitmap_data:                          ; destination for 128 bytes rendered bitmap data

times (180*1024)-num db  0                 ; fill up with zeros until file size=360k