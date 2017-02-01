; n queen solver
(define nil '())

(define caddr
  (lambda (lst)
    (car (cddr lst))))

(define append
  (lambda (lst1 lst2)
    (if (null? lst1)
      lst2
      (cons (car lst1)
            (append (cdr lst1) lst2)))))

(define accumulate
  (lambda (op initial sequence)
    (if (null? sequence)
      initial
      (op (car sequence)
          (accumulate op initial (cdr sequence))))))

(define map
  (lambda (proc lst)
    (if (null? lst)
      nil
      (cons (proc (car lst))
            (map proc (cdr lst))))))

(define map2
  (lambda (proc lst1 lst2)
    (if (null? lst1)
      nil
      (if (null? lst2)
        nil
        (cons (proc (car lst1) (car lst2))
              (map2 proc (cdr lst1) (cdr lst2)))))))

(define filter
  (lambda (pred lst)
    (if (null? lst)
      nil
      (if (pred (car lst))
        (cons (car lst) (filter pred (cdr lst)))
        (filter pred (cdr lst))))))

(define flatmap
  (lambda (proc seq)
    (accumulate append nil (map proc seq))))

(define enumerate-interval
  (lambda (low high)
    (if (> low high)
      nil
      (cons low (enumerate-interval (+ low 1) high)))))

(define make-board-from-y
  (lambda (y rest n)
    (if (null? rest)
      nil
      (cons (+ y n) (make-board-from-y (+ y n) (cdr rest) n)))))

(define make-board
  (lambda (board n)
    (if (null? board)
      nil
      (cons nil (make-board-from-y (car board) (cdr board) n)))))

(define make-wrong-board
  (lambda (board)
    (cons (make-board board 1)
          (cons (make-board board 0)
                (cons (make-board board -1) nil)))))

(define compare-board-pair
  (lambda (wrong-board board)
    (if (null? (filter
                 (lambda (b) b)
                 (map2 (lambda (e1 e2)
                         (if (null? e1)
                           #f
                           (= e1 e2)))
                       wrong-board
                       board)))
      #t
      #f)))

(define safe?
  (lambda (k positions)
    ((lambda (wrong-board)
       (if (compare-board-pair (car wrong-board) positions)
         (if (compare-board-pair (cadr wrong-board) positions)
           (compare-board-pair (caddr wrong-board) positions)
           #f)
         #f))
     (make-wrong-board positions))))

(define empty-board nil)

(define adjoin-position
  (lambda (new-row k rest-of-queens)
    (cons new-row rest-of-queens)))

(define queen-cols
  (lambda (k board-size)
    (if (= k 0)
      (cons empty-board nil)
      (filter
        (lambda (positions) (safe? k positions))
        (flatmap
          (lambda (rest-of-queens)
            (map (lambda (new-row)
                   (adjoin-position new-row k rest-of-queens))
                 (enumerate-interval 1 board-size)))
          (queen-cols (- k 1) board-size))))))

(define queens
  (lambda (board-size)
    (queen-cols board-size board-size)))

(print (queens 4))
