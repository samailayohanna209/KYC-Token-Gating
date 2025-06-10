(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_KYC_VERIFIED (err u101))
(define-constant ERR_PASS_ALREADY_USED (err u102))
(define-constant ERR_PASS_NOT_FOUND (err u103))
(define-constant ERR_INSUFFICIENT_BALANCE (err u104))
(define-constant ERR_PASS_EXPIRED (err u105))
(define-constant ERR_ALREADY_KYC_VERIFIED (err u106))

(define-map kyc-verified-users principal bool)
(define-map access-passes 
  { user: principal, pass-id: uint } 
  { 
    used: bool, 
    created-at: uint, 
    expires-at: uint,
    pass-type: (string-ascii 50)
  }
)
(define-map user-pass-count principal uint)
(define-map premium-features principal bool)

(define-data-var next-pass-id uint u1)
(define-data-var kyc-fee uint u1000000)
(define-data-var pass-price uint u500000)
(define-data-var pass-validity-period uint u144)

(define-read-only (is-kyc-verified (user principal))
  (default-to false (map-get? kyc-verified-users user))
)

(define-read-only (get-pass-details (user principal) (pass-id uint))
  (map-get? access-passes { user: user, pass-id: pass-id })
)

(define-read-only (get-user-pass-count (user principal))
  (default-to u0 (map-get? user-pass-count user))
)

(define-read-only (is-pass-valid (user principal) (pass-id uint))
  (match (map-get? access-passes { user: user, pass-id: pass-id })
    pass-data 
    (and 
      (not (get used pass-data))
      (< stacks-block-height (get expires-at pass-data))
    )
    false
  )
)

(define-read-only (has-premium-access (user principal))
  (default-to false (map-get? premium-features user))
)

(define-read-only (get-contract-info)
  {
    kyc-fee: (var-get kyc-fee),
    pass-price: (var-get pass-price),
    pass-validity-blocks: (var-get pass-validity-period),
    total-passes-issued: (- (var-get next-pass-id) u1)
  }
)

(define-public (submit-kyc-verification)
  (let ((user tx-sender))
    (asserts! (not (is-kyc-verified user)) ERR_ALREADY_KYC_VERIFIED)
    (try! (stx-transfer? (var-get kyc-fee) user CONTRACT_OWNER))
    (map-set kyc-verified-users user true)
    (ok true)
  )
)

(define-public (admin-verify-kyc (user principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (not (is-kyc-verified user)) ERR_ALREADY_KYC_VERIFIED)
    (map-set kyc-verified-users user true)
    (ok true)
  )
)

(define-public (purchase-access-pass (pass-type (string-ascii 50)))
  (let (
    (user tx-sender)
    (current-pass-id (var-get next-pass-id))
    (current-count (get-user-pass-count user))
  )
    (asserts! (is-kyc-verified user) ERR_NOT_KYC_VERIFIED)
    (try! (stx-transfer? (var-get pass-price) user CONTRACT_OWNER))
    (map-set access-passes 
      { user: user, pass-id: current-pass-id }
      {
        used: false,
        created-at: stacks-block-height,
        expires-at: (+ stacks-block-height (var-get pass-validity-period)),
        pass-type: pass-type
      }
    )
    (map-set user-pass-count user (+ current-count u1))
    (var-set next-pass-id (+ current-pass-id u1))
    (ok current-pass-id)
  )
)

(define-public (use-access-pass (pass-id uint))
  (let (
    (user tx-sender)
    (pass-key { user: user, pass-id: pass-id })
  )
    (asserts! (is-kyc-verified user) ERR_NOT_KYC_VERIFIED)
    (match (map-get? access-passes pass-key)
      pass-data
      (begin
        (asserts! (not (get used pass-data)) ERR_PASS_ALREADY_USED)
        (asserts! (< stacks-block-height (get expires-at pass-data)) ERR_PASS_EXPIRED)
        (map-set access-passes pass-key (merge pass-data { used: true }))
        (ok (get pass-type pass-data))
      )
      ERR_PASS_NOT_FOUND
    )
  )
)

(define-public (access-premium-feature (feature-name (string-ascii 100)))
  (let ((user tx-sender))
    (asserts! (is-kyc-verified user) ERR_NOT_KYC_VERIFIED)
    (asserts! (has-premium-access user) ERR_UNAUTHORIZED)
    (ok feature-name)
  )
)

(define-public (grant-premium-access (user principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-kyc-verified user) ERR_NOT_KYC_VERIFIED)
    (map-set premium-features user true)
    (ok true)
  )
)

(define-public (revoke-premium-access (user principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-delete premium-features user)
    (ok true)
  )
)

(define-public (revoke-kyc (user principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-delete kyc-verified-users user)
    (map-delete premium-features user)
    (ok true)
  )
)

(define-public (update-kyc-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set kyc-fee new-fee)
    (ok true)
  )
)

(define-public (update-pass-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set pass-price new-price)
    (ok true)
  )
)

(define-public (update-pass-validity (new-validity uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set pass-validity-period new-validity)
    (ok true)
  )
)

(define-public (emergency-withdraw)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (as-contract (stx-transfer? (stx-get-balance tx-sender) tx-sender CONTRACT_OWNER))
  )
)

(define-public (batch-verify-kyc (users (list 50 principal)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map set-kyc-status users))
  )
)

(define-private (set-kyc-status (user principal))
  (map-set kyc-verified-users user true)
)