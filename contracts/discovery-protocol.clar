;; Discovery Protocol Contract
;; Manages quantum life purpose discovery sessions

(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_SESSION_NOT_FOUND (err u201))
(define-constant ERR_INVALID_STATUS (err u202))
(define-constant ERR_COACH_NOT_VERIFIED (err u203))

;; Session data structure
(define-map discovery-sessions
  { session-id: uint }
  {
    client-id: principal,
    coach-id: principal,
    status: (string-ascii 20),
    session-type: (string-ascii 30),
    quantum-insights: (list 5 (string-ascii 100)),
    purpose-clarity-score: uint,
    created-at: uint,
    completed-at: uint,
    cost: uint
  }
)

;; Session counter
(define-data-var session-counter uint u0)

;; Client session history
(define-map client-sessions
  { client-id: principal }
  { session-ids: (list 50 uint) }
)

;; Create a new discovery session
(define-public (create-discovery-session
  (coach-id principal)
  (session-type (string-ascii 30))
  (cost uint))
  (let (
    (session-id (+ (var-get session-counter) u1))
    (client-id tx-sender)
  )
    ;; Verify coach is verified (would need to call coach-verification contract)
    (var-set session-counter session-id)
    (map-set discovery-sessions
      { session-id: session-id }
      {
        client-id: client-id,
        coach-id: coach-id,
        status: "scheduled",
        session-type: session-type,
        quantum-insights: (list),
        purpose-clarity-score: u0,
        created-at: block-height,
        completed-at: u0,
        cost: cost
      }
    )
    ;; Update client session history
    (match (map-get? client-sessions { client-id: client-id })
      existing-sessions
      (map-set client-sessions
        { client-id: client-id }
        { session-ids: (unwrap! (as-max-len? (append (get session-ids existing-sessions) session-id) u50) (err u999)) }
      )
      (map-set client-sessions
        { client-id: client-id }
        { session-ids: (list session-id) }
      )
    )
    (ok session-id)
  )
)

;; Complete a discovery session
(define-public (complete-session
  (session-id uint)
  (quantum-insights (list 5 (string-ascii 100)))
  (purpose-clarity-score uint))
  (match (map-get? discovery-sessions { session-id: session-id })
    session-data
    (begin
      (asserts! (is-eq tx-sender (get coach-id session-data)) ERR_UNAUTHORIZED)
      (asserts! (is-eq (get status session-data) "in-progress") ERR_INVALID_STATUS)
      (map-set discovery-sessions
        { session-id: session-id }
        (merge session-data {
          status: "completed",
          quantum-insights: quantum-insights,
          purpose-clarity-score: purpose-clarity-score,
          completed-at: block-height
        })
      )
      (ok true)
    )
    ERR_SESSION_NOT_FOUND
  )
)

;; Start a session
(define-public (start-session (session-id uint))
  (match (map-get? discovery-sessions { session-id: session-id })
    session-data
    (begin
      (asserts! (is-eq tx-sender (get coach-id session-data)) ERR_UNAUTHORIZED)
      (asserts! (is-eq (get status session-data) "scheduled") ERR_INVALID_STATUS)
      (map-set discovery-sessions
        { session-id: session-id }
        (merge session-data { status: "in-progress" })
      )
      (ok true)
    )
    ERR_SESSION_NOT_FOUND
  )
)

;; Get session info
(define-read-only (get-session-info (session-id uint))
  (map-get? discovery-sessions { session-id: session-id })
)

;; Get client sessions
(define-read-only (get-client-sessions (client-id principal))
  (map-get? client-sessions { client-id: client-id })
)
