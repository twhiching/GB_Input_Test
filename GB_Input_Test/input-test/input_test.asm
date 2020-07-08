; This section is for including files that either need to be in the home section, or files where it doesn't matter 
SECTION "Includes@home",ROM0

; Prior to importing GingerBread, some options can be specified

; Max 15 characters, should be uppercase ASCII
GAME_NAME EQUS "INPUT TEST" 

; Include SGB support in GingerBread. This makes the GingerBread library take up a bit more space on ROM0. To remove support, comment out this line (don't set it to 0)
;SGB_SUPPORT EQU 1 

; Include GBC support in GingerBread. This makes the GingerBread library take up slightly more space on ROM0. To remove support, comment out this line (don't set it to 0)
;GBC_SUPPORT EQU 1

; Set the size of the ROM file here. 0 means 32 kB, 1 means 64 kB, 2 means 128 kB and so on.
ROM_SIZE EQU 1 

; Set the size of save RAM inside the cartridge. 
; If printed to real carts, it needs to be small enough to fit. 
; 0 means no RAM, 1 means 2 kB, 2 -> 8 kB, 3 -> 32 kB, 4 -> 128 kB 
RAM_SIZE EQU 1

;Macro for copying a rectangular region into VRAM
; Changes ALL registers
; Arguments:
; 1 - Height (number of rows)
; 2 - Width (number of columns)
; 3 - Source to copy from
; 4 - Destination to copy to
CopyRegionToVRAM: MACRO

I SET 0
REPT \1

    ld bc, \2
    ld hl, \3+(I*\2)
    ld de, \4+(I*32)
    
    call mCopyVRAM
    
I SET I+1
ENDR
ENDM    

INCLUDE "gingerbread.asm"
INCLUDE "/mnt/c/Users/mikei/Desktop/Gameboy/gingerbread/examples/myExamples/images/input_test.inc"

SECTION "RAM variables", WRAM0[USER_RAM_START]
PLAYER_POSITION: DS 2
ALTERNATING_TILES: DS 2  ; ALTERNATING_TILES+x, 0 for decrement, 1 for increment
ALTERNATING_TILES_RUNNING: DS 2 ; ALTERNATING_TILES+x, 0 for decrement, 1 for increment
SPRITE_FLIP: DS 1; Keeps track on wheter have sprite flipped horizontally or not
WAIT_VAR: DS 1; Keeps track of the wait variable, used in the function shortWait
CURRENT_INPUT: DS 1; Holds the value of the current input
PREVIOUS_INPUT: DS 1; Holds the value of the previous input
PALETTE_SWITCH: DS 1; Keeps track if BGB, OBP0 and OBP1 palette has been switch
PLAYER_VELOCITY: DS 2; Holds the current velocity value in the x and y axis
TIME_SINCE_JUMP: DS 1; A variable that increments once the player has jumped
GRAVITY_STRENGTH: DS 1; Holds the value of the strength of gravity
HAS_JUMPED: DS 1; Keeps track of players jump and if they are still holding down the a button


SECTION "Text definitions",ROM0 
; Charmap definition (based on the pong.png image, and looking in the VRAM viewer after loading it in BGB helps finding the values for each character)
CHARMAP "<rightDPad>",$26
CHARMAP "<leftDPad>",$25
CHARMAP "<upDPad>",$14
CHARMAP "<downDPad>",$37
CHARMAP "<top_L_A>",$17
CHARMAP "<top_R_A>",$18
CHARMAP "<bottom_L_A>",$29
CHARMAP "<bottom_R_A>",$2A
CHARMAP "<top_L_B>",$15
CHARMAP "<top_R_B>",$16
CHARMAP "<bottom_L_B>",$27
CHARMAP "<bottom_R_B>",$28
CHARMAP "<leftSelect>", $38
CHARMAP "<rightSelect>", $39
CHARMAP "<leftStart>", $3A
CHARMAP "<rightStart>", $3B
CHARMAP " ", $00
CHARMAP "<end>", $60

blankSpace:
DB "  <end>"

rightDPadTiles:
DB "<rightDPad><end>"

leftDPadTiles:
DB "<leftDPad><end>"

upDPadTiles:
DB "<upDPad><end>"

downDPadTiles:
DB "<downDPad><end>"

selectTiles:
DB "<leftSelect><rightSelect><end>"

startTiles:
DB "<leftStart><rightStart><end>"

topAButtonTiles:
DB "<top_L_A><top_R_A><end>"

bottomAButtonTiles:
DB "<bottom_L_A><bottom_R_A><end>"

topBButtonTiles:
DB "<top_L_B><top_R_B><end>"

bottomBButtonTiles:
DB "<bottom_L_B><bottom_R_B><end>"

SECTION "StartOfGameCode",ROM0    
begin: ; GingerBread assumes that the label "begin" is where the game should start
   
    ; Set up work that needs to be done before the main game loop

    ; Load in tile data into vram
    ld hl, input_test_tile_data
    ld de, TILEDATA_START
    ld bc, input_test_tile_data_size
    call mCopyVRAM
   
    ;call StartLCD
    ; Prep the LCD and set it to use 8x8 sprites
    ld  a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00|LCDCF_WINOFF
    ld  [rLCDC], a


    ; Load in the map data into vram
    CopyRegionToVRAM 18, 20, input_test_map_data, BACKGROUND_MAPDATA_START

    ; Set up player position
    ld a, 82 ;X pos
    ld [PLAYER_POSITION], a
    ld a, 128 ; Y pos
    ld [PLAYER_POSITION+1], a

    ; Set up player velocity
    xor a
    ld [PLAYER_VELOCITY], a    ; X velocity
    ld [PLAYER_VELOCITY+1], a  ; Y velocity
    
    ; Set up values for the ALTERNATING_TILES var's
    ld a, 0; 
    ld [ALTERNATING_TILES], a
    ld a, 0; 
    ld [ALTERNATING_TILES+1], a

   
    ; Set up values for the ALTERNATING_TILES_RUNNING var's
    ld a, 0; 
    ld [ALTERNATING_TILES_RUNNING], a
    ld a, 0; 
    ld [ALTERNATING_TILES_RUNNING+1], a

    ; Set up value for the WAIT_VAR
    ld a, 7
    ld [WAIT_VAR], a

    ; Set up value for the PALETTE_SWITCH
    xor a
    ld [PALETTE_SWITCH], a

    ; Set up the value for the time since player has jumped
    xor a
    ld [TIME_SINCE_JUMP], a
   
    ; Set up the value for gravity
    ld a, 3
    ld [GRAVITY_STRENGTH], a
 
    ; Set up the sprite flip var to not be set, ie with a value of zero
    xor a
    ld [SPRITE_FLIP], a
    
    ; Set up the has jumped variable to default
    ld [HAS_JUMPED], a

    ; Load up sprite information then call the fucntion that draws the sprite onscreen 
    ld b, $0E
    ld h, $19
    ld d, $2B
    call drawSprite 

    ; Clear out a and load it into b. B is used to keep track of past input values.
    xor a
    ld [CURRENT_INPUT], a
    ld [PREVIOUS_INPUT], a

    ;ld b, a

; Main game loop
main:
    halt 
    nop 

    ld a, [PREVIOUS_INPUT]
    ld b, a
    call ReadKeys
    ld [CURRENT_INPUT], a    
    
    .processInput 
    ; Check to see if the player has pressed any new buttons
    ; Or is continuing to hold down any buttons    
    cp b
    call nz, displayTiles
    cp 0
    call nz, displayTiles
   
    ; Update the player's velocity
    call alterVelocity
     
    ; Load in the correct sprites based on the button press the player has made
    .if
        
        ;Check if player is crouching down
        .firstIf
            ld a, [CURRENT_INPUT]
            and KEY_DOWN
            cp 0
            jr nz, .drawCrouch
            jr .firstIf2
            
            .drawCrouch
                ; Check if player is in the air
                ld a, [PLAYER_POSITION+1]
                cp 128
                jr nz, .firstIf2                

                ld a, [PLAYER_VELOCITY]
                ld b, a
                ld a, [PLAYER_POSITION]
                add b
                ld [PLAYER_POSITION], a                
 
                ld b, $FF
                ld h, $23 
                ld d, $35                 
                jp .endIf

        ; Check if player is moving on the x axis
        .firstIf2
            ld a, [PLAYER_VELOCITY]
            cp 0
            jr nz, .xAxis
            jr .thirdIf
            .xAxis
                call displayHorizontal

        ; Check if player is moving on the y axis
        .thirdIf
            ; First check if player is off ground by looking at y pos. 
            ; If so continue on with the jump calculation
            ld a, [PLAYER_POSITION+1]
            cp 128
            jr nz, .yAxis

            ; This condition checks to see if the y velocity falls within certain ranges
            ; If 12 < y velocity < 20 && A button is not pressed || y velocity == 20 
            ; If the above condition is true, the jump calcualtion may proceded
            .condition
                ; Check if it is zero, if so don't calculate jump    
                ld a, [PLAYER_VELOCITY+1]
                cp 0
                jr z, .endCondition

                ; Checks if the y velocity is greater than 12
                .isGreater12
                    cp 12
                    jr nc, .isLessThan20
                    jr  .isANotPressed

                ; Checks if the y velocity is less than 20
                .isLessThan20
                    cp 20
                    jr c, .isANotPressed
                    jr .is20
    
                ; Checks if the y velocity is equal to 20
                .is20
                    cp 20
                    jr z, .yAxis
                    jr .endCondition

                ; Checks to see if A button is not held down
                .isANotPressed
                    ld a, [CURRENT_INPUT]
                    and KEY_A
                    cp 0
                    jr z, .yAxis
            .endCondition
    
            ; Else player is not moving at all
            jr .endIf

            ; Everything has been checked, we are a go to calcuate the jump
            .yAxis
                call displayJump
                jp .draw    
    
    .endIf
    
    halt
    nop

    ; If player had pressed the down button, draw sprite
    ; If player was moving on the x axis solely draw the sprite
    ; Otherwise reset default state amd draw netrual sprite 
    .secondIf
    
        ld a, [CURRENT_INPUT]
        and KEY_DOWN
        cp 0
        jr nz, .draw        

        ld a, [PLAYER_VELOCITY]
        cp 0
        jr nz, .draw
        jr .reset

        .draw
            call drawSprite
            call shortWait
            jp main

        .reset
            call resetPlayer
            jp main
    .endSecondIf
    
; This function resets the state of the player charcter
; Sets all values to its default and sets the veliocity in the x and y direction to 0
; At the end it draws the sprite
resetPlayer:
    xor a
    ld [ALTERNATING_TILES], a
    ld [ALTERNATING_TILES+1], a
    
    ld [ALTERNATING_TILES_RUNNING], a
    ld [ALTERNATING_TILES_RUNNING+1], a
 
    ld [PLAYER_VELOCITY], a    ; X velocity

    ; If player is holding down A button, do not reset the Y velocity
    ld a, [CURRENT_INPUT]
    and KEY_A
    cp 0
    jr nz, .continue
    xor a
    ld [PLAYER_VELOCITY+1], a  ; Y velocity
.continue    
    push bc
    ld b, $0E
    ld h, $19
    ld d, $2B
    call drawSprite
    pop bc
    ret

displayTiles:

    ld a, [CURRENT_INPUT]
    ld [PREVIOUS_INPUT], a 
 
    push af
    and KEY_START
    cp 0
    call nz, displayStart
    cp 0
    call z, hideStart
    pop af
    
    push af
    and KEY_SELECT
    cp 0
    call nz, displaySelect
    cp 0
    call z, hideSelect
    pop af

    push af
    and KEY_B
    cp 0
    call nz, displayB
    cp 0
    call z, hideB
    pop af

    push af
    and KEY_A
    cp 0
    call nz, displayA
    cp 0
    call z, hideA
    pop af

    push af
    and KEY_DOWN
    cp 0
    call nz, displayDown
    cp 0
    call z, hideDown
    pop af

    push af
    and KEY_UP
    cp 0
    call nz, displayUp
    cp 0
    call z, hideUp
    pop af

    push af
    and KEY_LEFT
    cp 0
    call nz, displayLeft
    cp 0
    call z, hideLeft
    pop af

    push af
    and KEY_RIGHT
    cp 0
    call nz, displayRight
    cp 0
    call z, hideRight
    pop af
    
    ret 

;input registers are b, h and d
;make sure to load in the start of the head torso and leg torso tile in the respective registers
drawSprite:

    push af

    ;Do quick compare to see if player sprite is crouching our not.
    ld a, b
    cp $FF
    jr z, .clearOutSprite
    jr drawLeftHead

.clearOutSprite
    xor a
    ld [SPRITES_START], a
    ld [SPRITES_START+1], a
    ld [SPRITES_START+2], a
    ld [SPRITES_START+3], a
    ld [SPRITES_START+4], a
    ld [SPRITES_START+5], a
    ld [SPRITES_START+6], a
    ld [SPRITES_START+7], a
    jr drawLeftTorso
    
drawLeftHead:    
    ;-----------------------------------------------Left part of the head
    ld a, [PLAYER_POSITION+1]; Y loaction
    ld [SPRITES_START], a
    ld a, [SPRITE_FLIP]
    cp 32
    ld a, [PLAYER_POSITION]; X location
    jr z, .inc
    jr .continue

.inc
    add 8

.continue
    ld [SPRITES_START+1], a
    ld a, b
    ld [SPRITES_START+2], a
    ld a, [SPRITE_FLIP]
    ld [SPRITES_START+3], a
    
drawRightHead:
    ;-----------------------------------------------Right part of the head
    ld a, [PLAYER_POSITION+1]; Y loaction
    ld [SPRITES_START+4], a
    ld a, [SPRITE_FLIP]
    cp 32
    ld a, [PLAYER_POSITION]; X location
    jr z, .continue

.inc
    add 8

.continue    
    ld [SPRITES_START+5], a
    ld a, b
    inc a
    ld [SPRITES_START+6], a
    ld a, [SPRITE_FLIP]
    ld [SPRITES_START+7], a

drawLeftTorso:
    ;-----------------------------------------------Left part of the torso
    ld a, [PLAYER_POSITION+1]; Y loaction
    add 8
    ld [SPRITES_START+8], a
    ld a, [SPRITE_FLIP]
    cp 32
    ld a, [PLAYER_POSITION]; X location
    jr z, .inc
    jr .continue

.inc
    add 8

.continue
    ld [SPRITES_START+9], a
    ld a, h
    ;ld a, $2E ; Tile number
    ld [SPRITES_START+10], a
    ld a, [SPRITE_FLIP]
    ld [SPRITES_START+11], a
    
drawRightTorso:
    ;----------------------------------------------Right part of the torso
    ld a, [PLAYER_POSITION+1]; Y loaction
    add 8
    ld [SPRITES_START+12], a
    ld a, [SPRITE_FLIP]
    cp 32
    ld a, [PLAYER_POSITION]; X location
    jr z, .continue

.inc
    add 8

.continue
    ld [SPRITES_START+13], a
    ld a, h
    inc a
    ld [SPRITES_START+14], a
    ld a, [SPRITE_FLIP]
    ld [SPRITES_START+15], a

drawLeftLeg:
    ;------------------------------------------------Left part of the legs
    ld a, [PLAYER_POSITION+1]; Y loaction
    add 16
    ld [SPRITES_START+16], a
    ld a, [SPRITE_FLIP]
    cp 32
    ld a, [PLAYER_POSITION]; X location
    jr z, .inc
    jr .continue

.inc
    add 8

.continue
    ld [SPRITES_START+17], a
    ld a, d
    ;ld a, $36 ; Tile number
    ld [SPRITES_START+18], a
    ld a, [SPRITE_FLIP]
    ld [SPRITES_START+19], a
    
drawRightLeg:
    ;-------------------------------------------------Right part of the legs
    ld a, [PLAYER_POSITION+1]; Y loaction
    add 16
    ld [SPRITES_START+20], a
    ld a, [SPRITE_FLIP]
    cp 32
    ld a, [PLAYER_POSITION]; X location
    jr z, .continue

.inc
    add 8

.continue
    ld [SPRITES_START+21], a
    ld a, d
    inc a
    ld [SPRITES_START+22], a
    ld a, [SPRITE_FLIP]
    ld [SPRITES_START+23], a

    pop af
    ret

; This section is for handling the dislplaying of button tiles
;------------------------------------------------------------------------------------------------
displayStart:
    ld b, $60 ; end character 
    ld c, 0 ; draw to background
    ld de, 10 + 32*10 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, startTiles ; Load in select tiles to be prepared to write on screen
    call RenderTextToEndByPosition
    ret

hideStart:
    ld b, $60 ; end character
    ld c, 0 ; draw to background
    ld de, 10 + 32*10 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, blankSpace
    call RenderTextToEndByPosition
    ret

displaySelect:
    ld b, $60 ; end character 
    ld c, 0 ; draw to background
    ld de, 7 + 32*10 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, selectTiles ; Load in start tiles to be prepared to write on screen
    call RenderTextToEndByPosition
   
    ; Save vale of a register
    push af 
    ; Select also flips the color palette
    ; If palette has been switched already, don't seitch it again,
    ; ie if player is hoilding down select
    ld a, [PALETTE_SWITCH]
    cp 0
    jr nz, .ret
    ; BGP palette
    ld h, $FF
    ld l, $47
    ld a, [hl]
    cpl
    ld [hl], a
    
    ; OBP0 palette
    ld l, $48
    ld a, [hl]
    cpl
    ld [hl], a

    ; OBP1 palette
    ld l, $49
    ld a, [hl]
    cpl
    ld [hl], a

    ld a, 1
    ld [PALETTE_SWITCH], a
    call shortWait
.ret
    pop af
    ret

hideSelect:
    ld b, $60 ; end character
    ld c, 0 ; draw to background
    ld de, 7 + 32*10 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, blankSpace
    call RenderTextToEndByPosition
    
    ; Reset palette switch variable
    xor a
    ld [PALETTE_SWITCH], a
    ret

displayB:
    ld b, $60 ; end character 
    ld c, 0 ; draw to background
    ld de, 14 + 32*7 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, topBButtonTiles ; Load in start tiles to be prepared to write on screen
    call RenderTextToEndByPosition
   
    ld de, 14 + 32*8 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, bottomBButtonTiles ; Load in start tiles to be prepared to write on screen
    call RenderTextToEndByPosition
    ret

hideB:
    ld b, $60 ; end character
    ld c, 0 ; draw to background
    ld de, 14 + 32*7 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, blankSpace
    call RenderTextToEndByPosition

    ld de, 14 + 32*8 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, blankSpace
    call RenderTextToEndByPosition
    ret

displayA:
    ld b, $60 ; end character 
    ld c, 0 ; draw to background
    ld de, 16 + 32*6 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, topAButtonTiles ; Load in start tiles to be prepared to write on screen
    call RenderTextToEndByPosition
   
    ld de, 16 + 32*7 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, bottomAButtonTiles ; Load in start tiles to be prepared to write on screen
    call RenderTextToEndByPosition
    ret

hideA:
    ld b, $60 ; end character
    ld c, 0 ; draw to background
    ld de, 16 + 32*6 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, blankSpace
    call RenderTextToEndByPosition

    ld de, 16 + 32*7 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, blankSpace
    call RenderTextToEndByPosition
    
    ; Clear out the has jumped variable
    xor a
    ld [HAS_JUMPED], a
    ret

displayDown:
    ld b, $60 ; end character 
    ld c, 0 ; draw to background
    ld de, 3 + 32*8 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, downDPadTiles ; Load in start tiles to be prepared to write on screen
    call RenderTextToEndByPosition
    ret

hideDown:
    ld b, $60 ; end character
    ld c, 0 ; draw to background
    ld de, 3 + 32*8 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, blankSpace
    call RenderTextToEndByPosition
    ret

displayUp:
    ld b, $60 ; end character 
    ld c, 0 ; draw to background
    ld de, 3 + 32*6 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, upDPadTiles ; Load in start tiles to be prepared to write on screen
    call RenderTextToEndByPosition
    ret

hideUp:
    ld b, $60 ; end character
    ld c, 0 ; draw to background
    ld de, 3 + 32*6 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, blankSpace
    call RenderTextToEndByPosition
    ret

displayLeft:
    ld b, $60 ; end character 
    ld c, 0 ; draw to background
    ld de, 2 + 32*7 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, leftDPadTiles ; Load in start tiles to be prepared to write on screen
    call RenderTextToEndByPosition

    ; Check if the player is on the ground
    ; If so, change the value of the sprite flip
    ld a, [PLAYER_POSITION+1]
    cp 128
    jr z, .flip
    ret

    .flip
        push af
        ld a, 32
        ld [SPRITE_FLIP], a
        pop af
    ret

hideLeft:
    ld b, $60 ; end character
    ld c, 0 ; draw to background
    ld de, 2 + 32*7 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, blankSpace
    call RenderTextToEndByPosition
    ret

displayRight:
    ld b, $60
    ld c, 0
    ld de, 4 + 32*7 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, rightDPadTiles ; Load in start tiles to be prepared to write on screen
    call RenderTextToEndByPosition
 
    ; Check if the player is on the ground
    ; If so, change the value of the sprite flip
    ld a, [PLAYER_POSITION+1]
    cp 128
    jr z, .flip
    ret

    .flip
        push af
        xor a
        ld [SPRITE_FLIP], a
        pop af
    ret

hideRight:
    ld b, $60 ; end character
    ld c, 0 ; draw to background
    ld de, 4 + 32*7 ; X and Y start positions (0-19) & (0-17) Formula:(x+32*y)
    ld hl, blankSpace
    call RenderTextToEndByPosition
    ret

;------------------------------------------------------------------------------------------------

; This functions keeps track of player's x and y velocity and alters it
alterVelocity:

; This section of this functions later the velocity by increasing it
; ie) By changing its value from zero, to a non zero state
;------------------------------------------------------------------------------------------------

    ; Check to see if the a button is pressed down
    .isAPressed
        ld a, [CURRENT_INPUT]
        AND KEY_A
        cp 0
        jr nz, .aPressed
        jr .isLeftPressed
    
        .aPressed
            ; If player is currently in the air, do not alter their y velocity
            ld a, [PLAYER_POSITION+1]
            cp 128
            jr nz, .endAPressed

            ; If player is crouched, do nothing
            ld a, [CURRENT_INPUT]
            AND KEY_DOWN
            cp 0
            jr nz, .endAPressed

            ; If player has jumped already and a button is held down, do not jump again
            ld a, [HAS_JUMPED]
            cp 1
            jp z, .endAPressed

            ; Check to see at what point in the jump the player is currently in 
            ld a, [PLAYER_VELOCITY+1]
            cp 0
            jr z, .beginOfJump
            jr .middleOfJump

            .beginOfJump
                ld a, 11

            .middleOfJump
                inc a  
                cp 20
                jr c, .less
                jr z, .setHasJumped
    
            .less
                ld [PLAYER_VELOCITY+1], a
                jp .endAPressed
            .setHasJumped
                ld [PLAYER_VELOCITY+1], a
                ld a, 1
                ld [HAS_JUMPED], a
        .endAPressed

    ; Check if left button is pressed
    .isLeftPressed
        ld a, [CURRENT_INPUT]
        AND KEY_LEFT
        cp 0
        jr nz, .leftPressed
        jr .isRightPressed

        .leftPressed
            .leftPressedIf
                ; If down is pressed, do nothing
                ld a, [CURRENT_INPUT]
                AND KEY_DOWN
                cp 0
                jr nz, .endLeftPressed
                ; Check to see if B button was pressed
                ld a, [CURRENT_INPUT]
                AND KEY_B
                cp 0
                jr nz, .leftRunning
                jr .leftPressedElse
            
                ; Ramp up speed gradually
                .leftRunning
                    ld a, [PLAYER_VELOCITY]
                    cp 0
                    jr z, .beginingLeftRun
                    cp -6
                    jr z, .endLeftPressed
                    jr nz, .middleLeftRun
                
                    .beginingLeftRun
                        ld a, -2
                        ld [PLAYER_VELOCITY], a
                        jr .endLeftPressed                 

                    .middleLeftRun
                        dec a
                        ld [PLAYER_VELOCITY], a
                        jr .endLeftPressed

            .leftPressedElse
                ld a, -2
                ld [PLAYER_VELOCITY], a     

        .endLeftPressed

    ; Check if right button is pressed
    .isRightPressed
        ld a, [CURRENT_INPUT]
        AND KEY_RIGHT
        cp 0
        jr nz, .rightPressed
        ;jr .isDownPressed
        jp .isNothingPressed

        .rightPressed
            .rightPressedIf
                ; If down is pressed, do nothing
                ld a, [CURRENT_INPUT]
                AND KEY_DOWN
                cp 0
                jr nz, .endRightPressed
                ; Check to see if B button was pressed
                ld a, [CURRENT_INPUT]
                AND KEY_B
                cp 0
                jr nz, .rightRunning
                jr .rightPressedElse
            
                ; Ramp up speed gradually
                .rightRunning
                    ld a, [PLAYER_VELOCITY]
                    cp 0
                    jr z, .beginingRightRun
                    cp 6
                    jr z, .endRightPressed
                    jr nz, .middleRightRun
                
                    .beginingRightRun
                        ld a, 2
                        ld [PLAYER_VELOCITY], a
                        jr .endRightPressed   
                    .middleRightRun
                        inc a
                        ld [PLAYER_VELOCITY], a
                        jr .endRightPressed   
        
            .rightPressedElse
                ld a, 2
                ld [PLAYER_VELOCITY], a     
    
        .endRightPressed
;-----------------------------------------------------------------------------------------------
; This section of the function tries to bring the velocity back down to zero
;-----------------------------------------------------------------------------------------------

    .isNothingPressed 
        ; If down was pressed, do this
        ld a, [CURRENT_INPUT]
        AND KEY_DOWN
        cp 0
        jr nz, .nothingPressed

        ; If left and right were pressed, skip this
        ld a, [CURRENT_INPUT]
        AND %00000011
        cp 0
        jr nz, .endNothingPressed

        ld a, [CURRENT_INPUT]
        AND %11100100
        cp 0
        jr nz, .nothingPressed
        
        .nothingPressed
            ; Figure out in which direction the player is currently going
            ld a, [PLAYER_VELOCITY]
            BIT 7, a
            jr z, .posVel
            jr nz, .negVel
    
            .posVel
                cp 0
                jr nz, .decVel
                jr .endNothingPressed
                
                .decVel
                    dec a
                    ld [PLAYER_VELOCITY], a
                    jr .endNothingPressed

            .negVel
                cp 0
                jr nz, .incVel
                jr .endNothingPressed
                
                .incVel
                    inc a
                    ld [PLAYER_VELOCITY], a

        .endNothingPressed
        ret
;------------------------------------------------------------------------------------------------

; Multiplys two numbers together, input is on a and b. Output is on a.
multiply:
    push bc
    ld c, a
    xor a

    .loop:
        add c
        dec b
        jr nz, .loop
    
    pop bc
    ret

; Detremines wheter the player is moving either towards the right(+x) or to the left(-x) and then loads in the apporates sprites.
displayHorizontal:

    ; First check if player is off the ground, if so return immediately
    ld a, [PLAYER_POSITION+1]
    cp 128
    jr nz ,.ret
    jp .continue
    .ret
        ret    

    .continue
    ; Need to check wheter the player is walking or running        
    ld a, [PLAYER_VELOCITY]
    BIT 7, a
    jr z, .pos
    jr nz, .neg

    .pos
        ld a, [CURRENT_INPUT]
        AND KEY_B
        cp 0
        jp nz, .runningRight
        jp .walkingRight
        
    .neg    
        ld a, [CURRENT_INPUT]
        AND KEY_B
        cp 0
        jp nz, .runningRight
        jp .walkingRight

    ;cp 2
    ;jp z, .walkingRight
    ;cp -2
    ;jp z, .walkingLeft
    ;cp 5
    ;jp z, .runningRight
    ;cp -5
    ;jp z, .runningLeft

    .running

        .runningRight
            ;Check to see if the down dpad is currently pressed
            ld a, [CURRENT_INPUT]
            and KEY_DOWN
            cp 0
            jr nz, .runningRet
            ld b, 0
            ld c, 0
            call updatePlayerPosition
            jr .runningIf

        .runningLeft
            ;Check to see if the down dpad is currently pressed
            ld a, [CURRENT_INPUT]
            and KEY_DOWN
            cp 0
            jr nz, .runningRet
            ld b, 0
            ld c, 1
            call updatePlayerPosition
            jr .runningIf

        .runningRet
            ;ld a, 1
            ret

        .runningIf
            ; See first if player is starting the run from a netural position
            ld a, [ALTERNATING_TILES_RUNNING]
            cp 0
            jr z, .runAlt1
    
            ; Player is already moving
            cp 1
            jr z, .runAlt2
    
            ; Legs of sprite are overlapping
            cp 2
            jr z, .runAlt3
    
            ; Player is already moving
            cp 3
            jp z, .runAlt4
        .endIf

        ; Leaning foward sprite
        .runAlt1
            ; Makes sure that during this animamtion the sprite maintains the same x and y values
            ld a, [SPRITE_FLIP]
            cp 0
            jr z, .runAlt1Inc
            jr nz, .runAlt1Dec

            .runAlt1Inc
                ld c, 1 
                jr .runAlt1Continue

            .runAlt1Dec
                ld c, 0
    
        .runAlt1Continue
            ld b, 0    
            call updatePlayerPosition    
            ld b, $10
            ld h, $1B 
            ld d, $2D
            ld a, [ALTERNATING_TILES_RUNNING]
            inc a
            ld [ALTERNATING_TILES_RUNNING], a    
    
            ; Keep track of where you would be if player decided to run at this moment 
            ld a, [ALTERNATING_TILES]
            inc a
            ld [ALTERNATING_TILES], a
            jp .runningRet


        ; Running sprite, right foot fully extended
        .runAlt2
            ld b, $3C
            ld h, $40
            ld d, $48
            ld a, [ALTERNATING_TILES_RUNNING]
            inc a
            ld [ALTERNATING_TILES_RUNNING], a
    
            ; Keep track of where you would be if player decided to run at this moment 
            ld a, [ALTERNATING_TILES]
            inc a
            ld [ALTERNATING_TILES], a
            jp .runningRet

        ; Running sprite, right and left foot overlapping
        .runAlt3
            ld b, $10
            ld h, $42 
            ld d, $4A
            ld a, [ALTERNATING_TILES_RUNNING+1]
            cp 0
            jr nz, .runAlt3Inc
            jr z, .runAlt3Dec

            .runAlt3Inc
                ld a, [ALTERNATING_TILES_RUNNING]
                dec a
                ld [ALTERNATING_TILES_RUNNING], a
                ld a, [ALTERNATING_TILES_RUNNING+1]
                dec a
                ld [ALTERNATING_TILES_RUNNING+1], a
    
                ; Keep track of where you would be if player decided to run at this moment 
                ld a, [ALTERNATING_TILES]
                dec a
                ld [ALTERNATING_TILES], a
                ld a, [ALTERNATING_TILES+1]
                dec a
                ld [ALTERNATING_TILES+1], a
                jp .runningRet

            .runAlt3Dec
                ld a, [ALTERNATING_TILES_RUNNING]
                inc a
                ld [ALTERNATING_TILES_RUNNING], a
                ld a, [ALTERNATING_TILES_RUNNING+1]
                inc a
                ld [ALTERNATING_TILES_RUNNING+1], a
    
                ; Keep track of where you would be if player decided to run at this moment 
                ld a, [ALTERNATING_TILES]
                inc a
                ld [ALTERNATING_TILES], a
                ld a, [ALTERNATING_TILES+1]
                inc a
                ld [ALTERNATING_TILES+1], a
                jp .runningRet

        ; Running sprite, left foot fully extended
        .runAlt4
            ld b, $3C
            ld h, $44 
            ld d, $4C
            ld a, [ALTERNATING_TILES_RUNNING]
            dec a
            ld [ALTERNATING_TILES_RUNNING], a

            ; Keep track of where you would be if player decided to run at this moment 
            ld a, [ALTERNATING_TILES]
            dec a
            ld [ALTERNATING_TILES], a    
            jp .runningRet
    
    .endRunning

    .walking
        
        .walkingRight
            ;Check to see if the down dpad is currently pressed
            ld a, [CURRENT_INPUT]
            and KEY_DOWN
            cp 0
            jr nz, .walkingRet
            ld b, 0
            ld c, 0
            call updatePlayerPosition
            jr .walkingIf

        .walkingLeft
            ;Check to see if the down dpad is currently pressed
            ld a, [CURRENT_INPUT]
            and KEY_DOWN
            cp 0
            jr nz, .walkingRet
            ld b, 0
            ld c, 1
            call updatePlayerPosition
            jr .walkingIf

        .walkingRet
            ld a, 1
            ret

        .walkingIf 
            ld a, [ALTERNATING_TILES]
            cp 0
            jr z, .walkingAlt1
            cp 1
            jr z, .walkingAlt2
            cp 2
            jr z, .walkingAlt3
            cp 3
            jp z, .walkingAlt4
    
        ; Leaning forward
        .walkingAlt1
            ld a, [SPRITE_FLIP]
            cp 0
            jr z, .walkingAlt1Inc
            jr nz, .walkingAlt1Dec

        .walkingAlt1Inc
            ld c, 1 
            jr .walkingAlt1Continue

        .walkingAlt1Dec
            ld c, 0
    
        .walkingAlt1Continue
            ld b, 0    
            call updatePlayerPosition    
            ld b, $10
            ld h, $1B 
            ld d, $2D
            ld a, [ALTERNATING_TILES]
            inc a
            ld [ALTERNATING_TILES], a    
   
            ; Keep track of where you would be if player decided to run at this moment 
            ld a, [ALTERNATING_TILES_RUNNING]
            inc a
            ld [ALTERNATING_TILES_RUNNING], a
            jp .walkingRet

        ; Right foot fully extended while walking
        .walkingAlt2
            ld b, $12
            ld h, $1D 
            ld d, $2F
            ld a, [ALTERNATING_TILES]
            inc a
            ld [ALTERNATING_TILES], a    
  
            ; Keep track of where you would be if player decided to run at this moment 
            ld a, [ALTERNATING_TILES_RUNNING]
            inc a
            ld [ALTERNATING_TILES_RUNNING], a
            jp .walkingRet

        ; Right and left foot overlaping while walking
        .walkingAlt3
            ld b, $0E
            ld h, $1F 
            ld d, $31
            ld a, [ALTERNATING_TILES+1]
            cp 0
            jr nz, .walkingAlt3Inc
            jr z, .walkingAlt3Dec

            .walkingAlt3Inc
                ld a, [ALTERNATING_TILES]
                dec a
                ld [ALTERNATING_TILES], a
                ld a, 0
                ld [ALTERNATING_TILES+1], a
    
                ; Keep track of where you would be if player decided to run at this moment 
                ld a, [ALTERNATING_TILES_RUNNING]
                dec a
                ld [ALTERNATING_TILES_RUNNING], a
                ld a, [ALTERNATING_TILES_RUNNING+1]
                dec a
                ld [ALTERNATING_TILES_RUNNING+1], a
                jp .walkingRet

            .walkingAlt3Dec
                ld a, [ALTERNATING_TILES] 
                inc a
                ld [ALTERNATING_TILES], a
                ld a, 1
                ld [ALTERNATING_TILES+1], a
    
                ; Keep track of where you would be if player decided to run at this moment 
                ld a, [ALTERNATING_TILES_RUNNING]
                inc a
                ld [ALTERNATING_TILES_RUNNING], a
                ld a, [ALTERNATING_TILES_RUNNING+1]
                inc a
                ld [ALTERNATING_TILES_RUNNING+1], a
                jp .walkingRet
 
        ; Left foot fully extended while walking
        .walkingAlt4
            ld b, $12
            ld h, $21 
            ld d, $33
            ld a, [ALTERNATING_TILES]
            dec a
            ld [ALTERNATING_TILES], a

            ; Keep track of where you would be if player decided to run at this moment 
            ld a, [ALTERNATING_TILES_RUNNING]
            dec a
            ld [ALTERNATING_TILES_RUNNING], a
            jp .walkingRet

    .endWalking

.endDisplayHorizontal

; This function calcuates the player's jump tracjectory based on their current x and y velocity
displayJump:
    
    ; Change the value of the wait variable to a smaller value
    ;ld a, 6
    ;ld [WAIT_VAR], a

    ; Calculate the player's velocity on the y axis
    call calVertVel
    
    ; Check to see if player is moving up or down based on their velocity
    ld b, a                             ; Current velocity
    ld a, [PLAYER_VELOCITY+1]           ; Initial velocity
        
    ; Player can be in one of three sates at this point
    ; State 1 - At standstill (Neither going up or down)
    ; State 2 - Moving up
    ; State 3 - Moving down
    
    ; Their inital and current y velocity is equal to one another and they are off the ground)
    .state1
        ld a, [PLAYER_POSITION+1]
        cp 128
        ld a, [PLAYER_VELOCITY+1]
        jr nz, .state1If
        jr .state2
        .state1If
                
                cp b
                jr z, .moveUp
                jr .state2

    ; Their inital y velocity is greater than their current y velocity
    .state2
        ; If Current velocity is negative, that means the player is falling back down
        BIT 7, a
        jr nz, .state2If
        jr .state2Continue
            .state2If
                jr .moveDown
    .state2Continue
        cp b
        jr nc, .moveUp
        jr .state3
    
    ; Their inital y velocity is less than their current y velocity
    .state3
        cp b
        jr c, .moveDown
    
    .moveUp 
        ; Store the player's current velocity
        ld a, b
        ld [PLAYER_VELOCITY+1], a
        
        ; Calculate the player's horizontal distance
        call calVertDist
       
        ; Now sub the result from calVertDist to the current player y position
        ld b, a
        ld a, [PLAYER_POSITION+1]
        sub b
        
        ; Store the value of the player's new y position
        ld [PLAYER_POSITION+1], a

        ; Calculate players x position
        call calHorDist
        
        ; Now add result onto player's current x position
        ld b, a
        ld a, [PLAYER_POSITION]
        add b
        ld [PLAYER_POSITION], a 

        ; Load in the sprites for the jump animation
        ld b, $3E
        ld h, $46
        ld d, $4E
            
        ; Increment time foward
        ld a, [TIME_SINCE_JUMP]
        inc a
        ld [TIME_SINCE_JUMP], a
         
        ld a, 1
        ret

    .moveDown
        ; Store the player's current velocity
        ld a, b
        ld [PLAYER_VELOCITY+1], a
        
        ; Calculate the player's horizontal distance
        call calVertDist
       
        ; Convert the negative number back into positive using two's complement
        cpl
        ld b, 1
        add b
 
        ; Now add the result from calVertDist to the current player y position
        ld b, a
        ld a, [PLAYER_POSITION+1]
        add b
        
        ; Do a check to see if the result is greater than 128
        ; If so the player has moved past the ground, change the y position back to 128
        cp 128
        jr nc, .onGround
        jr c, .onGround
        jr .continue

        .onGround
            ; Zero out the player's y velocity since they have landed
            xor a
            ld [PLAYER_VELOCITY+1], a

            ; Zero out the time since jump variable
            ld [TIME_SINCE_JUMP], a
        
            ; Change the value of the wait variable back to it's default
            ;ld a, 7
            ;ld [WAIT_VAR], a

            ; Then load 128 in to a to store as the player's new y position
            ld a, 128
        
            ; Store the value of the player's new y position
            ld [PLAYER_POSITION+1], a
   
            ; Calculate players x position
            call calHorDist
        
            ; Now add result onto player's current x position
            ld b, a
            ld a, [PLAYER_POSITION]
            add b
            ld [PLAYER_POSITION], a 

            ; Load in the sprites for the jump aniamtion
            ld b, $3E
            ld h, $46
            ld d, $4E

            ld a, 1
            ret

    .continue
        ; Store the value of the player's new y position
        ld [PLAYER_POSITION+1], a
   
        ; Calculate players x position
        call calHorDist
        
        ; Now add result onto player's current x position
        ld b, a
        ld a, [PLAYER_POSITION]
        add b
        ld [PLAYER_POSITION], a 

        ; Load in the sprites for the jump aniamtion
        ld b, $3E
        ld h, $46
        ld d, $4E

        ; Increment time foward
        ld a, [TIME_SINCE_JUMP]
        inc a
        ld [TIME_SINCE_JUMP], a
 
        ld a, 1
        ret

