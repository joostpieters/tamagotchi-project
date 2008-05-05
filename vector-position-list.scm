; ADT double-linked-position-list< T >
;=======================================
; Specification:
;---------------------------------------
; vector-position-list: ( ( T T -> boolean ) . list< T > -> vector-position-list< T > )
; length: ( -> number )
; full?: ( -> boolean )
; empty?: ( -> boolean )
; map: ( ( T -> T ) ( T T -> boolean ) -> vector-position-list< T > )
; map!: ( ( T -> T ) ( T T -> boolean ) -> {#t} )
; foldl: ( ( T T -> T ) T -> T )
; foldr: ( ( T T -> T ) T -> T )
; first-position: ( -> vector-position< T > )
; last-position: ( -> vector-position< T > )
; find: ( T -> vector-position< T > )
; delete!: ( vector-position< T > -> #<void> )
; add-before!: ( T . vector-position< T > -> #<void> )
; add-after!: ( T . vector-position< T > -> #<void> )
; next: ( vector-position< T > -> vector-position< T > )
; prev: ( vector-position< T > -> vector-position< T > )
; has-prev?: ( vector-position< T > -> boolean )
; has-next?: ( vector-position< T > -> boolean )
; value: ( vector-position< T > -> T )
; print: ( -> #<void> )
; (): ( -> vector-position< T > )


(load "global.ss")


(define (vector-position-list size ==? . lst) ;lst is used if creating from scheme list
  (define vect (make-vector size))
  (define ptr 0)
  
  (define (checkpos pos)
    (if (or (< pos 0)
            (>= pos ptr)) ; Also incorporates empty check
        (error vector-position-list.checkpos "invalid position")))
  
  (define (storage-move-left src len dest)
    (if (> len 0)
        (begin
          (vector-set! vect dest (vector-ref vect src))
          (storage-move-left (+ src 1) (- len 1) (+ dest 1)))))
  
  (define (storage-move-right src len dest)
    (define (iter ilen)
      (if (>= ilen 0)
          (begin
            (vector-set! vect (+ ilen dest) (vector-ref vect (+ ilen src)))
            (iter (- ilen 1)))))
    (iter (- len 1)))

  ; Public functions
  
  (define (getnext pos)
    (checkpos pos)

    (if (= pos (- ptr 1))
        (error vector-position-list.getnext "position has no next")
        (+ pos 1)))
  
  (define (getprev pos)
    (checkpos pos)

    (if (= pos 0)
        (error vector-position-list.getprev "position has no previous")
        (- pos 1)))
  
  (define (getval pos)
    (checkpos pos)

    (vector-ref vect pos))
  
  (define (gethas-next? pos)
    (checkpos pos)

    (not (= pos (- ptr 1))))
  
  (define (gethas-prev? pos)
    (checkpos pos)

    (not (= pos 0)))
  
  (define (update! pos val)
    (checkpos pos)

    (vector-set! vect pos val))

  (define (from-scheme-list lst)
    (if (not (null? lst))
        (begin (add-after! (car lst))
               (from-scheme-list (cdr lst)))))
  (define (length)
    ptr)
  (define (full?)
    (= (length) size))
  (define (empty?)
    (= (length) 0))
  (define (map func new==?)
    (let ((res (vector-position-list size new==?)))
      (define (iter thispos)
        (res 'add-after! (func (getval thispos)))
        (if (gethas-next? thispos)
            (iter (getnext thispos))))
      (if (not (empty?))
          (iter (first-position)))
      res))
  (define (map! func new==?)
    (define (iter thispos)
      (update! thispos (func (getval thispos)))
      (if (gethas-next? thispos)
          (iter (getnext thispos))))
    (set! ==? new==?)
    (if (not (empty?))
        (iter (first-position)))
    #t)
  (define (foldl comb zero)
    (define (iter thispos res)
      (if (gethas-next? thispos)
          (iter (getnext thispos) (comb res (getval thispos)))
          (comb res (getval thispos))))
    (if (empty?)
        zero
        (iter (first-position) zero)))
  (define (foldr comb zero)
    (define (iter thispos res)
      (if (gethas-next? thispos)
          (iter (getprev thispos) (comb res (getval thispos)))
          (comb res (getval thispos))))
    (if (empty?)
        zero
        (iter (last-position) zero)))
  (define (first-position)
    (if (empty?)
        (error 'vector-position-list "first position requested, but list is empty!")
        0))
  
  (define (last-position)
    (if (empty?)
        (error 'vector-position-list "last position requested, but list is empty!")
        (- ptr 1)))
  
  (define (find value)
    (define (iter pos)
      (cond ((==? (getval pos) value) pos)
            ((gethas-next? pos) (iter (getnext pos)))
            (else #f)))
    (if (empty?)
        #f
        (iter (first-position))))
  
  (define (find-eq value)
    (define (iter pos)
      (cond ((eq? (getval pos) value) pos)
            ((gethas-next? pos) (iter (getnext pos)))
            (else #f)))
    (if (empty?)
        #f
        (iter (first-position))))
  
  (define (delete! pos)
    (checkpos pos)
    (let ((behind (+ pos 1)))
      (storage-move-left behind (- (length) behind) pos)))
  
  (define (add-before! val . pos)
    (let ((realpos (if (null? pos)
                       (first-position)
                       (car pos))))
      (if (full?)
          (error vector-position-list.add-before! "list is full")
          (begin
            (storage-move-right realpos (- (length) realpos) (+ realpos 1))
            (vector-set! vect realpos val)))))
  
  (define (add-after! val . pos)
    (let* ((realpos (if (null? pos)
                        (last-position)

                        (car pos)))
           (behind (+ realpos 1)))
      (if (full?)
          (error vector-position-list.add-before! "list is full")
          (begin
            (storage-move-right behind (- (length) behind) (+ behind 1))
            (vector-set! vect behind val)))))
  
  (define (duplicate)
    (define (iter lst pos)
      (lst 'add-after! (getval pos))
      (if (gethas-next? pos)
          (iter lst (getnext pos))
          lst))
    (if (empty?)
        (vector-position-list ==?)
        (iter (vector-position-list ==?) (first-position))))
  
  (define (debug-print-complete)
    (define (iter pos)
      (display (getval pos))
      (display " ")
      (if (gethas-next? pos)
          (iter (getnext pos))))
    (cond ((empty?) (display "()")
                         (newline))
          (else (display "(")
                (iter (first-position))
                (display ")"))))
  
  (define (to-scheme-list)
    (define (rec pos)
      (if (gethas-next? pos)
          (cons (getval pos) (rec (getnext pos)))
          (cons (getval pos) '())))
    (if (empty?)
        '()
        (rec (first-position))))
  
  (unless (null? lst)
    (from-scheme-list (car lst)))
  
  (define (vector-position-list-object . msg)
    (if (null? msg)
        (first-position)
        (case (car msg)
          ('length (length))
          ('full? (full?))
          ('empty? (empty?))
          ('map (map (GetParam msg 0) (GetParam msg 1)))
          ('map! (map! (GetParam msg 0) (GetParam msg 1)))
          ('foldl (foldl (GetParam msg 0) (GetParam msg 1)))
          ('foldr (foldr (GetParam msg 0) (GetParam msg 1)))
          ('first-position (first-position))
          ('last-position (last-position))
          ('find (find (GetParam msg 0)))
          ('find-eq (find-eq (GetParam msg 0)))
          ('delete! (delete! (GetParam msg 0)))
          ('add-before! (apply add-before! (GetParam msg 0) (cddr msg)))
          ('add-after! (apply add-after! (GetParam msg 0) (cddr msg)))
          ('next (getnext (GetParam msg 0)))
          ('prev (getprev (GetParam msg 0)))
          ('value (getval (GetParam msg 0)))
          ('update! (update! (GetParam msg 0) (GetParam msg 1)))
          ('has-next? (gethas-next? (GetParam msg 0)))
          ('has-prev? (gethas-prev? (GetParam msg 0)))
          ('print (debug-print-complete))
          ('duplicate (duplicate))
          ('to-scheme-list (to-scheme-list))
          (else (error 'vector-position-list "message not understood: ~S" (car msg))))))
  vector-position-list-object)


; Makes the type of position list selectable by load
(define position-list vector-position-list)