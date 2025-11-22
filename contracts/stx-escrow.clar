;; stx-escrow.clar
;; A decentralized escrow smart contract for Stacks blockchain
;; Client deposits STX - funds are released to seller or refunded by arbiter decision

(define-constant ERR_NOT_CLIENT u100)
(define-constant ERR_NOT_SELLER u101)
(define-constant ERR_NOT_ARBITER u102)
(define-constant ERR_INVALID_AMOUNT u103)
(define-constant ERR_ALREADY_RELEASED u104)
(define-constant ERR_ALREADY_REFUNDED u105)
(define-constant ERR_NOT_FUNDED u106)

;; -------------------------------------------------
;; Data structures
;; -------------------------------------------------

(define-data-var client principal tx-sender)
(define-data-var seller principal tx-sender)
(define-data-var arbiter principal tx-sender)
(define-data-var amount uint u0)
(define-data-var funded bool false)
(define-data-var released bool false)
(define-data-var refunded bool false)
(define-data-var deadline uint u0)

;; -------------------------------------------------
;; Private helpers
;; -------------------------------------------------

(define-private (only-client)
  (if (is-eq tx-sender (var-get client))
      (ok true)
      (err ERR_NOT_CLIENT))
)

(define-private (only-seller)
  (if (is-eq tx-sender (var-get seller))
      (ok true)
      (err ERR_NOT_SELLER))
)

(define-private (only-arbiter)
  (if (is-eq tx-sender (var-get arbiter))
      (ok true)
      (err ERR_NOT_ARBITER))
)

(define-private (funded?)
  (var-get funded)
)

;; -------------------------------------------------
;; Core functions
;; -------------------------------------------------

;; (1) Initialize escrow details
(define-public (init (buyer principal) (vendor principal) (judge principal) (stx-amount uint) (lock-duration uint))
  (begin
    (asserts! (> stx-amount u0) (err ERR_INVALID_AMOUNT))
    (asserts! (> lock-duration u0) (err ERR_INVALID_AMOUNT))
    (asserts! (not (is-eq buyer vendor)) (err ERR_INVALID_AMOUNT))
    (asserts! (not (is-eq buyer judge)) (err ERR_INVALID_AMOUNT))
    (asserts! (not (is-eq vendor judge)) (err ERR_INVALID_AMOUNT))
    (var-set client buyer)
    (var-set seller vendor)
    (var-set arbiter judge)
    (var-set amount stx-amount)
    (var-set deadline lock-duration)
    (ok "Escrow contract initialized")
  )
)

;; (2) Client deposits funds
(define-public (deposit)
  (begin
    (try! (only-client))
    (if (var-get funded)
        (err ERR_ALREADY_RELEASED)
        (begin
          (var-set funded true)
          (ok "Deposit successful"))))
)

;; (3) Seller confirms delivery and requests payment
(define-public (release)
  (begin
    (try! (only-seller))
    (if (and (var-get funded) (not (var-get released)) (not (var-get refunded)))
        (begin
          (try! (stx-transfer? (var-get amount) tx-sender (var-get seller)))
          (var-set released true)
          (ok "Payment released to seller"))
        (err ERR_ALREADY_RELEASED)))
)

;; (4) Client requests refund before delivery
(define-public (request-refund)
  (begin
    (try! (only-client))
    (if (and (var-get funded) (not (var-get released)))
        (begin
          (try! (stx-transfer? (var-get amount) tx-sender (var-get client)))
          (var-set refunded true)
          (ok "Refund processed"))
        (err ERR_ALREADY_REFUNDED)))
)

;; (5) Arbiter decides refund or release
(define-public (arbiter-decision (decision uint))
  ;; decision: u1 = release to seller, u2 = refund to client
  (begin
    (try! (only-arbiter))
    (if (not (var-get funded))
        (err ERR_NOT_FUNDED)
        (if (and (not (var-get released)) (not (var-get refunded)))
            (begin
              (if (is-eq decision u1)
                  (begin
                    (try! (stx-transfer? (var-get amount) tx-sender (var-get seller)))
                    (var-set released true)
                    (ok "Arbiter released funds to seller"))
                  (begin
                    (try! (stx-transfer? (var-get amount) tx-sender (var-get client)))
                    (var-set refunded true)
                    (ok "Arbiter refunded funds to client"))))
            (err ERR_ALREADY_RELEASED))))
)

;; (6) Auto refund if deadline passed and no release
(define-public (auto-refund)
  (if (and (>= (var-get deadline) u0) (var-get funded) (not (var-get released)))
      (begin
        (try! (stx-transfer? (var-get amount) tx-sender (var-get client)))
        (var-set refunded true)
        (ok "Auto-refund processed"))
      (err ERR_ALREADY_REFUNDED))
)

;; -------------------------------------------------
;; Read-only views
;; -------------------------------------------------

(define-read-only (get-details)
  {
    client: (var-get client),
    seller: (var-get seller),
    arbiter: (var-get arbiter),
    amount: (var-get amount),
    funded: (var-get funded),
    released: (var-get released),
    refunded: (var-get refunded),
    deadline: (var-get deadline)
  }
)

(define-read-only (get-status)
  (if (var-get released)
      "released"
      (if (var-get refunded)
          "refunded"
          (if (var-get funded)
              "funded"
              "unfunded")))
)
