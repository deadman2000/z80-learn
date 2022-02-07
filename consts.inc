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

; FF58..FFFF Reserved          | Bank 0  | Bank 1 | Bank 2 | Bank 3 | Bank 4 | Bank 5  | Bank 6 | Bank 7
; C000..FF57 Avaliable memory  |                                             | Screen1 |        | Screen2

; 8000..BFFF Avaliable memory  | Bank 2

; 5CCB..7FFF Avaliable memory  |
; 5CC0..5CCA Reserved          |
; 5C00..5CBF System variables  | Bank 5
; 5B00..5AFF Printer buffer    |
; 4000..57FF Screen            |

; 0000..3FFF ROM

; Screen
; 256x192 pixels   32x24 cells

; Pixel address:
; 15| 14| 13| 12| 11| 10| 9 | 8 || 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0
; 0   1   0   y7  y6  y2  y1  y0 | y5  y4  y3  x4  x3  x2  x1  x0

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
    ld c, 0xfe
    out (c), a
    ENDM
