;Accept86 WorkingNavi / Saria Repeats hints
;==================================================================================================


TextLoadLogic_HOOK:
    addiu   sp, sp, -0x20
    sw      ra, 0x0014(sp)
    sw      a2, 0x0018(sp)
    sw      a1, 0x001c(sp)
    
;====Saria Repeats Hints==== ;TBD only if activated
;I want to make sure the Saria Texts get actually displayed before saving the id
;The Textpointer borders can change on every seed/version, so I have to dynamicly read them

    lw t2, SARIA_HINTS_CONDITION
 beq t2, r0, @@TEXTLOAD_WNAVI
    nop

    jal @checkGossipText
    nop
    
    lw      a1, 0x001c(sp)          ;restore a1
            ;lw      a2, 0x0018(sp)          ;restore a2 _don't mess up TextID yet
    
 beq v0, r0, @@TEXTLOAD_WNAVI      ;BRANCH if TextID no Gossip Text
    nop
    
;=>Gossip Text, save for saria
    jal SARIA_HINTS_GOSSIP_READING      ;has a1 TextPointer, a2 TextID
    nop
    lw      a1, 0x001c(sp)          ;restore a1
    lw      a2, 0x0018(sp)          ;restore a2
    J @@TLL_LOAD_TEXT
    nop
    
    
    
@@TEXTLOAD_WNAVI:    
;====Working Navi=====   

    lw      a2, 0x0018(sp)          ;restore a2

    lw t2, WORKING_NAVI_CONDITION
 beq t2, r0, @@TLL_LOAD_TEXT
    nop

    jal @checkNaviText
    nop
    
    lw      a1, 0x001c(sp)          ;restore a1
    lw      a2, 0x0018(sp)          ;restore a2
    
 beq v0, r0, @@TLL_LOAD_TEXT      ;BRANCH if TextID no Navi Text
    nop
    
    ;The TextOutput is handled normally
    
    ; Reset TextIDOffset stuff(cyclic logic), so the message isnt shown twice
    la t1, working_navi_TextIDOffsetGlobal
    sw r0, 0x0000 (t1)       ;Store TextIDOffset (Reset)
    
    la t2, working_navi_cyclicLogicGlobals
    sw r0, 0x0004 (t2) ;ShowTextFlag Reset
    
    jal get_TextID_ByTextPointer
    li t0, Navi_Hints_TextID_Base     ; if Text says "You are doing so well..." / Textpointer is on base, dont reset timer
 beq t0, v0, @@TLL_LOAD_TEXT
    nop
    
    sw t3, 0x0000 (t2) ;Timer1 Reset
    ;TBD test this

;=======Load Text=======
    
@@TLL_LOAD_TEXT:        ;TARGET LOAD_TEXT

    ;a1 and a2 might have been modified by wNavi
    jal 0x80000DF0          ;DMALoad Text in
    nop
    
         
    ;Restore RA and return
    lw      ra, 0x0014(sp)
    addiu   sp, sp, 0x20
    jr      ra
    nop

;==================================================================================================


;get_TextTablePointer_ByID:     ;arguments: a2 is the Text ID

;    li t1, TABLE_START_RAM
    
;@@get_TextTablePointer_ByID_inc:
;    addiu t1, t1, 8 
;    lh t3, 0x0000 (t1)
; bne t3, a2, @@get_TextTablePointer_ByID_inc 
;    nop

;    lw t3, 0x0004 (t1)
;    lui t5, 0x00ff
;    ori t5, t5, 0xffff
;    and t3, t3, t5
;    li t4, TEXT_START
;    addu t3, t3, t4
    
;    jr ra
;    nop
    
    
    

    
get_TextID_ByTextPointer: ; arguments: a1 is Textpointer to find

    li t1, TABLE_START_RAM

    lui t7, 0x0000
    j @@get_SariaIndexOffset_ByID_initjump
    nop
@@get_TextID_ByTextPointer_inc2:
    addiu t1, t1, 8 
@@get_SariaIndexOffset_ByID_initjump:
    lw t3, 0x0004 (t1)
    lui t5, 0x00ff
    ori t5, t5, 0xffff
    and t3, t3, t5
    li t4, TEXT_START
    addu t3, t3, t4
    
 bne t3, a1, @@get_TextID_ByTextPointer_inc2 
    nop
    
    ;we found our table entry
    lh v0, 0x0000 (t1)
    
    jr ra
    nop
    
    
    
@checkGossipText:
    addiu   sp, sp, -0x18
    sw      ra, 0x0014(sp)

    lui t9, 0x0000
    
    jal get_TextID_ByTextPointer
    nop      
    move a2, v0                         ;a2 has the textID, for saria stuff
    
    ori t2, r0, (0x0401 -1)                 ;gossip Text ID low
    slt t1, t2, v0        

 beq t1, r0, @@checkGossipText_NOK      ;BRANCH if reqested Textpointer A1 < Min
    nop
    
    ori t2, r0, (0x04FF +1)                  ;gossip Text ID high    
    slt t1, v0, t2   
    
  beq t1, r0, @@checkGossipText_NOK      ;BRANCH if reqested Textpointer A1 < Min
    nop     

    ori t9, r0, 0x0001
@@checkGossipText_NOK:

    move v0, t9
    
    ;Restore RA and return
    lw      ra, 0x0014(sp)
    addiu   sp, sp, 0x18
    jr ra
    nop





@checkNaviText:
    addiu   sp, sp, -0x18
    sw      ra, 0x0014(sp)

    lui t9, 0x0000
    
    jal get_TextID_ByTextPointer
    nop      
    
    ori t2, r0, (0x0141 -1)                  ;Navi Text ID low
    slt t1, t2, v0        

 beq t1, r0, @@checkNaviText_NOK      ;BRANCH if reqested Textpointer A1 < Min
    nop
    
    ori t2, r0, (0x015f +1)                  ;Navi Text ID high    
    slt t1, v0, t2   
    
  beq t1, r0, @@checkNaviText_NOK      ;BRANCH if reqested Textpointer A1 < Min
    nop     

    ori t9, r0, 0x0001
@@checkNaviText_NOK:

    move v0, t9
    
    ;Restore RA and return
    lw      ra, 0x0014(sp)
    addiu   sp, sp, 0x18
    jr ra
    nop
