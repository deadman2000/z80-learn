    SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
    DEVICE ZXSPECTRUM128

    include "consts.inc"


StackTop               EQU 0x8100
CodeStart              EQU 0x8100

    org CodeStart
    di
    ld sp, StackTop
    ei

    ;call DrawLine ; 6760
    ;call DrawLine2 ; 22949

    ; Switch memory 0xC000..0xFFFF to RAM7 - second screen bank
    ld bc, 0x7ffd
    ld a, %00010111
    out (c), a

    ; clear pixels on second screen
    xor a
    ld (SecScreenStart), a
    ld hl, SecScreenStart
    ld de, SecScreenStart+1
    ld bc, ScreenLen
    ldir

    ; clear attributes on second screen
    ld a, %00111000
    ld (SecAttrStart), a
    ld hl, SecAttrStart
    ld de, SecAttrStart+1
    ld bc, AttrLen
    ldir

    call DrawCursor

Loop:
    halt

    BORDERCOLOR BLACK
    call DrawCursor ; Remove cursor from screen
    call ReadMouseCoords
    call DrawCursor ; Draw new cursor

    ld a, 2
    call ROM_OPEN_CHANNEL
    
    ;  BORDERCOLOR MAGENTA
    ;call PrintFrames ; 10372

    ;BORDERCOLOR BLUE
    ;call PrintLastKey ; 19301

    BORDERCOLOR RED
    call PrintMouseCoords ; 10374

    BORDERCOLOR GREEN
    call ProcessKeyboard

    BORDERCOLOR CYAN
    call DrawLine ; 6760

    BORDERCOLOR WHITE
    jr Loop


    include "mouse.inc"

; Drawing vertical line from top to bottom screen
DrawLine:
    ;ld a, 0x80  ; draw first pixel in cell row
    ld hl, ScreenStart ; start cell address
    ld b, 3     ; blocks count
DrawBlock:
    push bc
    push hl
    ld b, 8     ; rows count
DrawRow:
    push bc
    push hl
    ld b, 8     ; cell height
DrawPixelCell:
    ld a, (hl) ; Invert first bit
    xor 0x80
    ld (hl), a
    inc h
    djnz DrawPixelCell
    ; Next row
    pop hl
    ld bc, 0x0020 ; next row offset
    add hl, bc
    pop bc
    djnz DrawRow
    ; Next block
    pop hl
    ld bc, 0x0800 ; next block offset
    add hl, bc
    pop bc
    djnz DrawBlock
    ret

; Drawing vertical line by decrementing y-coord and calc pixel address
; Pixel address:
; 15| 14| 13| 12| 11| 10| 9 | 8 || 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0
; 0   1   0   y7  y6  y2  y1  y0 | y5  y4  y3  x4  x3  x2  x1  x0
DrawLine2:
    ld b, 191   ; lines count
DrawLine2Next:
    push bc
    ld a, b
    and %00000111
    or %01000000
    ld h, a
    ld a, b
    .3 rra
    and %00011000
    or h
    ld h, a

    ld a, b
    .2 rla
    and %11100000
    ld l, a

    ld (hl), 0x80

    pop  bc
    djnz DrawLine2Next

    ret


PrintFrames:
    ; Get frame counter
    ld hl, (0x5C78)
    ld a, h
    call NumToHex
    ld (CoordsStr+3), de
    ld a, l
    call NumToHex
    ld (CoordsStr+6), de

    ; Text coords
    ld de, #0001
    ld (CoordsStr+1), de

    ; Printing
    ld de, CoordsStr
    ld bc, CoordsStrLen
    call ROM_PRINT
    ret

PrintLastKey:
    ld a, (0x5C08) ; Get last key
    ld (LastKeyCodeStr+13), a

    ; Printing
    ld de, LastKeyCodeStr
    ld bc, LastKeyCodeStrLen
    call ROM_PRINT
    ret

; Includes ProcessKeyboard
PrintKeyboard:
    ld de, #0003 ; Text coords
    ld (NumStr+1), de
    
    ld bc, 0x7ffe
    in a, (c)
    call NumToHex
    ld (NumStr+3), de
    
    ld de, NumStr ; Printing
    ld bc, NumStrLen
    call ROM_PRINT
    
ProcessKeyboard:
    ld bc, 0x7ffe
    in a, (c)
    and 0x01 ; check spacebar
    jr z, SpacePressed
    xor a
    ld (SpaceIsPressed), a
    ret

SpacePressed:
    ld a, (SpaceIsPressed)
    or a
    ret nz

    ld a, 1
    ld (SpaceIsPressed), a
    ld bc, 0x7ffd
    ld a, (RamMode)
    xor %00001000
    ld (RamMode), a
    out (c), a
    ret

SpaceIsPressed:
    db 0
RamMode:
    db %00010111

PrintMouseCoords:
    ld a, (CursorX)
    call NumToHex
    ld (CoordsStr+3), de

    ld a, (CursorY)
    call NumToHex
    ld (CoordsStr+6), de

    ; Text coords
    ld de, #0000
    ld (CoordsStr+1), de

    ; Printing
    ld de, CoordsStr
    ld bc, CoordsStrLen
    call ROM_PRINT

    
    ld bc, 0xfbdf ; get mouse X
    in a, (c)
    call NumToHex
    ld (CoordsStr+3), de
    
    ld bc, 0xffdf ; get mouse Y
    in a, (c)
    call NumToHex
    ld (CoordsStr+6), de

    ; Text coords
    ld de, #0600
    ld (CoordsStr+1), de
    
    ; Printing
    ld de, CoordsStr
    ld bc, CoordsStrLen
    call ROM_PRINT

    ret

CoordsStr:
    db AT,0,0,"00:00"
CoordsStrLen:  EQU $ - CoordsStr

LastKeyCodeStr:
    db AT,2,0,"Last key: x"
LastKeyCodeStrLen:  EQU $ - LastKeyCodeStr

NumStr:
    db AT,0,0,"00"
NumStrLen:  EQU $ - NumStr

; a - input number
; de - output chars
NumToHex:
    push af ; save a
    ld e, a
    and 0x0f
    call HexChar
    ld d, a ; save result
    ld a, e
    .4 rrca    ; Shift value to get high oct
    and 0x0f
    call HexChar
    ld e, a ; save result
    pop af  ; return original a value
    ret

; Convert a lower 4bit to hex letter
HexChar:
    cp 10
    jr c, Hex0 ; a < 10 ? return digit
    add 'A'-10
    ret
Hex0:
    add '0'
    ret

; Drawing line on border
; a line color
; d background color
DrawBorderLine:
    ld c, 254
    out (c), a
    ld b, 5
Delay1:
    djnz Delay1
    out (c), d
    ret

CodeLength:    EQU $-CodeStart+1

    SAVESNA "test.sna", CodeStart
    SAVETAP "test.tap", CodeStart