.endDisplayVertical

; This section is for my projectile motion functions
;------------------------------------------------------------------------------------------------
; Calculates the vertical velocity of the player character
; Output - a: The end result of the calculation
calVertVel:
    ld a, [GRAVITY_STRENGTH]
    ld b, a
    ld a, [TIME_SINCE_JUMP]
    call multiply                       ; g(t)
    ld b, a
    ld a, [PLAYER_VELOCITY+1]
    sub b                       ; y_0 - g(t)
    ret

; Calculates the vertical distance of the player character
; Input - a: Current velocity of the player character
; Output - a: The end result of the calculation
calVertDist:
        ld c, a                         ; Store the current velocity of player in c        
        ld a, [TIME_SINCE_JUMP]
        ld b, a
        call multiply                   ; t^2
        ld b, a                         ; Result of t^2
        ld a, [GRAVITY_STRENGTH]
        call multiply                   ; g(t^2)
        srl a                           ; g(t^2)/2
        ld d, a                         ; Store the result temporialy in d
        ld b, c                         ; Load the cyrrent player velocity back into b
        ld a, [TIME_SINCE_JUMP]
        call multiply                   ; y_0(t)
        sub d                           ; Final result of calulations
        ret
 
; Calculates the horizontal distance of the player character
; Output - a: The end result of the calculation
calHorDist:
    ld a, [PLAYER_VELOCITY]
    ld b, a
    ld a, [TIME_SINCE_JUMP]
    call multiply                       ; x_0(t)
    ret
