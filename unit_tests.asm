    SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
    DEVICE ZXSPECTRUM128
    
    include "unit_tests.inc"
    include "consts.inc"

    ORG 0x8000
CodeStart:
    UNITTEST_INITIALIZE
    ret

    include "mouse.inc"

    MODULE TestSuite_Mouse

UT_NoMove
    ld a, 0x80 ; new coord
    ld b, 0x80 ; prev coord
    ld c, 0x50 ; Cursor pos
    call CalcCursorPosX
    nop ; ASSERTION a == 0x50
    TC_END

UT_ShiftRight: ; Shift 1 pixels right without overflow
    ld a, 0x81 ; new coord
    ld b, 0x80 ; prev coord
    ld c, 0x00 ; Cursor pos
    call CalcCursorPosX
    nop ; ASSERTION a == 0x01
    TC_END

UT_ShiftRightOverflow: ; Shift 2 pixels right with overflow
    ld a, 0x01 ; new coord
    ld b, 0xff ; prev coord
    ld c, 0x00 ; Cursor pos
    call CalcCursorPosX
    nop ; ASSERTION a == 0x02
    TC_END
    
UT_ShiftRightEdge: ; Shift mouse right over screen
    ld a, 0x82 ; new coord
    ld b, 0x80 ; prev coord
    ld c, 0xff ; cursor coord
    call CalcCursorPosX
    nop ; ASSERTION a == 0xff
    TC_END

UT_ShiftRightEdgeOverflow: ; Shift mouse right over screen with overflow
    ld a, 0x02 ; new coord
    ld b, 0xff ; prev coord
    ld c, 0xfe ; cursor coord
    call CalcCursorPosX
    nop ; ASSERTION a == 0xff
    TC_END

UT_ShiftLeft: ; Shift 1 pixels right
    ld a, 0x80 ; new coord
    ld b, 0x81 ; prev coord
    ld c, 0x02 ; Cursor pos
    call CalcCursorPosX
    nop ; ASSERTION a == 0x01
    TC_END

UT_ShiftLeftOverflow: ; Shift 2 pixels right with overflow
    ld a, 0xfe
    sub 0xff

    ld a, 0xff ; new coord
    ld b, 0x01 ; prev coord
    ld c, 0x02 ; Cursor pos
    call CalcCursorPosX
    nop ; ASSERTION a == 0x00
    TC_END

UT_ShiftLeftEdge: ; Shift mouse left over screen
    ld a, 0x60
    sub 0xf2

    ld a, 0x60 ; new coord
    ld b, 0x72 ; prev coord
    ld c, 0x0A ; cursor coord
    call CalcCursorPosX
    nop ; ASSERTION a == 0x00
    TC_END

UT_ShiftLeftEdgeOverflow: ; Shift mouse left over screen with overflow
    ld a, 0xf5 ; new coord
    ld b, 0x06 ; prev coord
    ld c, 0x05 ; cursor coord
    call CalcCursorPosX
    nop ; ASSERTION a == 0x00
    TC_END

    ENDMODULE
    
    SAVESNA "unit_tests.sna", CodeStart