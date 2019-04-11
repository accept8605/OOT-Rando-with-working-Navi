;Accept86 WorkingNavi
;==================================================================================================

;WORKING_NAVI_DATA_GENERATED_TEXT_ROM => Texts with 0x3C increment (ROM-Address)
;WORKING_NAVI_DATA_GENERATED_LOOKUPTABLE_SYM => LookUpTable For NaviTexts (8 Bytes each per Text 
        ; 2 Bytes SaveDataOffset, ;1 Byte SaveDataBitoffset, 1 Byte to handle by Software)
        ; 1 Byte Sphere, 1 Byte ItemID, 2 Bytes SavedataMask for Item



.org WORKING_NAVI_RAM

WORKING_NAVI_GLOBALS:

.area 0x40

.data:
   working_navi_cyclicLogicGlobals:  .word  0x0,0x0,0x0,0x0,0x0,0x0
   working_navi_TextPointerGlobal:  .word  0x0
   
.endarea   
   
.text:




.org WORKING_NAVI_DATA_CODE  ; see changed build.asm and addresses.asm
.area 0x300


working_navi_cyclicLogic:
    addiu   sp, sp, -0x18
    sw      ra, 0x0014(sp)


    ;lui t0, 0x0350            ;WORKING_NAVI_DATA_GENERATED_TEXT_ROM
    ;ori t0, 0x0700            ;WORKING_NAVI_DATA_GENERATED_TEXT_ROM ;TextTablePointer for Navi-Texts
    li t0, WORKING_NAVI_DATA_GENERATED_TEXT_ROM
    ;lui t7, 0x8050            ;WORKING_NAVI_DATA_GENERATED_LOOKUPTABLE_SYM
    ;ori t7, 0x0400            ;WORKING_NAVI_DATA_GENERATED_LOOKUPTABLE_SYM  ;LookupTablePointer for Navi-Texts
    li t7, WORKING_NAVI_DATA_GENERATED_LOOKUPTABLE_SYM
                                    ;global variable 1 (Timer), 2 (showTextFlag), 
    la t1, working_navi_cyclicLogicGlobals   ;3 (Max Time when Navi activated - value comes from python patched ROM Patches.py)
                                             ;4 (LastLookupTablePointer); 5(LastTextTablePointer)
                                             ;6 Timer2


;Progress made? =>Timer Reset
    lw t6, 0x0014 (t1)       ;load global variable 6 (Timer2)
    addiu t6, t6, 0x0001     ;increment
    sw t6, 0x0014 (t1)       ;store increment global variable 6 (Timer2)
    
    lui t3, 0x0000
    ori t3, 0xd90       ; 1 minute
    
 beq t6, t3, @WNAVI_CL_HAS_ANY_PROGRESS_BEEN_MADE   ; every minute, Check if any Progress has been made - Reset timer if progress made
    nop

    li t7, WORKING_NAVI_DATA_GENERATED_LOOKUPTABLE_SYM ; Reset t7 to LookupTable-Base

;Timercheck => otherwise say "You are doing so well, no need to bother you" 
    lw t5, 0x0008 (t1)       ;global Variable 3 - MaxTime when Navi gets activated
    lw t6, 0x0000 (t1)       ;load global variable 1 (Timer)
    addiu t6, t6, 0x0001     ;increment
    sw t6, 0x0000 (t1)       ;store increment global variable 1 (Timer)
    
 beq t6, t5, @WNAVI_CL_HAS_ANY_PROGRESS_BEEN_MADE   ; Check when Timer1 expires, too (when timers are desynced)
    nop


@WNAVI_AFTER_CL_HAS_ANY_PROGRESS_BEEN_MADE:





    li t7, WORKING_NAVI_DATA_GENERATED_LOOKUPTABLE_SYM ; Reset t7 to LookupTable-Base
    lw t6, 0x0000 (t1)       ;load global variable 1 (Timer)
    lw t5, 0x0008 (t1)       ;global Variable 3 - MaxTime when Navi gets activated

    
 beq t6, t5, @WNAVI_CL_TEXTPOINTER_RESTORE   ; Restore Textpointer when Timer expired
    nop
