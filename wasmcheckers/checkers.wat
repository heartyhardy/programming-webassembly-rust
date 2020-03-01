(module
    (memory $mem 1)

    ;; Global constants
    (global $BLACK i32 (i32.const 1))
    (global $WHITE i32 (i32.const 2))
    (global $CROWN i32 (i32.const 4))

    ;; player turns
    (global $CURRENT_TURN (mut i32) (i32.const 0))

    ;; Index for given position (x, y) = (x + y * 8)
    (func $indexForPosition (param $x i32) (param $y i32) (result i32)
        (i32.add
            (i32.mul
                (i32.const 8)
                (get_local $y)
            )
            (get_local $x)
        )
    )

    ;; Offset for given position is (x+y*8) * bytes per unit, in this case 4
    (func $offsetForPosition (param $x i32) (param $y i32) (result i32)
        (i32.mul
            (call $indexForPosition (get_local $x) (get_local $y))
            (i32.const 4)
        )
    )

    ;; Chckes if the given piece is Crowned or not
    (func $isCrowned (param $piece i32) (result i32)
        (i32.eq
            (i32.and (get_local $piece) (get_global $CROWN))
            (get_global $CROWN)
        )
    )

    ;; Checks if the given piece is Black
    (func $isBlack (param $piece i32) (result i32)
        (i32.eq
            (i32.and (get_local $piece) (get_global $BLACK))
            (get_global $BLACK)
        )    
    )

    ;; Checks if the given piece is White
    (func $isWhite (param $piece i32) (result i32)
        (i32.eq
            (i32.and (get_local $piece) (get_global $WHITE))
            (get_global $WHITE)
        )    
    )

    ;; Adds a crown to the given piece
    (func $withCrown (param $piece i32) (result i32)
        (i32.or (get_local $piece) (get_global $CROWN))
    )

    ;; Removes a crown by only extracting Black and White bits
    (func $withoutCrown (param $piece i32) (result i32)
        (i32.and (get_local $piece) (i32.const 3))
    )

    ;; Sets a given piece on the gameboard
    (func $setPiece (param $x i32) (param $y i32) (param $piece i32)
        (i32.store
            (call $offsetForPosition
                (get_local $x)
                (get_local $y)
            )
            (get_local $piece)
        )
    )

    ;; Gets a piece from given x,y if it exsits or unreachable
    (func $getPiece (param $x i32) (param $y i32) (result i32)
        (if (result i32)
            (block (result i32)
                (i32.and
                    (call $inRange
                        (i32.const 0)
                        (i32.const 7)
                        (get_local $x)
                    )
                    (call $inRange
                        (i32.const 0)
                        (i32.const 7)
                        (get_local $y)                    
                    )
                )            
            )
        (then
            (i32.load
               (call $offsetForPosition
                (get_local $x)
                (get_local $y)) 
            )
        )
        (else
            (unreachable)
        )       
        )
    )        

    ;; Checks if the given number is within the range
    (func $inRange (param $low i32) (param $high i32) (param $value i32) (result i32)
        (i32.and
            (i32.ge_s (get_local $value) (get_local $low))
            (i32.le_s (get_local $value) (get_local $high))
        )
    )

    ;; Gets the current turn
    (func $getTurnOwner (result i32)
        (get_global $CURRENT_TURN)
    )

    ;; Set current turn
    (func $setTurnOwner (param $piece i32)
        (set_global $CURRENT_TURN (get_local $piece))
    )

    ;; Toggles the turn owner
    (func $toggleTurnOwner
        (if (i32.eq (call $getTurnOwner) (i32.const 1))
            (then (call $setTurnOwner (i32.const 2)))
            (else (call $setTurnOwner (i32.const 1)))            
        )
    )

    ;; Checks if the current turn belongs to the human player
    (func $isPlayerTurn (param $player i32) (result i32)
        (i32.ge_s
            (i32.and (get_local $player) (call $getTurnOwner))
            (i32.const 0)
        )   
    )

    (export "indexForPosition" (func $indexForPosition))
    (export "offsetForPosition" (func $offsetForPosition))
    (export "isCrowned" (func $isCrowned))
    (export "isBlack" (func $isBlack))
    (export "isWhite" (func $isWhite))
    (export "withCrown" (func $withCrown))
    (export "withoutCrown" (func $withoutCrown))
)