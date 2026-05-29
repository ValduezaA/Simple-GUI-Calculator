org 100h

jmp start

; ================================================
; DATA SEGMENT
; ================================================
num789 db " 7   8   9   +  - "
len789 equ $ - num789

num456 db " 4   5   6   *  / "
len456 equ $ - num456

num123 db " 1   2   3   " 
len123 equ $ - num123

num0   db "     0   x   =  " 
len0   equ $ - num0   

; UI Variables
disp_row    dw 8      
cursor_col  dw 30     

; Math Variables
current_val dw 0      
operand1    dw 0      
operator    db 0      

; ================================================
; CODE SEGMENT
; ================================================
start:
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; 1. Set Video Mode
    mov ax, 0003h
    int 10h 

    ; 2. Clear Screen
    mov ax, 0600h    
    mov bh, 00h      
    mov cx, 0000h    
    mov dh, 24       
    mov dl, 79       
    int 10h

    ; ================================================
    ; 3. Draw Pink Frame
    ; ================================================
    
    ; --- TOP BORDER ---
    mov dh, 7           
    mov dl, 29          
    mov cx, 20          
draw_top_pink:
    mov ah, 02h         
    int 10h
    mov ah, 09h         
    mov al, 0xC4        
    cmp dl, 29
    jne check_top_right
    mov al, 0xDA        
    jmp print_top
check_top_right:
    cmp dl, 48
    jne print_top
    mov al, 0xBF        
print_top:
    mov bl, 0Dh         ; Pink
    push cx
    mov cx, 1           
    int 10h
    pop cx
    inc dl
    loop draw_top_pink

    ; --- BOTTOM BORDER ---
    mov dh, 15          
    mov dl, 29
    mov cx, 20
draw_bottom_pink:
    mov ah, 02h
    int 10h
    mov ah, 09h
    mov al, 0xC4        
    cmp dl, 29
    jne check_bot_right
    mov al, 0xC0        
    jmp print_bot
check_bot_right:
    cmp dl, 48
    jne print_bot
    mov al, 0xD9        
print_bot:
    mov bl, 0Dh         ; Pink
    push cx
    mov cx, 1
    int 10h
    pop cx
    inc dl
    loop draw_bottom_pink

    ; --- LEFT SIDE ---
    mov dh, 8           
    mov dl, 29          
    mov cx, 7           
draw_left_pink:
    mov ah, 02h
    int 10h
    mov ah, 09h
    mov al, 0xB3        
    mov bl, 0Dh         
    push cx
    mov cx, 1
    int 10h
    pop cx
    inc dh
    loop draw_left_pink

    ; --- RIGHT SIDE ---
    mov dh, 8           
    mov dl, 48          
    mov cx, 7           
draw_right_pink:
    mov ah, 02h
    int 10h
    mov ah, 09h
    mov al, 0xB3        
    mov bl, 0Dh         
    push cx
    mov cx, 1
    int 10h
    pop cx
    inc dh
    loop draw_right_pink

    ; --- 4. SEPARATOR LINE (New) ---
    mov dh, 9           ; Row between result (8) and numbers (10)
    mov dl, 30
    mov cx, 18
draw_separator:
    mov ah, 02h
    int 10h
    mov ah, 09h
    mov al, 0xCD        ; Double horizontal line
    mov bl, 0Dh         ; Pink color
    push cx
    mov cx, 1
    int 10h
    pop cx
    inc dl
    loop draw_separator

    ; 5. Draw Result Area (Now Black)
    call Clear_Display_Box

    ; 6. Draw Buttons (Pink Text)
    mov ah, 13h     
    mov al, 01h     
    mov bh, 00h     
    mov bl, 0Dh      
    
    mov cx, len789  
    mov dl, 30      
    mov dh, 10      
    mov bp, offset num789  
    int 10h          

    mov cx, len456  
    mov dl, 30      
    mov dh, 11      
    mov bp, offset num456  
    int 10h  

    mov cx, len123  
    mov dl, 30      
    mov dh, 12      
    mov bp, offset num123  
    int 10h  

    mov cx, len0 
    mov dl, 30      
    mov dh, 13      
    mov bp, offset num0  
    int 10h  

    ; 7. Initialize Mouse
    mov ax, 0000h    
    int 33h
    mov ax, 0001h    
    int 33h

