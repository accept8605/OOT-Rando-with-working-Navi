;Accept86 Saria hints repeat
;==================================================================================================
    
.definelabel Saria_Gossip_Save_Offset, 0xD4 + (57 * 0x1C) +0x10 

Saria_Hints_Globals:  .word  0x0, 0x0, 0x0, 0x0   ;1:last TextID loaded, 2:internal GossipText index
                                             ;3:Activation, 4: just deactivated


SARIA_GOSSIP_TEXTID_TABLE_SYM:
.area (42*2+4), 0      ;somehow its 42 Gossip TextIDs?, 4 Bytes as Space to code
.endarea



Saria_TextBoxBreak_HOOK:
    addiu   sp, sp, -0x1C
    sw      ra, 0x0014(sp)
    sw      a1, 0x0018(sp)

    ;displaced code
    jal OOT_Navi_Saria_TextID_Generation
    nop
    
    
    lw t2, SARIA_HINTS_CONDITION
 beq t2, r0, @@Saria_TextID_END
    nop
    
    ;v0 is the TextID (from the hook!)
    
    la t1, Saria_Hints_Globals
    lw t2, 0x0000 (t1)      ;Load Last TextID
    
    ori t3, r0, 0x00e0  ; ID-You want to talk to Saria, right?
 beq t2, t3, @@Saria_TextID_StartNew
    nop
    
    ori t3, r0, 0x00e3  ; ID-Do you want to talk to Saria again?
 beq t2, t3, @@Saria_TextID_StartNew
    nop
    
    J @@Saria_TextID_Continue
    nop
    
@@Saria_TextID_StartNew:
    sw r0, 0x0004 (t1)          ;Reset Text Index
    
@@Saria_TextID_Continue:
    sw v0, 0x0000 (t1)          ;Save Last TextID
    
    
    lw t2, 0x0008 (t1)          ;Load Activation
 bne t2, r0, @@Saria_TextID_Change
    nop
           
    
; Is it a Saria Text?    
    
    ori t2, r0, (0x0160 -1)                  ;saria Text ID low
    slt t1, t2, v0        

 beq t1, r0, @@Saria_TextID_END      ;BRANCH if reqested Textpointer A1 < Min
    nop
    
    ori t2, r0, (0x016c +1)                  ;saria Text ID high - TBD is this correct? 
    slt t1, v0, t2   
    
  beq t1, r0, @@Saria_TextID_END      ;BRANCH if reqested Textpointer A1 < Min
    nop    
 
@@Saria_TextID_Change: 
    ori t2, r0, 0x0001
    la t1, Saria_Hints_Globals
    sw t2, 0x0008 (t1)          ;save Activation  
     
    jal @GET_NEXT_GOSSIP_ID
    nop
    ; Modifying v0 with the new TextID



@@Saria_TextID_END:    
    ;Restore RA and return
    lw      ra, 0x0014(sp)
    lw      a1, 0x0018(sp)
    addiu   sp, sp, 0x1C
    jr ra
    nop  



Saria_TextBoxBreak_Chaining_HOOK:       ;in a subfunction in the TextBoxBreak function
    la t1, Saria_Hints_Globals
    lw t2, 0x0008 (t1)      ;Load Activation
    
 beq t2, r0, @@Saria_TextBoxBreak_Chaining_NoChange
    nop
    ;overwrite V0 to chain TextBoxes
    ori v0, r0, 5

@@Saria_TextBoxBreak_Chaining_NoChange:
    ;displaced code
    jr ra
    nop



Saria_TextBoxBreak_Chaining2_HOOK:      ; On the JalR FunctionPointer settings

    ;displaced code
    lw a0, 0x0020 (SP)
    
    la t1, Saria_Hints_Globals
    
    lw t2, 0x000C (t1)      ;Load just deactivated
 bne t2, r0, @@Saria_TextBoxBreak_Chaining_JustDeactivated
    nop

    
    lw t2, 0x0008 (t1)      ;Load Activation
    
 bne t2, r0, @@Saria_TextBoxBreak_Chaining_NoChange
    nop
    
    ;displaced code
    sw t6, 0x0130 (t7)     ;if TextBoxChaining active for Saria, no resetting with t6

@@Saria_TextBoxBreak_Chaining_NoChange:
    ;displaced code
    j Saria_TextBoxBreak_Chaining2_HOOK_END
    nop


@@Saria_TextBoxBreak_Chaining_JustDeactivated:
    sw r0, 0x000C (t1)      ;reset just deactivated
    lui t6, 0x801E
    ori t6, t6, 0x0C2c
    sw t6, 0x0130 (t7)     ;if TextBoxChaining just deactivated, set function pointer to normal value

    j @@Saria_TextBoxBreak_Chaining_NoChange
    nop




SARIA_HINTS_GOSSIP_READING: ;arguments: a1 = Textpointer, a2 = TextID
    addiu   sp, sp, -0x18
    sw      ra, 0x0014(sp)
    
    
    la t1, Saria_Hints_Globals
    lw t2, 0x0008 (t1)      ;Load Activation
    
 bne t2, r0, @@SARIA_HINTS_GOSSIP_READING_NOSAVE ;if Saria Text Activation is active, no saving
    nop
    
    ; Get Message Text Index offset
    jal @get_SariaIndexOffset_ByTextPointer
    nop
    ; v0 has the indexoffset now

    move a1, v0                     ;a1 is indexoffset of gossiptext now
    jal @SARIA_GOSSIP_SAVEPROGRESS
    nop

