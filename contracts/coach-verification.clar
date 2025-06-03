;; Coach Verification Contract
;; Manages verification and registration of quantum life purpose coaches

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Coach data structure
(define-map coaches
  { coach-id: principal }
  {
    verified: bool,
    specialization: (string-ascii 50),
    experience-years: uint,
    certification-level: uint,
    rating: uint,
    total-sessions: uint,
    registration-block: uint
  }
)

;; Coach verification status
(define-map verification-requests
  { coach-id: principal }
  {
    status: (string-ascii 20),
    submitted-at: uint,
    reviewed-at: uint
  }
)

;; Register as a coach
(define-public (register-coach (specialization (string-ascii 50)) (experience-years uint) (certification-level uint))
  (let ((coach-id tx-sender))
    (asserts! (is-none (map-get? coaches { coach-id: coach-id })) ERR_ALREADY_VERIFIED)
    (map-set coaches
      { coach-id: coach-id }
      {
        verified: false,
        specialization: specialization,
        experience-years: experience-years,
        certification-level: certification-level,
        rating: u0,
        total-sessions: u0,
        registration-block: block-height
      }
    )
    (map-set verification-requests
      { coach-id: coach-id }
      {
        status: "pending",
        submitted-at: block-height,
        reviewed-at: u0
      }
    )
    (ok true)
  )
)

;; Verify a coach (admin only)
(define-public (verify-coach (coach-id principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? coaches { coach-id: coach-id })
      coach-data
      (begin
        (map-set coaches
          { coach-id: coach-id }
          (merge coach-data { verified: true })
        )
        (map-set verification-requests
          { coach-id: coach-id }
          {
            status: "approved",
            submitted-at: (default-to u0 (get submitted-at (map-get? verification-requests { coach-id: coach-id }))),
            reviewed-at: block-height
          }
        )
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

;; Get coach info
(define-read-only (get-coach-info (coach-id principal))
  (map-get? coaches { coach-id: coach-id })
)

;; Check if coach is verified
(define-read-only (is-coach-verified (coach-id principal))
  (match (map-get? coaches { coach-id: coach-id })
    coach-data (get verified coach-data)
    false
  )
)

;; Update coach rating
(define-public (update-coach-rating (coach-id principal) (new-rating uint))
  (match (map-get? coaches { coach-id: coach-id })
    coach-data
    (begin
      (map-set coaches
        { coach-id: coach-id }
        (merge coach-data { rating: new-rating })
      )
      (ok true)
    )
    ERR_NOT_FOUND
  )
)
