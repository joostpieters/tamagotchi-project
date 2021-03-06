; sleep-fsm.scm
; Desc: Defines the object sleep-fsm.
;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

(load "fsm.scm")
(load "need-level.scm")

;***************************************************
; Object sleep-fsm
; Constructor spec: (  -> sleep-fsm )
; Desc: FSM specification to sleep
; Args: /
;***************************************************

(define (sleep-fsm external)
  (define tiredness-level (need-level))
  (define put-in-bed #f)
  (define cycles-to-go SLEEP_TIME)
  
  ;===================================================
  ; Method sleep
  ; Spec: (  -> { #<void> } )
  ; Desc: set put-in-bed to #f and calls lower-tiredness-level!
  ; Args: /
  ;===================================================
  (define (sleep)
    (tiredness-level 'lower-a-bit!)
    (set! cycles-to-go (- cycles-to-go 1))
    (set! put-in-bed #f))

  ;===================================================
  ; Method dont-sleep
  ; Spec: (  -> { #<void> } )
  ; Desc: set put-in-bed to #f and calls lower-tiredness-level!
  ; Args: /
  ;===================================================
  (define (dont-sleep)
    (set! put-in-bed #f))

  ;===================================================
  ; Method rebels?
  ; Spec: (  -> { #<void> } )
  ; Desc: does external call to see if the animal rebels.
  ; Args: /
  ;===================================================
  (define (rebels?)
    (external 'docility 'rebels?))

  ;===================================================
  ; Method true-condition?
  ; Spec: (  -> { #<void> } )
  ; Desc: always returns true
  ; Args: /
  ;===================================================
  (define (true-condition?)
    #t)

  ;===================================================
  ; Method init-transitions
  ; Spec: (  -> { #<void> } )
  ; Desc: adds transitions to all states (must be called after the states are created)
  ; Args: /
  ;===================================================
  (define (init-transitions)
    (state-awake 'add-transition! (fsm-transition (lambda () (tiredness-level 'high?)) state-tired))
    (state-awake 'add-transition! (fsm-transition (lambda () (and put-in-bed (not (rebels?)))) state-asleep (lambda () (set! cycles-to-go SLEEP_TIME))))
    (state-awake 'add-transition! (fsm-transition (lambda () (and put-in-bed (rebels?))) state-refused))
    (state-awake 'add-transition! (fsm-transition true-condition? state-awake))
    ;;---
    (state-tired 'add-transition! (fsm-transition (lambda () (and put-in-bed (not (rebels?)))) state-asleep (lambda () (set! cycles-to-go SLEEP_TIME))))
    (state-tired 'add-transition! (fsm-transition (lambda () (and put-in-bed (rebels?))) state-refused))
    (state-tired 'add-transition! (fsm-transition (lambda () (tiredness-level 'low?)) state-awake))
    (state-tired 'add-transition! (fsm-transition (lambda () (tiredness-level 'deadly?)) state-dead))
    (state-tired 'add-transition! (fsm-transition true-condition? state-tired))
    ;;---
    (state-asleep 'add-transition! (fsm-transition (lambda () (> cycles-to-go 0)) state-asleep))
    (state-asleep 'add-transition! (fsm-transition (lambda () (tiredness-level 'low?)) state-awake))
    (state-asleep 'add-transition! (fsm-transition (lambda () (tiredness-level 'high?)) state-tired))
    ;;---
    (state-refused 'add-transition! (fsm-transition (lambda () (tiredness-level 'low?)) state-awake))
    (state-refused 'add-transition! (fsm-transition (lambda () (tiredness-level 'high?)) state-tired)))


  (define state-awake (fsm-state (lambda () (tiredness-level 'raise!)) '() 4))
  (define state-tired (fsm-state (lambda () (tiredness-level 'raise!)) '() 5))
  (define state-asleep (fsm-state sleep '() 3))
  (define state-refused (fsm-state dont-sleep '() 2))
  (define state-dead (fsm-state '() '() 0))
  
  (define my-fsm (fsm state-awake))
  
  (define (sleep-fsm-object msg . args)
    (let ((my-param (make-param args 'sleep-fsm-object)))
      (case msg
        ('tired? (eq? (my-fsm 'get-current-state) state-tired))
        ('awake? (eq? (my-fsm 'get-current-state) state-awake))
        ('asleep? (eq? (my-fsm 'get-current-state) state-asleep))
        ('refused? (eq? (my-fsm 'get-current-state) state-refused))
        ('dead? (eq? (my-fsm 'get-current-state) state-dead))
        ('put-in-bed (set! put-in-bed #t))
        ('wake (set! cycles-to-go 0))
        ('level tiredness-level)
        (else (apply my-fsm msg args)))))
  
  (init-transitions)
  
  sleep-fsm-object)
