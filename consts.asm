; ROM functions
ROM_OPEN_CHANNEL        EQU 0x1601
ROM_PRINT               EQU 0x203C

; Symbols
AT                      EQU 0x16

; Colors
BLACK                   EQU 0
BLUE                    EQU 1
RED                     EQU 2
MAGENTA                 EQU 3
GREEN                   EQU 4
CYAN                    EQU 5
YELLOW                  EQU 6
WHITE                   EQU 7

; Memory
ScreenStart             EQU 0x4000
ScreenLen               EQU 0x1800
AttrStart               EQU ScreenStart+ScreenLen
SecScreenStart          EQU 0xC000
SecAttrStart            EQU SecScreenStart+ScreenLen
AttrLen                 EQU 32*24