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

    ;; Checks if this piece should be crowned
    (func $shouldCrown (param $pieceY i32) (param $piece i32) (result i32)
        (i32.or
            (i32.and
                (i32.eq
                    (get_local $pieceY)
                    (i32.const 0)
                )
                (call $isBlack (get_local $piece))
            )
            (i32.and
                (i32.eq
                    (get_local $pieceY)
                    (i32.const 7)
                )
                (call $isWhite (get_local $piece))
            )
        )
    )

    ;; Make the given piece a crowned piece
    (func $crownPiece (param $x i32) (param $y i32)
        (local $piece i32)
        (set_local $piece (call $getPiece (get_local $x) (get_local $y)))

        (call $setPiece (get_local $x) (get_local $y)
            (call $withCrown (get_local $piece)))

        (call $notify_piececrowned (get_local $x)(get_local $y))
    )

    ;; Get distance
    (func $distance (param $x i32) (param $y i32) (result i32)
        (i32.sub (get_local $x) (get_local $y))
    )

    ;; Checks if the given move is a valid move
    (func $isValidMove (param $x i32) (param $y i32) (param $toX i32) (param $toY i32) (result i32)
        (local $player i32)
        (local $target i32)

        (set_local $player (call $getPiece (get_local $x) (get_local $y)))
        (set_local $target (call $getPiece (get_local $toX) (get_local $toY)))

        (if (result i32)
            (block (result i32)
                (i32.and
                    (call $isValidJumpDistance (get_local $y) (get_local $toY))
                    (i32.and
                        (call $isPlayerTurn (get_local $player))
                        (i32.eq (get_local $target) (i32.const 0))
                    )
                )            
            )
            (then
                (i32.const 1)
            )
            (else 
                (i32.const 0)
            )       
        )
    )


    ;; Checks if the jump distance is valid
    (func $isValidJumpDistance (param $from i32) (param $to i32) (result i32)
        (local $d i32)
        (set_local $d
            (if (result i32)
                (i32.ge_s (get_local $to) (get_local $from))
                (then
                    (call $distance (get_local $from) (get_local $to))
                )
                (else 
                    (call $distance (get_local $to) (get_local $from))
                )
            )
        )
        (i32.le_u
            (get_local $d)
            (i32.const 2)
        )
    )

    ;; Exported move function to be called by the game host
    (func $move (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)
        (if (result i32)
        (block (result i32)
            (call $isValidMove (get_local $fromX) (get_local $fromY)
            (get_local $toX) (get_local $toY))
            )
        (then
            (call $do_move (get_local $fromX) (get_local $fromY)
            (get_local $toX) (get_local $toY))
        )
        (else
            (i32.const 0)
        )
        )
    )

;; Internal move function, performs actual move post-validation of target.
;; Currently not handled:
;;- removing opponent piece during a jump
;;- detecting win condition
    (func $do_move (param $fromX i32) (param $fromY i32) (param $toX i32) (param $toY i32) (result i32)
        (local $curpiece i32)
        (set_local $curpiece (call $getPiece (get_local $fromX)(get_local $fromY)))
        (call $toggleTurnOwner)
        (call $setPiece (get_local $toX) (get_local $toY) (get_local $curpiece))
        (call $setPiece (get_local $fromX) (get_local $fromY) (i32.const 0))
        
        (if (call $shouldCrown (get_local $toY) (get_local $curpiece))
        (then (call $crownPiece (get_local $toX) (get_local $toY))))
        (call $notify_piecemoved (get_local $fromX) (get_local $fromY)
        (get_local $toX) (get_local $toY))
        (i32.const 1)
    )

    (export "indexForPosition" (func $indexForPosition))
    (export "offsetForPosition" (func $offsetForPosition))
    (export "isCrowned" (func $isCrowned))
    (export "isBlack" (func $isBlack))
    (export "isWhite" (func $isWhite))
    (export "withCrown" (func $withCrown))
    (export "withoutCrown" (func $withoutCrown))
)