@@SARIA_HINTS_GOSSIP_READING_NOSAVE:    

    ;Restore RA and return
    lw      ra, 0x0014(sp)
    addiu   sp, sp, 0x18
    jr ra
    nop    
    
    
    
    
    
@get_SariaIndexOffset_ByTextPointer:    ; arguments: a1 is gossip Textpointer to find
    addiu   sp, sp, -0x18
    sw      ra, 0x0014(sp)
    
    jal get_TextID_ByTextPointer ;v0 is TextID now
    nop
    
    la t1, SARIA_GOSSIP_TEXTID_TABLE_SYM
    lui t2, 0x0000
@@get_SariaIndexOffset_ByTextPointer_notFoundYet:
    lh t3, 0x0000 (t1)
    addiu t2, t2, 1
    addiu t1, t1, 2
    bne v0, t3, @@get_SariaIndexOffset_ByTextPointer_notFoundYet
        nop
    
    addiu t2, t2, -1
    
    ;now in t2 is the indexoffset
    move v0, t2
    
    ;Restore RA and return
    lw      ra, 0x0014(sp)
    addiu   sp, sp, 0x18
    jr ra
    nop
    
    
    
     
    
@SARIA_GOSSIP_SAVEPROGRESS: ; a1 = bitIndex to store

    li   t4, SAVE_CONTEXT 
    
    ;get byteoffset
    srl t3, a1, 5       ; equals / 32
    
    ;get Bitoffset
    andi t2, a1, 0x1F    ; equals % 32
    
    ;calc byte to save
    ori t6, r0, 0x1C
    multu t3, t6
    mflo t6
    addu t4, t4, t6
    lw t3, (Saria_Gossip_Save_Offset) (t4)
    lui t5, 0x8000  
    srlv t5, t5, t2     ;big endian
    or t3, t3, t5
    
    ;save
    sw t3, (Saria_Gossip_Save_Offset) (t4)    
    
    jr ra
    nop
    
    

    
@GET_NEXT_GOSSIP_ID:
    addiu   sp, sp, -0x18
    sw      ra, 0x0014(sp)
    
    li   t4, SAVE_CONTEXT 
    
    ;load progress bits    
    lui t5, 0x0000                          ;current bitindex
    lb  t8, (Saria_Gossip_Save_Offset)(t4)  ;current loadbitmask from savedata
    
    la t1, Saria_Hints_Globals
    lui at, 0x0000          ; current Index

@Get_Next_GossipID_NEXT:
    ori t3, r0, 40
    slt t6, at, t3
    
 beq t6, r0, @WGet_Next_GossipID_END ; Escape at end of loop <= THIS IS THE RETURN OUT
    nop
    
; here we load our progress
   slti t3, t5, 8     ; t5 bitindex still ok?
 bne t3, r0, @@Get_Next_GossipID_NO_NEXTBYTE
   nop
   
   ; if a byte is complete, next one
   lui t5, 0x0000
   addiu t4, t4, 1
   
   andi t9, t4, 0x0003      ; equals %4
 bne t9, r0, @@Get_Next_GossipID_NO_NEXTBYTE    ; if t4 bytecount modulo 4 is 0 => next unused savedata section
   nop
   ;here we go to the next unused savedata section
   addiu t4, t4, (0x1C-4)  
   
@@Get_Next_GossipID_NO_NEXTBYTE:

   lb  t8, (Saria_Gossip_Save_Offset)(t4)

;here we check our t8 progress-saveflag-bits
    ori t9, r0, 0x80
    srlv t9, t9, t5     ;big endian
    and t8, t8, t9
    
    addiu t5, t5, 1             ;Increase Bitindex
    addiu at, at, 1             ;Increase CurrentIndex
    
 beq r0, t8, @Get_Next_GossipID_NEXT  
    nop
    
;bit set for this entry

    lw t2, 0x0004 (t1)      ; load lastIndex
    addiu t6, t2, 1
    slt t3, at, t6
 bne t3, r0, @Get_Next_GossipID_NEXT        ;NextEntry if continuation not reached
    nop
    
    sw at, 0x0004 (t1)      ; save lastIndex
    
    ;set TextID by entry found
    addiu a1, at, -1
    jal @get_SariaTextID_byIndexOffset
    nop
    
    ;Restore RA and return
    lw      ra, 0x0014(sp)
    addiu   sp, sp, 0x18
    jr ra
    nop  
   
@WGet_Next_GossipID_END: 

    ;set TextID
    ori v0, r0, 0x00e3  ;Do you want to talk to Saria again?
    sw r0, 0x0008 (t1)  ;reset activation
    sw r0, 0x0004 (t1)  ;reset lastIndex
    ori t2, r0, 0x0001
    sw t2, 0x000C (t1)  ;set just deactiveted
    

    ;Restore RA and return
    lw      ra, 0x0014(sp)
    addiu   sp, sp, 0x18
    jr ra
    nop    
    
    
    
    
    
@get_SariaTextID_byIndexOffset:    ; arguments: a1 is IndexOffset

    la t1, SARIA_GOSSIP_TEXTID_TABLE_SYM
    sll a1, a1, 1   ;mult with 2
    addu t1, t1, a1

    lh v0, 0x0000 (t1)
    
    jr ra
    nop
    
    
    
    