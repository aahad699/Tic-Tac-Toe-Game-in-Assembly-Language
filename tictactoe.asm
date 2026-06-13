data segment       
    new_line db 13, 10, "$"
    
    game_draw db "_|_|_", 13, 10
              db "_|_|_", 13, 10
              db "_|_|_", 13, 10, "$"    
                  
    game_pointer db 9 DUP(?)  
    
    win_flag  db 0 
    move_count db 0          ; counts filled cells (0-9), draw when it hits 9
    player db "0$" 
    
    game_over_message db "GAME OVER", 13, 10, "$"    
    game_start_message db "FA22 Ghosts", 13, 10, "$"
    player_message db "PLAYER $"   
    win_message db " WIN!$"
    draw_message db "IT'S A DRAW!", 13, 10, "$"
    cell_used_message db "CELL ALREADY USED! TRY AGAIN: $"
    type_message db "TYPE A POSITION: $"
ends

stack segment
    dw   128  dup(?)
ends         

extra segment
    
ends

code segment
start:
    ; set segment registers
    mov     ax, data
    mov     ds, ax
    mov     ax, extra
    mov     es, ax

    ; game start   
    call    set_game_pointer    
            
main_loop:  
    call    clear_screen   
    
    lea     dx, game_start_message 
    call    print
    
    lea     dx, new_line
    call    print                      
    
    lea     dx, player_message
    call    print
    lea     dx, player
    call    print  
    
    lea     dx, new_line
    call    print    
    
    lea     dx, game_draw
    call    print    
    
    lea     dx, new_line
    call    print    
    
    lea     dx, type_message    
    call    print            
                        
    ; read draw position                   
    call    read_keyboard
                       
    ; calculate draw position                   
    sub     al, 49               
    mov     bh, 0
    mov     bl, al

    ; --- input validation: check if cell is already used ---
    call    check_cell_used
    cmp     ah, 1
    je      cell_taken
    ; --- end validation ---
                                  
    call    update_draw
    inc     move_count           ; increment move counter after a valid move
                                                          
    call    check  
                       
    ; check if someone won                   
    cmp     win_flag, 1  
    je      game_over

    ; check for draw (all 9 cells filled, no winner)
    cmp     move_count, 9
    je      game_draw_end
    
    call    change_player 
            
    jmp     main_loop

cell_taken:
    ; reprint board with error message, ask again
    call    clear_screen

    lea     dx, game_start_message
    call    print

    lea     dx, new_line
    call    print

    lea     dx, player_message
    call    print
    lea     dx, player
    call    print

    lea     dx, new_line
    call    print

    lea     dx, game_draw
    call    print

    lea     dx, new_line
    call    print

    lea     dx, cell_used_message
    call    print

    call    read_keyboard

    sub     al, 49
    mov     bh, 0
    mov     bl, al

    call    check_cell_used
    cmp     ah, 1
    je      cell_taken          ; keep looping until a free cell is chosen

    call    update_draw
    inc     move_count

    call    check

    cmp     win_flag, 1
    je      game_over

    cmp     move_count, 9
    je      game_draw_end

    call    change_player
    jmp     main_loop


; --- check_cell_used ---
; Input:  BX = zero-based cell index (0-8)
; Output: AH = 1 if cell is already taken, AH = 0 if free
check_cell_used:
    push    bx
    mov     bl, game_pointer[bx]
    mov     bh, 0
    mov     al, ds:[bx]
    pop     bx
    cmp     al, "_"
    je      cell_free
    mov     ah, 1               ; cell is taken
    ret
    cell_free:
    mov     ah, 0               ; cell is free
    ret


change_player:   
    lea     si, player    
    xor     ds:[si], 1 
    
    ret
      
 
update_draw:
    mov     bl, game_pointer[bx]
    mov     bh, 0
    
    lea     si, player
    
    cmp     ds:[si], "0"
    je      draw_x     
                  
    cmp     ds:[si], "1"
    je      draw_o              
                  
    draw_x:
    mov     cl, "x"
    jmp     update

    draw_o:          
    mov     cl, "o"  
    jmp     update    
          
    update:         
    mov     ds:[bx], cl
      
    ret 
       
       
check:
    call    check_line
    ret     
       
       
