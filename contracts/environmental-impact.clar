;; Environmental Impact Contract
;; Measures and tracks environmental impact of green chemistry processes

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-found (err u301))
(define-constant err-unauthorized (err u302))

;; Data structures
(define-map environmental-assessments
  { assessment-id: uint }
  {
    assessor: principal,
    process-id: uint,
    carbon-footprint: uint,
    water-usage: uint,
    waste-generated: uint,
    energy-consumption: uint,
    renewable-energy-percent: uint,
    biodegradability-score: uint,
    toxicity-level: uint,
    assessment-date: uint,
    verified: bool
  }
)

(define-map assessment-counter { id: uint } { count: uint })

;; Initialize counter
(map-set assessment-counter { id: u0 } { count: u0 })

;; Get next assessment ID
(define-private (get-next-assessment-id)
  (let ((current-count (default-to u0 (get count (map-get? assessment-counter { id: u0 })))))
    (map-set assessment-counter { id: u0 } { count: (+ current-count u1) })
    (+ current-count u1)
  )
)

;; Submit environmental assessment
(define-public (submit-assessment
  (process-id uint)
  (carbon-footprint uint)
  (water-usage uint)
  (waste-generated uint)
  (energy-consumption uint)
  (renewable-energy-percent uint)
  (biodegradability-score uint)
  (toxicity-level uint)
)
  (let ((assessment-id (get-next-assessment-id)))
    (map-set environmental-assessments
      { assessment-id: assessment-id }
      {
        assessor: tx-sender,
        process-id: process-id,
        carbon-footprint: carbon-footprint,
        water-usage: water-usage,
        waste-generated: waste-generated,
        energy-consumption: energy-consumption,
        renewable-energy-percent: renewable-energy-percent,
        biodegradability-score: biodegradability-score,
        toxicity-level: toxicity-level,
        assessment-date: block-height,
        verified: false
      }
    )
    (ok assessment-id)
  )
)

;; Verify assessment (owner only)
(define-public (verify-assessment (assessment-id uint))
  (if (is-eq tx-sender contract-owner)
    (match (map-get? environmental-assessments { assessment-id: assessment-id })
      assessment-data
      (begin
        (map-set environmental-assessments
          { assessment-id: assessment-id }
          (merge assessment-data { verified: true })
        )
        (ok true)
      )
      err-not-found
    )
    err-owner-only
  )
)

;; Get assessment details
(define-read-only (get-assessment (assessment-id uint))
  (map-get? environmental-assessments { assessment-id: assessment-id })
)

;; Calculate environmental score
(define-read-only (calculate-environmental-score (assessment-id uint))
  (match (map-get? environmental-assessments { assessment-id: assessment-id })
    assessment-data
    (let (
      (carbon-score (if (< (get carbon-footprint assessment-data) u100) u25 u0))
      (water-score (if (< (get water-usage assessment-data) u1000) u25 u0))
      (waste-score (if (< (get waste-generated assessment-data) u50) u25 u0))
      (renewable-score (if (> (get renewable-energy-percent assessment-data) u50) u25 u0))
    )
      (ok (+ carbon-score water-score waste-score renewable-score))
    )
    err-not-found
  )
)
