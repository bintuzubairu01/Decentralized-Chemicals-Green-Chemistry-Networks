;; Market Development Contract
;; Facilitates green chemistry market connections and transactions

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u500))
(define-constant err-not-found (err u501))
(define-constant err-unauthorized (err u502))
(define-constant err-insufficient-funds (err u503))

;; Data structures
(define-map market-listings
  { listing-id: uint }
  {
    seller: principal,
    org-id: uint,
    product-name: (string-ascii 100),
    description: (string-ascii 300),
    price: uint,
    quantity: uint,
    green-certification: bool,
    sustainability-score: uint,
    listing-date: uint,
    active: bool
  }
)

(define-map market-transactions
  { transaction-id: uint }
  {
    buyer: principal,
    seller: principal,
    listing-id: uint,
    quantity: uint,
    total-price: uint,
    transaction-date: uint,
    status: (string-ascii 20)
  }
)

(define-map listing-counter { id: uint } { count: uint })
(define-map transaction-counter { id: uint } { count: uint })

;; Initialize counters
(map-set listing-counter { id: u0 } { count: u0 })
(map-set transaction-counter { id: u0 } { count: u0 })

;; Get next listing ID
(define-private (get-next-listing-id)
  (let ((current-count (default-to u0 (get count (map-get? listing-counter { id: u0 })))))
    (map-set listing-counter { id: u0 } { count: (+ current-count u1) })
    (+ current-count u1)
  )
)

;; Get next transaction ID
(define-private (get-next-transaction-id)
  (let ((current-count (default-to u0 (get count (map-get? transaction-counter { id: u0 })))))
    (map-set transaction-counter { id: u0 } { count: (+ current-count u1) })
    (+ current-count u1)
  )
)

;; Create market listing
(define-public (create-listing
  (org-id uint)
  (product-name (string-ascii 100))
  (description (string-ascii 300))
  (price uint)
  (quantity uint)
  (green-certification bool)
  (sustainability-score uint)
)
  (let ((listing-id (get-next-listing-id)))
    (map-set market-listings
      { listing-id: listing-id }
      {
        seller: tx-sender,
        org-id: org-id,
        product-name: product-name,
        description: description,
        price: price,
        quantity: quantity,
        green-certification: green-certification,
        sustainability-score: sustainability-score,
        listing-date: block-height,
        active: true
      }
    )
    (ok listing-id)
  )
)

;; Purchase from listing
(define-public (purchase-product (listing-id uint) (quantity uint))
  (match (map-get? market-listings { listing-id: listing-id })
    listing-data
    (if (and (get active listing-data) (>= (get quantity listing-data) quantity))
      (let (
        (transaction-id (get-next-transaction-id))
        (total-price (* (get price listing-data) quantity))
        (remaining-quantity (- (get quantity listing-data) quantity))
      )
        ;; Update listing quantity
        (map-set market-listings
          { listing-id: listing-id }
          (merge listing-data {
            quantity: remaining-quantity,
            active: (> remaining-quantity u0)
          })
        )
        ;; Record transaction
        (map-set market-transactions
          { transaction-id: transaction-id }
          {
            buyer: tx-sender,
            seller: (get seller listing-data),
            listing-id: listing-id,
            quantity: quantity,
            total-price: total-price,
            transaction-date: block-height,
            status: "completed"
          }
        )
        (ok transaction-id)
      )
      err-insufficient-funds
    )
    err-not-found
  )
)

;; Get listing details
(define-read-only (get-listing (listing-id uint))
  (map-get? market-listings { listing-id: listing-id })
)

;; Get transaction details
(define-read-only (get-transaction (transaction-id uint))
  (map-get? market-transactions { transaction-id: transaction-id })
)

;; Update listing status
(define-public (update-listing-status (listing-id uint) (active bool))
  (match (map-get? market-listings { listing-id: listing-id })
    listing-data
    (if (is-eq tx-sender (get seller listing-data))
      (begin
        (map-set market-listings
          { listing-id: listing-id }
          (merge listing-data { active: active })
        )
        (ok true)
      )
      err-unauthorized
    )
    err-not-found
  )
)