check_line:
    mov     cx, 0
    
    check_line_loop:     
    cmp     cx, 0
    je      first_line
    
    cmp     cx, 1
    je      second_line
    
    cmp     cx, 2
    je      third_line  
    
    call    check_column
    ret    
        
    first_line:    
    mov     si, 0   
    jmp     do_check_line   

    second_line:    
    mov     si, 3
    jmp     do_check_line
    
    third_line:    
    mov     si, 6
    jmp     do_check_line        

    do_check_line:
    inc     cx
  
    mov     bh, 0
    mov     bl, game_pointer[si]
    mov     al, ds:[bx]
    cmp     al, "_"
    je      check_line_loop
    
    inc     si
    mov     bl, game_pointer[si]    
    cmp     al, ds:[bx]
    jne     check_line_loop 
      
    inc     si
    mov     bl, game_pointer[si]  
    cmp     al, ds:[bx]
    jne     check_line_loop
                 
                         
    mov     win_flag, 1
    ret         
       
       
       
check_column:
    mov     cx, 0
    
    check_column_loop:     
    cmp     cx, 0
    je      first_column
    
    cmp     cx, 1
    je      second_column
    
    cmp     cx, 2
    je      third_column  
    
    call    check_diagonal
    ret    
        
    first_column:    
    mov     si, 0   
    jmp     do_check_column   

    second_column:    
    mov     si, 1
    jmp     do_check_column
    
    third_column:    
    mov     si, 2
    jmp     do_check_column        

    do_check_column:
    inc     cx
  
    mov     bh, 0
    mov     bl, game_pointer[si]
    mov     al, ds:[bx]
    cmp     al, "_"
    je      check_column_loop
    
    add     si, 3
    mov     bl, game_pointer[si]    
    cmp     al, ds:[bx]
    jne     check_column_loop 
      
    add     si, 3
    mov     bl, game_pointer[si]  
    cmp     al, ds:[bx]
    jne     check_column_loop
                 
                         
    mov     win_flag, 1
    ret        


check_diagonal:
    mov     cx, 0
    
    check_diagonal_loop:     
    cmp     cx, 0
    je      first_diagonal
    
    cmp     cx, 1
    je      second_diagonal                         
    
    ret    
        
    first_diagonal:    
    mov     si, 0                
    mov     dx, 4 ;tamanho do pulo
    jmp     do_check_diagonal   

    second_diagonal:    
    mov     si, 2
    mov     dx, 2
    jmp     do_check_diagonal       

    do_check_diagonal:
    inc     cx
  
    mov     bh, 0
    mov     bl, game_pointer[si]
    mov     al, ds:[bx]
    cmp     al, "_"
    je      check_diagonal_loop
    
    add     si, dx
    mov     bl, game_pointer[si]    
    cmp     al, ds:[bx]
    jne     check_diagonal_loop 
      
    add     si, dx
    mov     bl, game_pointer[si]  
    cmp     al, ds:[bx]
    jne     check_diagonal_loop
                 
                         
    mov     win_flag, 1
    ret  
           

game_over:        
    call    clear_screen   
    
    lea     dx, game_start_message 
    call    print
    
    lea     dx, new_line
    call    print                          
    
    lea     dx, game_draw
    call    print    
    
    lea     dx, new_line
    call    print

    lea     dx, game_over_message
    call    print  
    
    lea     dx, player_message
    call    print
    
    lea     dx, player
    call    print
    
    lea     dx, win_message
    call    print 

    jmp     fim


game_draw_end:
    call    clear_screen

    lea     dx, game_start_message
    call    print

    lea     dx, new_line
    call    print

    lea     dx, game_draw
    call    print

    lea     dx, new_line
    call    print

    lea     dx, draw_message
    call    print

    jmp     fim
  
     
set_game_pointer:
    lea     si, game_draw
    lea     bx, game_pointer          
              
    mov     cx, 9   
    
    loop_1:
    cmp     cx, 6
    je      add_1                
    
    cmp     cx, 3
    je      add_1
    
    jmp     add_2 
    
    add_1:
    add     si, 1
    jmp     add_2     
      
    add_2:                                
    mov     ds:[bx], si 
    add     si, 2
                        
    inc     bx               
    loop    loop_1 
 
    ret  
         
       
print:      ; print dx content  
    mov     ah, 9
    int     21h   
    
    ret 
    

clear_screen:       ; get and set video mode
    mov     ah, 0fh
    int     10h   
    
    mov     ah, 0
    int     10h
    
    ret
       
    
read_keyboard:  ; read keybord and return content in ah
    mov     ah, 1       
    int     21h  
    
    ret      
      
      
fim:
    jmp     fim         
      
code ends

end start