;------------------------------------------------------------------------------------------------

; Updates the current position(ie, on the x and y axis) of the player character
; B - Flag to determine whether to update the x, y or both x and y axis(0 - for x; 1 - y; 2 - x and y)
; C - Flag to determine whether to increment or decrement on the choosen axis (0 - inc; 1 - dec)
updatePlayerPosition:


    ; If any of the Altering Tiles are at value 0, imediatly return as the position does not change
    ld a, [ALTERNATING_TILES]
    cp 0
    jr z, .ret
    ld a, [ALTERNATING_TILES_RUNNING]
    cp 0
    jr z, .ret
    jr .continue
.ret
    ret    

.continue
    ld a, b
    cp 0
    jr z, .updateX
    cp 1
    jr z, .updateY
    cp 2
    jr z, .updateX_Y

.updateX
    ld a, c
    cp 0
    jr z, .incX
    cp 1
    jr z, .decX

.incX 
    ;ld a, [STRIDE_LENGTH]
    ld a, [PLAYER_VELOCITY]
    ld b, a
    ld a, [PLAYER_POSITION]
    add b
    ld [PLAYER_POSITION], a
    jr .end

.decX
    ;ld a, [STRIDE_LENGTH]
    ld a, [PLAYER_VELOCITY]
    ld b, a
    ld a, [PLAYER_POSITION]
    add b
    ld [PLAYER_POSITION], a
    jr .end