@WNAVI_AFTER_CL_TEXTPOINTER_RESTORE:    
       
       
       
;actual timertest        
    slt t4, t6, t5           ;Test : t6(timer) less than t5 (global variable with TimerBase)
    lui t3, 0x0000
    ori t3, t3, 0x0001
    
 beq t4, t3, @WNAVI_CL_TIMER_NOK       ;BRANCH Jump over to @WNAVI_CL_TIMER_NOK when Timer not allowing Navi Text Output
    nop
    
    lui t4, 0x0000
    sw t4, 0x0000 (t1)       ;Reset Timer on global Variable 1, if timer was ok >= MaxTime
     
    
    
;after Timer OK => give useful text - calculate next Text
    addiu t7, t7, 0xfff8     ;From here is the LookupTablePointer setting. Decrement T7 LookupTablePointer by 4

@WNAVI_CL_INCREMENT_POINTERS:

    addiu t0, t0, 0x003c     ;TARGET Jump Here to INCREMENT_POINTERS From here is the TextTablePointer setting. Increment T0 TextTablePointer by 3C
    addiu t7, t7, 0x0008     ; 0x0004     ;Increment LookupTablePointer


    li a1, @WNAVI_CL_INCREMENT_POINTERS          ; A1: Increment Pointers Address
    move a2, t7                                 ; t7 LookupTablePointer
    JAL @WNAVI_CL_CHECKSAVEDATA                  ;checks save Data for LookupTableEntry
    nop



;then set Textpointer

    ;when t0 not changed, no need to save
    lw t6, 0x0010 (t1)       ;load last Textpointer
 beq t6, t0, @@WNAVI_CL_NOTCHANGED_BRANCH
    nop
    
  ;Here: Textpointer has changed
    la t2, working_navi_TextPointerGlobal
    sw t0, 0x0000 (t2)       ; Store T0 in Global Variable 5 Textpointer
    sw t7, 0x000c (t1)       ; Save Global Variable 4 LastLookupTablePointer
    sw t0, 0x0010 (t1)       ; save last Textpointer
    lui t3, 0x0000
    sw t3, 0x0000 (t1)       ; Reset Timer TBD test this
    
    
@@WNAVI_CL_NOTCHANGED_BRANCH:
        

;Restore and Return
@WNAVI_CL_RETURN:         
    ;Restore RA and return
    lw      ra, 0x0014(sp)
    addiu   sp, sp, 0x18
    jr      ra
    nop





;_______Subroutines for cyclic logic__________

    
@WNAVI_CL_TEXTPOINTER_RESTORE:
    la t3, working_navi_TextPointerGlobal
    la t1, working_navi_cyclicLogicGlobals
    lw t2, 0x0010 (t1)       ;Load Backup of lastTexpointer (normally t0, but that is generated from the ground up again)
    sw t2, 0x0000 (t3)       ;Store t2 in Global Variable 5 Textpointer, which was "You are doing so well, no need to bother you"
    
    lui t3, 0x0000
    ori t3, t3, 0x0001
    sw t3, 0x0004 (t1) ;ShowTextFlag set
    
    
    lui t2, 0x8011
    ori t2, 0xA608
    lui t3, 0x0000     ;Manipulate OOT Navi Timer
    ori t3, 0x0009
    sb t3, 0x0000 (t2)
    
    
   
    J @WNAVI_AFTER_CL_TEXTPOINTER_RESTORE
    nop    
    
    
@WNAVI_CL_TIMER_NOK:
    la t1, working_navi_cyclicLogicGlobals
    
    lui t3, 0x0000
    ori t3, t3, 0x0001
    lw t2, 0x0004 (t1)          ;ShowTextFlag
 beq t2, t3, @WNAVI_CL_RETURN
    nop
    
    la t1, working_navi_TextPointerGlobal
    li t0, WORKING_NAVI_DATA_GENERATED_TEXT_ROM
    sw t0, 0x0000 (t1)       ;Store T0 in Global Variable 5 Textpointer
   
    J @WNAVI_CL_RETURN
    nop    

