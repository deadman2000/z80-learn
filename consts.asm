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

; Ports

; Keyboard
; Port  bit0  bit1   bit2 bit3 bit4
; ----  ----  ----   ---- ---- ----
; $FEFE Shift Z      X    C    V
; $FDFE A     S      D    F    G
; $FBFE Q     W      E    R    T
; $F7FE 1     2      3    4    5
; $EFFE 0     9      8    7    6
; $DFFE P     O      I    U    Y
; $BFFE Enter L      K    J    H
; $7FFE Space Symbol M    N    B

; Memory
ScreenStart             EQU 0x4000
ScreenLen               EQU 0x1800
AttrStart               EQU ScreenStart+ScreenLen
SecScreenStart          EQU 0xC000
SecAttrStart            EQU SecScreenStart+ScreenLen
AttrLen                 EQU 32*24

; Macros

; Setup border color
    MACRO BORDERCOLOR color
    ld a, color
    ld c, 254
    out (c), a
    ENDM