; ================================================
; MAIN INTERACTION LOOP
; ================================================
Main_Mouse_Loop:
    mov ax, 0003h
    int 33h
    cmp bx, 1
    jne Main_Mouse_Loop     

    shr cx, 3               
    shr dx, 3               

    mov ax, 0B800h
    mov es, ax              
    mov ax, 80
    mul dx                  
    add ax, cx              
    shl ax, 1               
    mov di, ax              
    mov bl, es:[di]         

    cmp bl, 'x'
    je Clear_Logic

    cmp bl, '='             
    je Check_Equals

    cmp bl, '0'
    jl Check_Operators      
    cmp bl, '9'
    jg Wait_For_Release     

    push bx                 
    sub bl, '0'             
    mov bh, 0               
    mov ax, current_val     
    mov cx, 10
    mul cx                  
    add ax, bx              
    mov current_val, ax     
    pop bx                  

    cmp cursor_col, 46
    jg Wait_For_Release     

    mov ax, 80
    mul disp_row            
    add ax, cursor_col      
    shl ax, 1               
    mov di, ax              
    mov al, bl              
    mov ah, 0Dh              ; PINK text on BLACK background
    stosw                   
    inc cursor_col          
    jmp Wait_For_Release    

Clear_Logic:
    mov current_val, 0
    mov operand1, 0
    mov operator, 0
    call Clear_Display_Box
    mov cursor_col, 30
    jmp Wait_For_Release

Check_Operators:
    cmp bl, '+'
    je Setup_Operator
    cmp bl, '-'
    je Setup_Operator
    cmp bl, '*'
    je Setup_Operator
    cmp bl, '/'
    je Setup_Operator
    jmp Wait_For_Release         

Setup_Operator:
    mov ax, current_val     
    mov operand1, ax        
    mov current_val, 0      
    mov operator, bl        
    call Clear_Display_Box  
    mov cursor_col, 30      
    jmp Wait_For_Release

Check_Equals:
    mov ax, operand1
    mov bx, current_val
    cmp operator, '+'
    je Do_Add
    cmp operator, '-'
    je Do_Sub
    cmp operator, '*'
    je Do_Mul
    cmp operator, '/'
    je Do_Div
    jmp Finish_Math          

Do_Add: add ax, bx
    jmp Finish_Math
Do_Sub: sub ax, bx
    jmp Finish_Math
Do_Mul: mul bx
    jmp Finish_Math
Do_Div: cmp bx, 0
    je Finish_Math          
    mov dx, 0               
    div bx

Finish_Math:
    mov current_val, ax     
    call Clear_Display_Box  
    mov cursor_col, 30      
    mov cx, 0               
    mov bx, 10              
Divide_Loop:
    mov dx, 0               
    div bx                  
    push dx                 
    inc cx                  
    cmp ax, 0               
    jne Divide_Loop         
Print_Answer_Loop:
    pop bx                  
    add bl, '0'             
    mov ax, 80
    mul disp_row            
    add ax, cursor_col      
    shl ax, 1               
    mov di, ax              
    mov al, bl              
    mov ah, 0Dh              ; PINK text on BLACK background
    stosw                   
    inc cursor_col          
    loop Print_Answer_Loop  

Wait_For_Release:
    mov ax, 0003h
    int 33h
    cmp bx, 0               
    jne Wait_For_Release    
    jmp Main_Mouse_Loop     

; ================================================
; PROCEDURES
; ================================================
Clear_Display_Box PROC
    push ax
    push bx
    push cx
    push dx
    mov ax, 0600h    
    mov bh, 00h      ; 00h = Black background
    mov ch, 8        
    mov cl, 30       
    mov dh, 8        
    mov dl, 46       
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
Clear_Display_Box ENDP

ret