;_______Subroutine1__________
@WNAVI_CL_CHECKSAVEDATA: ;ARGUMENTS: a1=LABEL TO INCREMENT LookupTable; a2=LookupTablePointer

    lb t6, 0x0003 (a2)       ;Load "IsDone" Part of LookupTable-Element
    andi t6, t6, 0x00ff      ;BitMaskFilter
    lui t5, 0x0000
    ori t5, t5, 0x00ff
    
 beq t6, t5, @WNAVI_CL_INT_CHECKSAVEDATA_RETURN       ;BRANCH - EndofTable? to AFTER_TEXT_POINTER_UPDATE
    nop

    lw t6, 0x0000 (a2)       ;Load SaveDataOffset from LookupTablePointer in T6
    srl t6, t6, 16         
    andi t6, t6, 0xffff      ;Mask SaveDataOffset
    lui t5, 0x0000
    
 bne t6, t5, @@WNAVI_CL_INT_CHECKSAVEDATA_DONT_JUMP1       ;BRANCH - if LookupTable Offset is 0 Jump Back INCREMENT_POINTERS
    nop
    jr a1
    nop
@@WNAVI_CL_INT_CHECKSAVEDATA_DONT_JUMP1:
    
    
    lb t3, 0x0002 (a2)       ;Load SaveDataBitOffset
    andi t3, t3, 0x00ff
    
    lw t5, 0x0004 (a2)        ;load savemask in t5
    srl t5, t5, 16           ;Only max 2 Bytes large
    andi t5, t5, 0xffff
    

    lui t4, 0x8011           ;Load SaveDataBasePointer to Add to SaveDataOffset
    ori t4, t4, 0xa5d0       ;RAM Address NTSC1.0 0x8011A5D0 https://wiki.cloudmodding.com/oot/Save_Format#Save_File_Validation 

    addu t6, t6, t4          ;Get Resulting SaveDataPointer with Offset in t6
    lw t4, 0x0000 (t6)       ;T4: Resulting SaveDataElementWord
    srlv t4, t4, t3
    andi t4, t4, 0xffff
    
    
    lui t6, 0x0
    ori t6, 0xffff
 beq t4, t6, @@WNAVI_CL_INT_CHECKSAVEDATA_DONT_JUMP2       ;BRANCH If SaveDataElementWord is FFFF => didnt get item
    nop     
    
    
    ;the mask could be FF => save data has item if not FF
 beq t6, t5, @WNAVI_CL_SAVEMASKFF               ;BRANCH, MASK is FF, check savedata different
    nop
    
    
    lb t3, 0x0006 (a2)       ;Load ItemID
    andi t3, t3, 0x00ff
    lui t6, 0x0
 bne t3, t6, @WNAVI_CL_CHECKSAVEDATA_ITEMID
    nop
    
    
    
;Savemask not FF or itemID
    and t4, t4, t5        ;mask saveData with saveDatamask
    lui t5, 0x0000        ;load 0 in t5

 beq t4, t5, @@WNAVI_CL_INT_CHECKSAVEDATA_DONT_JUMP2       ;BRANCH If SaveData has this Item => Go to INCREMENT_POINTERS/a1
    nop
    jr a1
    nop
    
@@WNAVI_CL_INT_CHECKSAVEDATA_DONT_JUMP2:
    
 
@WNAVI_CL_INT_CHECKSAVEDATA_RETURN:   
    jr ra
    nop
    
    
    
    
