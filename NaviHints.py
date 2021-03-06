#Accept86 Navi Hints
#==================================================================================================

from SaveContext import SaveContext
from Hints import get_raw_text, lineWrap        
from Utils import default_output_path
from Rom import Rom
from Messages import add_message

import os, os.path
                    
import re

class Navi_Hints(Rom):
    
    NAVI_HINTS_ROM_GLOBALS = None
    NAVI_HINTS_DATA_GENERATED_LOOKUPTABLE_ROM = None
    NAVI_HINTS_TEXTID_BASE = None
    Navi_TextID_Base = 0x7400
    
    def __init__(self, rom):
        self.NAVI_HINTS_ROM_GLOBALS = rom.sym('NAVI_HINTS_GLOBALS') #0x03490000
        self.NAVI_HINTS_DATA_GENERATED_LOOKUPTABLE_ROM = rom.sym('NAVI_HINTS_DATA_GENERATED_LOOKUPTABLE') #self.NAVI_HINTS_ROM + 0x40     #TBD from .json File?
        self.NAVI_HINTS_TEXTID_BASE = rom.sym('NAVI_HINTS_TEXTID_BASE')
    
    lastUpgradeIndexes = [0,0,0,0]
    lastBottleIndex = 0
    
    
    def Reset(self):
        self.lastUpgradeIndexes = [0,0,0,0]
        self.lastBottleIndex = 0
    

    def getBitOffsetIndex(self, mask):
        i=0;
        for i in range(0, (32+16)):
            if( ((mask>>i)&1)!=0 ):
                break
            
        return i
    

    #=> bitshiftcount with 0x80 flag -> 0x84, 0x88 0x8C
    #=> if value from save not smaller than that got item
    #strength: goes 0=>0x40->0x80->0xC0, no bitencoding
    #scale: 0 => 0x200 => 0x400
    #hookshot: 0xFFFF => 0xFF0A => 0xFF0B
    #Wallet:  0=>0x1000 => 0x2000
    item_id_map_Rando = {
        'none'                : 0xFF,
        'hookshot'            : 0x0A,
        'longshot'            : 0x0B,
        'gorons_bracelet'     : 0x40,
        'silver_gauntlets'    : 0x80,
        'golden_gauntlets'    : 0xC0,
        'silver_scale'        : 0x02,
        'golden_scale'        : 0x04,
        'adults_wallet'       : 0x10,
        'giants_wallet'       : 0x20,
    }

    
    def OptimizeOffsetAndMask(self, ItemByteOffset,ItemMask,ItemID, item):
    
        maskOffset = self.getBitOffsetIndex(ItemMask)
        maskOffset8Increment = int(maskOffset/8)*8
        
        ItemMask = (ItemMask >> maskOffset8Increment) & 0xFFFF
        
        if(maskOffset8Increment>=32):
            ItemByteOffset += 4
            maskOffset8Increment -= 32
        
        ItemBitOffset = maskOffset8Increment
        
        #special handling for Rutos Letter
        #item ID int(0x1B)
        if item.name=='Bottle with Letter':
            ItemID = int(0x1B)  #theres more special handling in Navi_Hints.asm, if itemID 0x1B, got item if ID correct or King Zora moved
        
        
        return [ItemByteOffset,ItemBitOffset,ItemMask,ItemID]
    
    
    
    def getUpgradeBitmask(self, UpgradeIndex, ItemByteoffset, ItemMask, ItemCategory, name_no_brackets, item ):
                           
        RealMask = ItemMask 
        
        #'Progressive Strength Upgrade'
        #Progressive Scale'
        #Progressive Wallet'
        #'Progressive Hookshot'
        NameTable = [['gorons_bracelet','silver_gauntlets','golden_gauntlets'],['silver_scale','golden_scale'],['adults_wallet','giants_wallet'],['hookshot','longshot']]
        
        ItemID = int(self.item_id_map_Rando[NameTable[UpgradeIndex][self.lastUpgradeIndexes[UpgradeIndex]]])
        self.lastUpgradeIndexes[UpgradeIndex] = self.lastUpgradeIndexes[UpgradeIndex] + 1
        
        
        return self.OptimizeOffsetAndMask(ItemByteoffset,RealMask,ItemID,item)
    
    

    def getActualBitOffsetAndMask(self, actualAddress, ItemMask):
        bitoffset = 0
        mask = ItemMask
        if True: #( ItemMask == 0xFFFFFFFF ):
            #if((actualAddress%4)!=0):
            bitoffset = int((3-actualAddress%4)*8)        #its big endianess, %4 => move to right, magic offset 0xXXA => the real value is 2 Bytes to the right mask FFFF              
            mask = int( (ItemMask << bitoffset) & 0xFFFFFFFFFFFF ) 
        #so example fire arrows is the left Byte        
        return mask



    def getSaveFileAdressAndMaskByItem(self, Item, ItemType, save_context):
        
        address = -1
    
        name_no_brackets = re.sub('\s? \(.*?\)', '', Item.name).strip()
        name_no_brackets = name_no_brackets.replace('Buy ', '')
        address = save_context.give_item_addressAndMask(name_no_brackets)
      
        if address == -1:
            address = save_context.give_item_addressAndMask(name_no_brackets+'s')
            if address == -1:
                return -1
            
            
        ItemByteoffset =  address[0]-address[0]%4   #sometimes its not 32bit alligned?
        ItemMask = int(address[2])
        RealMask = 0   
        ItemCategory = str(address[3])
        
        
            
        if (ItemCategory == 'upgrades'):
            if(name_no_brackets=='Progressive Strength Upgrade'):
                return self.getUpgradeBitmask(0, ItemByteoffset, ItemMask, ItemCategory, name_no_brackets, Item )
            elif(name_no_brackets=='Progressive Scale'):
                return self.getUpgradeBitmask(1, ItemByteoffset, ItemMask, ItemCategory, name_no_brackets, Item )
            elif(name_no_brackets=='Progressive Wallet'):  
                return self.getUpgradeBitmask(2, ItemByteoffset, ItemMask, ItemCategory, name_no_brackets, Item ) 

        elif (ItemCategory == 'magic_acquired'):
            RealMask = 0x00007F00 #FF has the Problem that 0x00 counts as aquired for magic, but for deku sticks its the other way around
        
        elif (ItemCategory == 'bottle_types'):
            if name_no_brackets in SaveContext.bottle_types:
                RealMask = self.getActualBitOffsetAndMask(address[0]+self.lastBottleIndex, 0x00FF)  
                self.lastBottleIndex += 1
                
            #Bottles:bitmask 2 bytes to high, 0xFFFFFFFF=> 0xFFFF16FF => 0xFFFF161B => 0xFFFF161B 0x1E
                #green potion drunk 0x16->0x14
                #these are the Item Ids
            
        elif (ItemCategory == 'quest'):
            if ( ItemMask == 0xFFFFFFFF): 
                RealMask = self.getActualBitOffsetAndMask(address[0], 0xFFFF)
            else:
                RealMask = ItemMask
            
        elif(ItemCategory == 'item_slot'):  
            if ( ItemMask == 0xFFFFFFFF): 
                RealMask = self.getActualBitOffsetAndMask(address[0], 0xFFFF)
            else:
                RealMask = int((ItemMask << 16)&0xFFFF0000)    #Rando gives some masks 2 Bytes down                  
                
            if(name_no_brackets=='Progressive Hookshot'):
                return self.getUpgradeBitmask(3, ItemByteoffset, RealMask, ItemCategory, name_no_brackets, Item )        
                

        elif(ItemCategory == 'equip_items'):
            if ( ItemMask == 0xFFFFFFFF): 
                RealMask = self.getActualBitOffsetAndMask(address[0], 0xFFFF)
            else:       
                RealMask = int((ItemMask << 16)&0xFFFF0000)    #Rando gives some masks 2 Bytes down                  


        ItemID = 0
        return self.OptimizeOffsetAndMask(ItemByteoffset,RealMask,ItemID, Item)
       

    
    def Navi_Hints_patch_LookUpTableItem(self, ItemByteoffset, ItemBitoffset, ItemMask, ItemID, sphere_nr, CurLookupTablePointerB, rom):
        bArray = bytearray()
        #bArray.extend(map(ord, itemid))
        bArray = ItemByteoffset.to_bytes(2, 'big')
        rom.write_bytes(CurLookupTablePointerB, bArray)
        bArray = ItemBitoffset.to_bytes(1, 'big')
        rom.write_bytes(CurLookupTablePointerB+2, bArray)
        
        bArray = ItemMask.to_bytes(2, 'big')
        rom.write_bytes(CurLookupTablePointerB+4, bArray)
        
        bArray = ItemID.to_bytes(1, 'big')
        rom.write_bytes(CurLookupTablePointerB+6, bArray)
        
        bArray = int(sphere_nr).to_bytes(1, 'big')
        rom.write_bytes(CurLookupTablePointerB+7, bArray)
        
                                  
             
    def getLocationTests(self, location, spoiler):
        
        LocationList = list()
        
        #Bottle with Letter / Rutos letter should be handled seperately since you can't use it as bottle
        if location.item.info.bottle: # or (location.item.name=='Bottle with Letter'): #TBD test
            for (sphere_nr, sphere) in spoiler.playthrough.items():
                for (locationB) in sphere:
                    if locationB.item.info.bottle:# or (locationB.item.name=='Bottle with Letter'):
                        LocationList.append(locationB)
        else:
            for (sphere_nr, sphere) in spoiler.playthrough.items():
                for (locationB) in sphere:
                    if str(locationB.item.name) == str(location.item.name):
                        LocationList.append(locationB)
                    
        RemoveList = list()
        length = len(LocationList)
        i = int(0)
        for n in range(i+1, length):
            if (LocationList[i].filter_tags != None) and (LocationList[n].filter_tags != None):
                if(str(LocationList[i].filter_tags[0]) == str(LocationList[n].filter_tags[0]) ):
                    RemoveList.append(LocationList[n])
                    
                 
        locationexact = 'check '
        locationexact = locationexact + str(LocationList[0])
        
        LocationToUseCount = len(LocationList)
        for i in range(0,LocationToUseCount):
            if(location == LocationList[i]):
                LocationToUseCount = i + 1 # get multiple locations if its not the first Location in the row, in which you can get the item
                break
        
        for i in range(1,LocationToUseCount):
            locationexact = locationexact + ' or ' + str(LocationList[i]) + ' '
            
        locationvague = locationexact
        
        
        if(LocationList[0].filter_tags != None):
            locationvague = 'Maybe we find something in ' + str(LocationList[0].filter_tags[0])
            
            for locationC in RemoveList:
                LocationList.remove(locationC)   
                
            LocationToUseCount = len(LocationList)
            for i in range(0,LocationToUseCount):
                if(location == LocationList[i]):
                    LocationToUseCount = i + 1 # get multiple locations if its not the first Location in the row, in which you can get the item
                    break    
                
            for i in range(1,LocationToUseCount):
                if(LocationList[i].filter_tags != None):
                    locationvague = locationvague + ' or ' + str(LocationList[i].filter_tags[0]) + ' '
                else:
                    locationvague = locationvague + ' or check ' + str(LocationList[i]) + ' '
                                                                
            
        #get all items with this str(location.item.name) in an array
        #for the first one, normal location output
        #for the others, combine the locations
        #limit string length
        
        maxlen = 0x7C-6-4
        locationexact = (locationexact[:maxlen] + '..') if len(locationexact) > maxlen else locationexact
        locationvague = (locationvague[:maxlen] + '..') if len(locationvague) > maxlen else locationvague
        return [locationexact, locationvague]
                        
                                     
                 
    def Navi_Hints_patch_internal(self, rom, world, spoiler, save_context, outfile, messages):
        # Save Navi Texts in Rom
        CurNavi_Hints_TextID = self.Navi_TextID_Base
                  
        add_message(messages, get_raw_text(lineWrap("I have faith in you, you can progress")), id=CurNavi_Hints_TextID)
        CurNavi_Hints_TextID += 1
        
        # set LookUp Table for Navi Texts        
        CurLookupTablePointerB = self.NAVI_HINTS_DATA_GENERATED_LOOKUPTABLE_ROM

        self.Reset()            
                    
        for (sphere_nr, sphere) in spoiler.playthrough.items():
            for (location) in sphere:
                if str(location) != 'Links Pocket':
                    if str(location.item.name) != 'Gold Skulltula Token':
                        adressAndMask = -1
                        
                        adressAndMask = self.getSaveFileAdressAndMaskByItem(location.item,str(location.item.type),save_context)
                        if adressAndMask == -1:
                            breakpoint = 5;
                            continue
                        
                        ItemByteoffset =  adressAndMask[0]
                        ItemBitoffset =  adressAndMask[1] 
                        ItemMask = adressAndMask[2]
                        ItemID = adressAndMask[3]
                        
                        locTexts = self.getLocationTests(location, spoiler)
                        locationexact = locTexts[0]
                        locationvague = locTexts[1]
                        

                        if world.settings.Navi_Hints_exact:
                            add_message(messages, get_raw_text(lineWrap(locationexact)), id=CurNavi_Hints_TextID)
                        else:
                            add_message(messages, get_raw_text(lineWrap(locationvague)), id=CurNavi_Hints_TextID)
                        CurNavi_Hints_TextID += 1
                        
                        self.Navi_Hints_patch_LookUpTableItem(ItemByteoffset, ItemBitoffset, ItemMask, ItemID, sphere_nr, CurLookupTablePointerB, rom)
                        CurLookupTablePointerB += 8
                        
                        if world.settings.create_spoiler:
                            if(outfile != None):
                                outfile.write('\n %s: %s : %s' % (sphere_nr, location, location.item ) )
                
                     
        add_message(messages, get_raw_text(lineWrap("We got everything we need, lets beat Ganon")), id=CurNavi_Hints_TextID)
        CurNavi_Hints_TextID += 1 
          
        #end of LookUp Table
        rom.write_bytes(CurLookupTablePointerB, [0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00])  
                        
    
                        
    
        
    def Navi_Hints_patch(self, rom, world, spoiler, save_context, outfilebase, messages):
        if world.settings.Navi_Hints:
            #write global variables
            asmglobal1_Timer_initvalue = int(0)
            asmglobal2_LookupTableIndex_initvalue = int(0)
            asmglobal3_MaxTimer_initvalue = int(0xd90 * int(world.settings.Navi_Hints_delay) ) #0xd90 = 1min TBD over UI # Write Navi Delay Time to ROM TBD TBD
            asmglobal4_FlagForAsmHack_initvalue = int(0)
            
            glob1 = list(bytearray(asmglobal1_Timer_initvalue.to_bytes(4, 'big')))
            glob2 = list(bytearray(asmglobal2_LookupTableIndex_initvalue.to_bytes(4, 'big')))
            glob3 = list(bytearray(asmglobal3_MaxTimer_initvalue.to_bytes(4, 'big')))
            glob4 = list(bytearray(asmglobal4_FlagForAsmHack_initvalue.to_bytes(4, 'big')))
            byteArray = bytearray( glob1 + glob2 + glob3 + glob4 )
            
            rom.write_bytes(self.NAVI_HINTS_ROM_GLOBALS, byteArray)
            
            
            #write TextIDBase
            asmglobal5_TextIDBase_initvalue = int(self.Navi_TextID_Base)
            byteArray = bytearray(asmglobal5_TextIDBase_initvalue.to_bytes(4, 'big'))   
            
            rom.write_bytes(self.NAVI_HINTS_TEXTID_BASE, byteArray)
            
            
            
            spoiler_path = ""     
            if world.settings.create_spoiler: 
                output_dir = default_output_path(world.settings.output_dir)      
                spoiler_path = os.path.join(output_dir, '%s_NaviHintsSpoiler.txt' % outfilebase)
                with open(spoiler_path, 'w') as outfile:
                        outfile.write('OoT Randomizer Navi Hints\n\n')
                        outfile.write('\nPlaythrough:\n\n')
                        self.Navi_Hints_patch_internal(rom, world, spoiler, save_context, outfile, messages)
                        
            else:
                self.Navi_Hints_patch_internal(rom, world, spoiler, save_context, None)          
            