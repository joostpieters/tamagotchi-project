(load "input.scm")
(load "ld-lcd.scm")
(load "buzzer.scm")
(load "tama-fsm-bundler.scm")

(define (tamagotchi-manager)
  (define input (input-mapper))
  (define fsm-bundle (tama-fsm-bundler input))
  (define my-lcd (lcd fsm-bundle))
  (define my-buzz (buzzer GPIO_0 11))
  
  (define (init-input)
    (let ((ctxt (input-context 6))
          (b0-press (input-digital GPIO_0 10))
          (b1-press (input-digital GPIO_0 9))
          (b2-press (input-digital GPIO_0 8))
          (b3-press (input-digital GPIO_0 7))
          (temp-hot (input-analog 'ain0 (lambda (val)
                                      (> val 92))))
          (ldr-dark (input-analog 'ain1 (lambda (val)
                                       (> val 90)))))
      (ctxt 'map b0-press (lambda ()
                             (fsm-bundle 'send-to 'hunger 'feed)))
      (ctxt 'map b1-press (lambda ()
                             (fsm-bundle 'send-to 'mood 'play-a-game)))
      (ctxt 'map b2-press (lambda ()
                             (fsm-bundle 'send-to 'docility 'punish)))
      (ctxt 'map b3-press (lambda ()
                             (fsm-bundle 'send-to 'waste 'clean)))
      (ctxt 'map temp-hot (lambda ()
                             (fsm-bundle 'send-to 'health 'cure)))
      (ctxt 'map ldr-dark (lambda ()
                             (fsm-bundle 'send-to 'sleep 'put-in-bed)))
      (input 'push-context! ctxt)))

  (define (iptloop)
    (define (innerloop)
      (input 'check)
      (if (< (timer.value TIMER1) 2)
          (innerloop)))
    (timer.set-PR TIMER1 59999999)
    (timer.reset-n-start TIMER1)
    (innerloop)
    (timer.stop TIMER1))
    
;;==========================================================
  (define (beep-if-necessary)
    (if (or (fsm-bundle 'send-to 'hunger 'hungry?)
            (fsm-bundle 'send-to 'mood 'unhappy?)
            (fsm-bundle 'send-to 'waste 'disgusting?)
            (fsm-bundle 'send-to 'health 'sick?)
            (fsm-bundle 'send-to 'sleep 'tired?)
            (and (fsm-bundle 'send-to 'docility 'rebels?)
                 (> (rand 'get 0 100) 85)))
        (my-buzz 'beep 1000000)))
;;==========================================================
  (define (transition-all-fsms)
    (fsm-bundle 'transition))
  
  (define (prepare-pins)
    (output-pin (pin 12))
    (output-pin (pin 13))
    (output-pin (pin 14))
    (output-pin (pin 15))
    (output-pin (pin 19))
    (set-pin (pin 19)))
    
  
  (define (mainloop)
    (if (fsm-bundle 'one-dead?)
        (begin
          (display "DEAD")
          (newline))
        (begin
          (display "TRANSITIONING")
          (newline)
          (iptloop)
          (transition-all-fsms)
          (my-lcd 'update)
          (beep-if-necessary)
          (mainloop))))
  (init-input)
  (prepare-pins)
  (mainloop)
  )