;____Sub-Subroutine1___    
@WNAVI_CL_SAVEMASKFF:        ; TARGET if Savedatamask is FF

    ;Savemask is FF
    ;t4: SaveDataElementWord , t5 SaveDataMask
    
 beq t4, t5, @@WNAVI_CL_INT_CHECKSAVEDATA_DONT_JUMP3       ;BRANCH If SaveData mask FF and Savedata not FF Item aquired => Go to INCREMENT_POINTERS/a1
    nop
    jr a1
    nop
@@WNAVI_CL_INT_CHECKSAVEDATA_DONT_JUMP3:


    J @WNAVI_CL_INT_CHECKSAVEDATA_RETURN
    nop



;____Sub-Subroutine2___
@WNAVI_CL_CHECKSAVEDATA_ITEMID: 


    ;t3 is ItemID
    ;t4: SaveDataElementWord , t5 SaveDataMask
    
    
    sltu t6,t4,t3   ; SaveData < ItemID?
    lui t2, 0x0000
    ori t2, t2, 0x0001
    
 beq t6, t2, @@WNAVI_CL_INT_CHECKSAVEDATA_DONT_JUMP4       ;BRANCH If SaveData < ItemID, dont got item
    nop
    jr a1
    nop
@@WNAVI_CL_INT_CHECKSAVEDATA_DONT_JUMP4:


    J @WNAVI_CL_INT_CHECKSAVEDATA_RETURN
    nop  
    
    
    
    
    

;_______Subroutine2_______
@WNAVI_CL_HAS_ANY_PROGRESS_BEEN_MADE:
    la t1, working_navi_cyclicLogicGlobals
    lui t3, 0x0000
    sw t3, 0x0014 (t1)       ;Reset global variable 6 (Timer2)
    
    li t7, WORKING_NAVI_DATA_GENERATED_LOOKUPTABLE_SYM

    J @WNAVI_CL_HAS_ANY_PROGRESS_BEEN_MADE_INITJUMP
    nop
    
    
    
@WNAVI_CL_HAS_ANY_PROGRESS_BEEN_MADE_GOT_ITEM:  
    lui t6, 0x0000
    lb t6, 0x0003 (t7)       ;Load "IsDone" Part of LookupTable-Element
    ori t6, t6, 0x0001       ;Save Flag for gotten Item
    sb t6, 0x0003 (t7)
    
    lui t3, 0x0000
    ori t3, 0x0001
    
; Reset ShowText, Reset Timer, if Item is newly gotten
 bne t6, t3, @@WNAVI_CL_HAS_ANY_PROGRESS_BEEN_MADE_NO_TIMERRESET
    nop
    ori t6, t6, 0x0003       ;Save Flag for gotten Item "before"
    sb t6, 0x0003 (t7)
    
    la t4, working_navi_cyclicLogicGlobals
    lui t3, 0x0000
    sw t3, 0x0004 (t4) ;Reset ShowTextFlag
    sw t3, 0x0000 (t4) ;Reset Timer1 (NaviDelay)
@@WNAVI_CL_HAS_ANY_PROGRESS_BEEN_MADE_NO_TIMERRESET:    
    
@WNAVI_CL_HAS_ANY_PROGRESS_BEEN_MADE_ITEM_NOT_GOTTEN:
    addiu t7, t7, 0x0008     ; 0x0004     ;Increment LookupTablePointer
    
@WNAVI_CL_HAS_ANY_PROGRESS_BEEN_MADE_INITJUMP:     
    
    lui t3, 0x0000
    ori t3, t3, 0x00FF
    lb t6, 0x0003 (t7)       ;Load "IsDone" Part of LookupTable-Element
    andi t6, t6, 0x00ff      ;BitMaskFilter
    
 beq t3, t6, @WNAVI_AFTER_CL_HAS_ANY_PROGRESS_BEEN_MADE ; Escape at end of loop <= THIS IS THE RETURN OUT
    nop
    

    li a1, @WNAVI_CL_HAS_ANY_PROGRESS_BEEN_MADE_GOT_ITEM     ; A1: Item Got Jump Address
    move a2, t7                                 ; t7 LookupTablePointer
    JAL @WNAVI_CL_CHECKSAVEDATA                  ;checks save Data for LookupTableEntry
    nop

    J @WNAVI_CL_HAS_ANY_PROGRESS_BEEN_MADE_ITEM_NOT_GOTTEN
    nop
    
    ;Heres no Return needed, always go to end of lookuptable
    
    
