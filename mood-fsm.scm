; mood-fsm.scm
; Desc: Defines the object mood-fsm.
;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

(load "fsm.scm")
(load "need-level.scm")
(load "simple-game.scm")

;***************************************************
; Object mood-fsm
; Constructor spec: (  -> honger-fsm )
; Desc: FSM specification for mood
; Args: /
;***************************************************

(define (mood-fsm external input)
  (define unhappiness-level (need-level))
  (define play-game #f)
  (define game (simple-game input
                            (lambda ()
                              (unhappiness-level 'lower!)
                              (display "Yay!"))
                            (lambda ()
                              (display "Aww =("))))
    
  ;===================================================
  ; Method true-condition?
  ; Spec: (  -> { #<void> } )
  ; Desc: always returns true
  ; Args: /
  ;===================================================
  (define (true-condition?)
    #t)
  
  ;===================================================
  ; Method play-a-game
  ; Spec: (  -> { #<void> } )
  ; Desc: starts a game
  ; Args: /
  ;===================================================
  (define (play-a-game)
    (game 'start)
    (set! play-game #f))
  
  ;===================================================
  ; Method reject-a-game
  ; Spec: (  -> { #<void> } )
  ; Desc: resets play-game
  ; Args: /
  ;===================================================
  (define (reject-a-game)
    (set! play-game #f))
  
  ;===================================================
  ; Method rebels?
  ; Spec: (  -> { #<void> } )
  ; Desc: does external call to see if the animal rebels.
  ; Args: /
  ;===================================================
  (define (rebels?)
    (external 'docility 'rebels?))

  ;===================================================
  ; Method init-transitions
  ; Spec: (  -> { #<void> } )
  ; Desc: adds transitions to all states (must be called after the states are created)
  ; Args: /
  ;===================================================
  (define (init-transitions)
    (state-happy 'add-transition! (fsm-transition (lambda () (unhappiness-level 'high?)) state-unhappy))
    (state-happy 'add-transition! (fsm-transition (lambda () (and play-game (not (rebels?)))) state-playing-game))
    (state-happy 'add-transition! (fsm-transition (lambda () (and play-game (rebels?))) state-refused))
    (state-happy 'add-transition! (fsm-transition true-condition? state-happy))
    ;;---
    (state-unhappy 'add-transition! (fsm-transition (lambda () (and play-game (not (rebels?)))) state-playing-game))
    (state-unhappy 'add-transition! (fsm-transition (lambda () (and play-game (rebels?))) state-refused))
    (state-unhappy 'add-transition! (fsm-transition (lambda () (unhappiness-level 'low?)) state-happy))
    (state-unhappy 'add-transition! (fsm-transition (lambda () (unhappiness-level 'deadly?)) state-dead))
    (state-unhappy 'add-transition! (fsm-transition true-condition? state-unhappy))
    ;;---
    (state-playing-game 'add-transition! (fsm-transition (lambda () (unhappiness-level 'low?)) state-happy))
    (state-playing-game 'add-transition! (fsm-transition (lambda () (unhappiness-level 'high?)) state-unhappy))
    ;;---
    (state-refused 'add-transition! (fsm-transition (lambda () (unhappiness-level 'low?)) state-happy))
    (state-refused 'add-transition! (fsm-transition (lambda () (unhappiness-level 'high?)) state-unhappy)))

  (define state-happy (fsm-state (lambda () (unhappiness-level 'raise!)) '() 4))
  (define state-unhappy (fsm-state (lambda () (unhappiness-level 'raise!)) '() 5))
  (define state-playing-game (fsm-state play-a-game '() 2))
  (define state-refused (fsm-state reject-a-game '() 2))
  (define state-dead (fsm-state '() '() 0))
  
  (define my-fsm (fsm state-happy))
  
  (define (mood-fsm-object msg . args)
    (let ((my-param (make-param args 'mood-fsm-object)))
      (case msg
        ('unhappy? (eq? (my-fsm 'get-current-state) state-unhappy))
        ('happy? (eq? (my-fsm 'get-current-state) state-happy))
        ('playing-game? (eq? (my-fsm 'get-current-state) state-playing-game))
        ('refused? (eq? (my-fsm 'get-current-state) state-refused))
        ('dead? (eq? (my-fsm 'get-current-state) state-dead))
        ('play-a-game (set! play-game #t))
        ('level unhappiness-level)
        (else (apply my-fsm msg args)))))

  (init-transitions)

  mood-fsm-object)
