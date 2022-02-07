
ReadMouseCoords:
    ld bc, 0xfbdf ; get mouse X
    in a, (c)
    ld hl, PrevMouseX
    ld b, (hl)
    ld (PrevMouseX), a
    ld hl, CursorX
    ld c, (hl)
    call CalcCursorPosX
    ld (CursorX), a

    ld bc, 0xffdf ; get mouse Y
    in a, (c)   ; swap a anb b, for invert shift sign
    ld hl, PrevMouseY
    ld b, (hl)
    ld (PrevMouseY), a
    ld hl, CursorY
    ld c, (hl)
    call CalcCursorPosY
    ld (CursorY), a
    ret

; Calculating cursor position
; a - current mouse value
; b - previous mouse value
; c - current cursor coord
; Result:
; a - new cursor coord
CalcCursorPosX:
    sub b              ;  a = shift. flag C if left
    jr z, CCPX_NoMove  ; curr == prev. return
    cp 0x80
    jr nc, CCPX_Left    ; diff >= 128 ? move left
    add c              ; a = new coord (not limited) = curr coord + shift
    cp c
    ret nc ; return if a >= c (coord not overflowed)
    ld a, 0xff
    ret
CCPX_Left:
    add c              ; a = new coord (not limited) = curr coord + shift
    cp c
    ret c ; return if a < c (coord not overflowed)
    ld a, 0
    ret
CCPX_NoMove:
    ld a, c
    ret

; Calculating cursor position
; a - current mouse value
; b - previous mouse value
; c - current cursor coord
; Result:
; a - new cursor coord
CalcCursorPosY:
    ld d, a ; swap a and b
    ld a, b
    ld b, d
    sub b    ;  a = shift. flag C if left
    jr z, CCPX_NoMove  ; curr == prev. return
    cp 0x80
    jr nc, CCPY_Up    ; diff >= 128 ? move up

    add c
    cp c
    jr c, CCPY_Max ; go to CCPY_Max if a < c and value overflowed
    cp 8*8*3
    ret c
CCPY_Max:
    ld a, 8*8*3-1 ; max y value
    ret
CCPY_Up:
    add c
    cp c
    ret c ; return if a < c
    ld a, 0
    ret

DrawCursor:
    ld a, (CursorY) ; Store CursorY to DrawCursorY for incrementing
    ld (DrawCursorY), a

    ; Calc pos in cell
    ld a, (CursorX)  ; a = x
    and 0x7
    ld (CursorX_InCell), a

    ld b, 8          ; cursor height - 8 rows
    ld hl, CursorImg ; Cursor start address
DrawCursorRow:
    push bc

    ; calculating coords
    ; 15| 14| 13| 12| 11| 10| 9 | 8 || 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0
    ; 0   1   0   y7  y6  y2  y1  y0 | y5  y4  y3  x7  x6  x5  x4  x3

    ld bc, ScreenStart ; bc = 0100 0000 0000 0000
    ld a, (DrawCursorY)
    ; y0..y2
    and 7
    or b
    ld b, a  ; b = 010 xx y2..y0

    ld a, (DrawCursorY)
    ; y3..y5
    .3 rra   ; a = xxx y7..y3
    ld e, a
    and 0x18 ; a = 000 y7..y6 000
    or b
    ld b, a  ; b = 010 y7..y6 y2..y0
    
    ; y6..y7
    ld a, e  ; a = xxx y7..y3
    and 7    ; a = 00000 y5..y3
    .5 rla   ; a = y5..y3 00000   ; TODO .3 rra
    or c
    ld c, a  ; c = y5..y3 00000

    ; calc x
    ld a, (CursorX)  ; a = x
    .3 rra           ; a = xxx x7..x3
    and 0x1f         ; a = 000 x7..x3
    ld (CursorColumn), a
    or c
    ld c, a
    ; end calc

    ld de, bc

    ld a, (CursorX_InCell)
    or a
    jr z, DrawCursorZeroX
    ld b, a    ; b = X coord in cell
    ld a, (hl) ; get cursor image row
ShiftCursorX_Right:
    rra
    and 0x7f
    djnz ShiftCursorX_Right
    jr DrawCursorXOR

DrawCursorZeroX:
    ld a, (hl)
    
DrawCursorXOR:
    ld c, a
    ld a, (de) ; load current screen pixels
    xor c
    ld (de), a ; load row into screen memory

; Drawing right orverflowed part
    ld a, (CursorColumn)
    xor 0x1f
    jr z, DrawRowEnd ; Last column
    ld a, (CursorX_InCell)
    or a
    jr z, DrawRowEnd ; Zero aligned
    sub 8
    neg    ; a = 8 - a
    ld b, a
    ld a, (hl) ; get cursor image row
ShiftCursorX_Left:
    rla
    and 0xfe
    djnz ShiftCursorX_Left 
    
    ld c, a
    inc e
    ld a, (de) ; load current screen pixels
    xor c
    ld (de), a ; load row into screen memory
    dec e

DrawRowEnd:
    ; DrawCursorY++
    ld a, (DrawCursorY)
    inc a
    cp 192
    jr nc, DrawEndOverflowY
    ld (DrawCursorY), a

    inc d ; increment y coord
    inc hl
    pop bc
    djnz DrawCursorRow
    ret
DrawEndOverflowY:
    pop bc
    ret

PrevMouseX: db 0
PrevMouseY: db 0

CursorX: db 0x3e ; 16*8 ; Cursor position in pixels 0..255
CursorColumn: db 16 ; Cursor cell number 0..31
CursorX_InCell: db 0 ; Cursor position in cell 0..7
CursorY: db 10*8
DrawCursorY: db 0

CursorImg:
    dg 1-------
    dg 11------
    dg 1-1-----
    dg 11-1----
    dg 111-1---
    dg 111111--
    dg 1-11----
    dg 11------