.updateY
    ld a, c
    cp 0
    jr z, .incY
    cp 1
    jr z, .decY

.incY
    ld a, [PLAYER_POSITION+1]
    add 2
    ld [PLAYER_POSITION+1], a
    jr .end

.decY
    ld a, [PLAYER_POSITION+1]
    sub 2
    ld [PLAYER_POSITION+1], a
    jr .end

.updateX_Y
    ld a, c
    cp 0
    jr z, .incX_Y
    cp 1
    jr z, .decX_Y

.incX_Y
    ;ld a, [STRIDE_LENGTH]
    ld a, [PLAYER_VELOCITY]
    ld b, a
    ld a, [PLAYER_POSITION]
    add b
    ld [PLAYER_POSITION], a
    ld a, [PLAYER_POSITION+1]
    add b
    ld [PLAYER_POSITION+1], a
    jr .end

.decX_Y
    ;ld a, [STRIDE_LENGTH]
    ld a, [PLAYER_VELOCITY]
    ld b, a
    ld a, [PLAYER_POSITION]
    sub b
    ld [PLAYER_POSITION], a
    ld a, [PLAYER_POSITION+1]
    sub b
    ld [PLAYER_POSITION+1], a

.end
    ret

; Puts the cpu into an idle and helps with timing the graphics. 
; Otherwise the animation would play out to quickly.
shortWait:
    ld a, [WAIT_VAR]
    ld b, a    
.loop    
   
    ; Save value of b
    push bc
     
    ; If the player has pressed a button during short wait, break out of it
    ld a, [CURRENT_INPUT]
    ld b, a
    call ReadKeys
    cp b
    jr z, .loopContinue
    jp nz, .break

.break
    pop bc
    ld [CURRENT_INPUT], a
    ret
.loopContinue    
    pop bc
    ld a, 1 
    halt
    nop 
    dec b
    ld a, b
    cp 0 
    jr nz, .loop 
    ret 
