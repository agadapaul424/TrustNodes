;; TrustNodes: A reputation system built on verified human identities
;; Simplified version with standard syntax

;; Constants
(define-constant ERR-NOT-AUTHORIZED u1)
(define-constant ERR-ALREADY-REGISTERED u2)
(define-constant ERR-NOT-REGISTERED u3)
(define-constant ERR-SELF-ATTESTATION u4)
(define-constant ERR-ATTESTATION-EXISTS u5)
(define-constant ERR-ATTESTATION-NOT-FOUND u6)
(define-constant ERR-INVALID-SCORE u7)

;; Data variables
(define-data-var admin principal tx-sender)
(define-data-var next-identity-id uint u1)
(define-data-var verification-threshold uint u3)

;; Maps
(define-map identities
  principal
  {
    id: uint,
    registration-block: uint,
    verification-score: uint,
    verified: bool,
    attestation-count: uint
  }
)

(define-map attestations
  { attester: principal, attestee: principal }
  {
    score: uint,
    timestamp: uint,
    context: (string-utf8 100),
    valid: bool
  }
)

(define-map domain-reputation
  { identity: principal, domain: (string-ascii 20) }
  {
    score: uint,
    last-updated: uint,
    endorsement-count: uint
  }
)

;; Administrative functions
(define-public (set-admin (new-admin principal))
  (if (is-eq tx-sender (var-get admin))
    (ok (var-set admin new-admin))
    (err ERR-NOT-AUTHORIZED)
  )
)

(define-public (set-verification-threshold (new-threshold uint))
  (if (is-eq tx-sender (var-get admin))
    (ok (var-set verification-threshold new-threshold))
    (err ERR-NOT-AUTHORIZED)
  )
)

;; User registration
(define-public (register-identity)
  (if (is-none (map-get? identities tx-sender))
    (let ((new-id (var-get next-identity-id)))
      (map-set identities tx-sender
        {
          id: new-id,
          registration-block: burn-block-height,
          verification-score: u0,
          verified: false,
          attestation-count: u0
        }
      )
      (var-set next-identity-id (+ new-id u1))
      (ok new-id)
    )
    (err ERR-ALREADY-REGISTERED)
  )
)

;; Attestation functions
(define-public (attest-to-identity 
    (attestee principal) 
    (score uint) 
    (context (string-utf8 100))
  )
  (if (and 
        (is-some (map-get? identities tx-sender))
        (is-some (map-get? identities attestee))
        (not (is-eq tx-sender attestee))
        (is-none (map-get? attestations { attester: tx-sender, attestee: attestee }))
        (and (>= score u1) (<= score u10))
      )
    (let ((attestee-data (unwrap-panic (map-get? identities attestee))))
      (map-set attestations { attester: tx-sender, attestee: attestee }
        {
          score: score,
          timestamp: burn-block-height,
          context: context,
          valid: true
        }
      )
      (map-set identities attestee
        {
          id: (get id attestee-data),
          registration-block: (get registration-block attestee-data),
          verification-score: (+ (get verification-score attestee-data) score),
          attestation-count: (+ (get attestation-count attestee-data) u1),
          verified: (or 
                      (get verified attestee-data) 
                      (>= (+ (get attestation-count attestee-data) u1) (var-get verification-threshold))
                    )
        }
      )
      (ok true)
    )
    (err (if (not (is-some (map-get? identities tx-sender)))
            ERR-NOT-REGISTERED
            (if (not (is-some (map-get? identities attestee)))
              ERR-NOT-REGISTERED
              (if (is-eq tx-sender attestee)
                ERR-SELF-ATTESTATION
                (if (is-some (map-get? attestations { attester: tx-sender, attestee: attestee }))
                  ERR-ATTESTATION-EXISTS
                  ERR-INVALID-SCORE
                )
              )
            )
          )
    )
  )
)

(define-public (update-attestation 
    (attestee principal) 
    (score uint) 
    (context (string-utf8 100))
  )
  (if (and 
        (is-some (map-get? attestations { attester: tx-sender, attestee: attestee }))
        (and (>= score u1) (<= score u10))
      )
    (let ((attestation (unwrap-panic (map-get? attestations { attester: tx-sender, attestee: attestee })))
          (attestee-data (unwrap-panic (map-get? identities attestee)))
          (old-score (get score attestation)))
      (map-set attestations { attester: tx-sender, attestee: attestee }
        {
          score: score,
          timestamp: burn-block-height,
          context: context,
          valid: true
        }
      )
      (map-set identities attestee
        {
          id: (get id attestee-data),
          registration-block: (get registration-block attestee-data),
          verification-score: (+ (- (get verification-score attestee-data) old-score) score),
          attestation-count: (get attestation-count attestee-data),
          verified: (get verified attestee-data)
        }
      )
      (ok true)
    )
    (err (if (not (is-some (map-get? attestations { attester: tx-sender, attestee: attestee })))
            ERR-ATTESTATION-NOT-FOUND
            ERR-INVALID-SCORE
          )
    )
  )
)

;; Domain-specific reputation functions
(define-public (endorse-for-domain 
    (identity principal) 
    (domain (string-ascii 20)) 
    (score uint)
  )
  (if (and
        (is-some (map-get? attestations { attester: tx-sender, attestee: identity }))
        (and (>= score u1) (<= score u10))
      )
    (let ((domain-data (default-to 
                          { score: u0, last-updated: u0, endorsement-count: u0 } 
                          (map-get? domain-reputation { identity: identity, domain: domain }))))
      (map-set domain-reputation { identity: identity, domain: domain }
        {
          score: (+ (get score domain-data) score),
          last-updated: burn-block-height,
          endorsement-count: (+ (get endorsement-count domain-data) u1)
        }
      )
      (ok true)
    )
    (err ERR-ATTESTATION-NOT-FOUND)
  )
)

;; Read-only functions
(define-read-only (get-identity-info (identity principal))
  (map-get? identities identity)
)

(define-read-only (get-attestation (attester principal) (attestee principal))
  (map-get? attestations { attester: attester, attestee: attestee })
)

(define-read-only (get-domain-reputation (identity principal) (domain (string-ascii 20)))
  (map-get? domain-reputation { identity: identity, domain: domain })
)

;; Initialize the contract
(define-private (initialize)
  (begin
    (var-set admin tx-sender)
    (var-set verification-threshold u3)
    true
  )
)

(begin
  (initialize)
)