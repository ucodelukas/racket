(load-relative "loadtest.rktl")
(Section 'places)
(require tests/racket/place-utils)

(place-wait
 (place/splat (p1 ch) (printf "Hello from place\n")))

(let ()
  (define-values (in out) (place-channel))
  (struct ts (a))
  (err/rt-test (place-channel-put in (ts "k")))

  (let ()
    (define us (string->uninterned-symbol "foo"))
    (define us2 (string->uninterned-symbol "foo"))
    (place-channel-put in (cons us us))
    (define r (place-channel-get out))
    (test #t equal? (car r) (cdr r))
    (test (not (place-enabled?)) equal? us (car r))
    (test (not (place-enabled?)) equal? us (cdr r))
    (test #f symbol-interned? (car r))
    (test #f symbol-interned? (cdr r))

    (place-channel-put in (cons us us2))
    (define r2 (place-channel-get out))
    (test #f symbol-interned? (car r2))
    (test #f symbol-interned? (cdr r2))
    (test #f equal? (car r2) (cdr r2))
    (test (not (place-enabled?)) equal? us (car r2))
    (test (not (place-enabled?)) equal? us2 (cdr r2)))

  (let ()
    (define us (string->unreadable-symbol "foo2"))
    (define us2 (string->unreadable-symbol "foo3"))
    (place-channel-put in (cons us us))
    (define r (place-channel-get out))
    (test #t equal? (car r) (cdr r))
    (test #t equal? us (car r))
    (test #t equal? us (cdr r))
    (test #t symbol-unreadable? (car r))
    (test #t symbol-unreadable? (cdr r))
     
    (place-channel-put in (cons us us2))
    (define r2 (place-channel-get out))
    (test #t symbol-unreadable? (car r2))
    (test #t symbol-unreadable? (cdr r2))
    (test #f equal? (car r2) (cdr r2))
    ;interned into the same table as us and us2
    ;because the same place sends and receives
    (test #t equal? us (car r2))
    (test #t equal? us2 (cdr r2))))
  
(let ([p (place/splat (p1 ch)
          (printf "Hello form place 2\n")
          (exit 99))])
  (test #f place? 1)
  (test #f place? void)
  (test #t place? p)
  (test #t place-channel? p)

  (err/rt-test (place-wait 1))
  (err/rt-test (place-wait void))
  (test 99 place-wait p)
  (test 99 place-wait p))

(arity-test dynamic-place 2 2)
(arity-test place-wait 1 1)
(arity-test place-channel 0 0)
(arity-test place-channel-put 2 2)
(arity-test place-channel-get 1 1)
(arity-test place-channel? 1 1)
(arity-test place? 1 1)
(arity-test place-channel-put/get 2 2)
(arity-test processor-count 0 0)

(err/rt-test (dynamic-place "foo.rkt"))
(err/rt-test (dynamic-place null 10))
(err/rt-test (dynamic-place "foo.rkt" 10))
(err/rt-test (dynamic-place '(quote some-module) 'tfunc))

        
(let ([p (place/splat (p1 ch)
          (printf "Hello form place 2\n")
          (sync never-evt))])
  (place-kill p)
  (place-kill p)
  (place-kill p))

(for ([v (list #t #f null 'a #\a 1 1/2 1.0 (expt 2 100) 
               "apple" (make-string 10) #"apple" (make-bytes 10)
               (void) (gensym) (string->uninterned-symbol "apple")
               (string->unreadable-symbol "grape"))])
  (test #t place-message-allowed? v)
  (test #t place-message-allowed? (list v))
  (test #t place-message-allowed? (vector v)))

(for ([v (list (lambda () 10)
               add1)])
  (test (not (place-enabled?)) place-message-allowed? v)
  (test (not (place-enabled?)) place-message-allowed? (list v))
  (test (not (place-enabled?)) place-message-allowed? (cons 1 v))
  (test (not (place-enabled?)) place-message-allowed? (cons v 1))
  (test (not (place-enabled?)) place-message-allowed? (vector v)))

(report-errs)