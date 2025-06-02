;; Ingredient Sourcing Contract
;; Tracks molecular gastronomy ingredients

(define-constant err-not-found (err u301))
(define-constant err-unauthorized (err u302))
(define-constant err-invalid-status (err u303))

;; Ingredient batch data
(define-map ingredient-batches
  { batch-id: uint }
  {
    supplier: principal,
    ingredient-name: (string-ascii 50),
    molecular-grade: (string-ascii 20),
    origin: (string-ascii 100),
    harvest-date: uint,
    expiry-date: uint,
    quantity: uint,
    status: (string-ascii 20),
    temperature-controlled: bool
  }
)

;; Supply chain tracking
(define-map supply-chain
  { batch-id: uint, step: uint }
  {
    handler: principal,
    location: (string-ascii 100),
    timestamp: uint,
    temperature: int,
    notes: (string-ascii 200)
  }
)

;; Batch counter
(define-data-var batch-counter uint u0)

;; Register ingredient batch
(define-public (register-batch
  (ingredient-name (string-ascii 50))
  (molecular-grade (string-ascii 20))
  (origin (string-ascii 100))
  (harvest-date uint)
  (expiry-date uint)
  (quantity uint)
  (temperature-controlled bool)
)
  (let ((batch-id (+ (var-get batch-counter) u1)))
    (map-set ingredient-batches
      { batch-id: batch-id }
      {
        supplier: tx-sender,
        ingredient-name: ingredient-name,
        molecular-grade: molecular-grade,
        origin: origin,
        harvest-date: harvest-date,
        expiry-date: expiry-date,
        quantity: quantity,
        status: "registered",
        temperature-controlled: temperature-controlled
      }
    )
    (var-set batch-counter batch-id)
    (ok batch-id)
  )
)

;; Update batch status
(define-public (update-batch-status (batch-id uint) (new-status (string-ascii 20)))
  (let ((batch (unwrap! (map-get? ingredient-batches { batch-id: batch-id }) err-not-found)))
    (asserts! (is-eq (get supplier batch) tx-sender) err-unauthorized)
    (map-set ingredient-batches
      { batch-id: batch-id }
      (merge batch { status: new-status })
    )
    (ok true)
  )
)

;; Add supply chain step
(define-public (add-supply-step
  (batch-id uint)
  (step uint)
  (location (string-ascii 100))
  (temperature int)
  (notes (string-ascii 200))
)
  (begin
    (map-set supply-chain
      { batch-id: batch-id, step: step }
      {
        handler: tx-sender,
        location: location,
        timestamp: block-height,
        temperature: temperature,
        notes: notes
      }
    )
    (ok true)
  )
)

;; Get batch info
(define-read-only (get-batch (batch-id uint))
  (map-get? ingredient-batches { batch-id: batch-id })
)

;; Get supply chain step
(define-read-only (get-supply-step (batch-id uint) (step uint))
  (map-get? supply-chain { batch-id: batch-id, step: step })
)

;; Check if batch is fresh
(define-read-only (is-batch-fresh (batch-id uint))
  (match (map-get? ingredient-batches { batch-id: batch-id })
    batch (< block-height (get expiry-date batch))
    false
  )
)