.endarea    
    
    
    
;==================================================================================================

.org WORKING_NAVI_DATA_CODE2  ; see changed build.asm and addresses.asm
.area 0x1F0

working_navi_TextLoadLogic:
    addiu   sp, sp, -0x18
    sw      ra, 0x0014(sp)
    
    lui t2, 0x0000
    ori t2, t2, 0x0000      ;just 0 in T2 for using with compares
    
    lui t3, 0x0093          ; TBD why did this value change since Rando 1.0?
    ori t3, t3, 0x2ea0      ;TextLoadPointerMin old: 0x4af0
    slt t1, t3, a1          ;comparison, A1 = requested Textloadpointer of the game
    
 beq t1, t2, @@WNAVI_TLL_LOAD_TEXT      ;BRANCH if reqested Textpointer A1 < Min NaviSection: Jump LOAD_TEXT
    nop
    
    lui t3, 0x0093          ; TBD why did this value change since Rando 1.0?
    ori t3, t3, 0x37ac      ; TextLoadPointer max old: 0x5400
    slt t1, a1, t3          ;A1 < T3 (Max) req Textpointer A1 < Max NaviSection

 beq t1, t2, @@WNAVI_TLL_LOAD_TEXT      ;BRANCH if Textpointer < Max => Jump LOAD_TEXT
    nop
    
                            ; T7 Global Variable 5 Textpointer
    la t7, working_navi_TextPointerGlobal
    lw a1, 0x0000 (t7)      ; IF req Textpointer A1 in NaviSection => Load GlobalVar with Text of workingNavi in A1


    ; Reset Textpointer stuff(cyclic logic), so the message isnt shown twice
    la t1, working_navi_TextPointerGlobal
    li t0, WORKING_NAVI_DATA_GENERATED_TEXT_ROM
    sw t0, 0x0000 (t1)       ;Store T0 in Global Variable  Textpointer (Reset)
    la t2, working_navi_cyclicLogicGlobals
    lui t3, 0x0000
    sw t3, 0x0004 (t2) ;ShowTextFlag Reset
    sw t3, 0x0000 (t2) ;Timer1 Reset

    
@@WNAVI_TLL_LOAD_TEXT:        ;TARGET LOAD_TEXT
    jal 0x80000DF0          ;DMALoad Text in
    nop
    
         
    ;Restore RA and return
    lw      ra, 0x0014(sp)
    addiu   sp, sp, 0x18
    jr      ra
    nop

;==================================================================================================


working_navi_ExtendedInit:

    ; Init global variables (for cyclic logic)
    la t1, working_navi_TextPointerGlobal
    li t0, WORKING_NAVI_DATA_GENERATED_TEXT_ROM
    sw t0, 0x0000 (t1)       ;Store T0 in Global Variable 5 Textpointer
   
    li t7, WORKING_NAVI_DATA_GENERATED_LOOKUPTABLE_SYM
                                    ;global variable 1 (Timer), 2 (dummy), 
    la t1, working_navi_cyclicLogicGlobals   ;3 (Max Time when Navi activated - value comes from python patched ROM Patches.py)
                                             ;4 (LastLookupTablePointer); 5(LastTextTablePointer)
                                             ;6 Timer2
    addiu t0, t0, 0x003c  ;The Textpointer Backup is not on "You are doing so well, no need to bother you" but on the first real hint
    sw t0, 0x0010 (t1)
    sw t7, 0x000C (t1)
    
    jr ra
    nop


.endarea 



.org WORKING_NAVI_DATA_GENERATED_TEXT_SYM  ; see addresses.asm, this is only done so we get a symbol in symbols_RAM.json
.area 0x1000
nop
.endarea
