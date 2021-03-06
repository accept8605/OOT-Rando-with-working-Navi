//Accept86 Textload
//==================================================================================================

#include "z64.h"


extern const uint32_t SARIA_HINTS_CONDITION;  
extern const uint32_t NAVI_HINTS_CONDITION;  

extern uint32_t SARIA_HINTS_GOSSIP_READING(uint32_t unknown, uint32_t TextAddress, uint32_t TextID);

extern const uint32_t C_TABLE_START;  
extern const uint32_t C_TABLE_START_RAM;  
extern const uint32_t C_TEXT_START;  

extern uint32_t CyclicLogic_ResetText(uint32_t TextID);

uint16_t get_TextID_ByTextPointer(uint32_t TextAddress);

extern const uint32_t Navi_Hints_TextID_Base;


uint8_t TextLoadLogic_handling(uint32_t RAMAddress, uint32_t ROMTextAddress, uint32_t TextLength)
{
    
    if(SARIA_HINTS_CONDITION)
    {
        uint16_t TextID = get_TextID_ByTextPointer(ROMTextAddress);
    
        if((TextID>=0x0401) && (TextID<=0x04FF))        // gossip hints TextID-Borders
        {
            SARIA_HINTS_GOSSIP_READING(0, ROMTextAddress, TextID);
        }
    }
    
    if(NAVI_HINTS_CONDITION)
    {
        uint16_t TextID = get_TextID_ByTextPointer(ROMTextAddress);
    
        if((TextID>=Navi_Hints_TextID_Base) && (TextID<=(Navi_Hints_TextID_Base+100)) )       // Navi Text TextID-Borders
        {
            //The TextOutput is handled normally  
            //Reset TextIDOffset stuff(cyclic logic), so the message isnt shown twice 
            //Store TextIDOffset (Reset) 
            //ShowTextFlag (Reset)  
            //if Text says 'I have faith in you..' Textpointer is on base, dont reset timer 
            //Timer1 Reset <= TBD test this  
            CyclicLogic_ResetText((uint32_t) TextID);
        }
    }
    
}






uint16_t get_TextID_ByTextPointer(uint32_t TextAddress)
{
    uint8_t* curTableAddress = (uint8_t*)(uint32_t)C_TABLE_START_RAM;

    while(1)
    {
        uint32_t TextOffset = (uint32_t)(*(uint32_t*)(curTableAddress+4));
        TextOffset &= 0xffffff;
        
        if( (TextOffset+(uint32_t)C_TEXT_START) == TextAddress )
            break;
        
        curTableAddress += 8;
    }
    
    uint32_t TextID = (uint32_t)(*(uint16_t*)(curTableAddress));

    return TextID;
}



    
