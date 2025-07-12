(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_KYC_VERIFIED (err u101))
(define-constant ERR_PASS_ALREADY_USED (err u102))
(define-constant ERR_PASS_NOT_FOUND (err u103))
(define-constant ERR_INSUFFICIENT_BALANCE (err u104))
(define-constant ERR_PASS_EXPIRED (err u105))
(define-constant ERR_ALREADY_KYC_VERIFIED (err u106))
(define-constant ERR_PASS_NOT_TRANSFERABLE (err u107))
(define-constant ERR_INVALID_TRANSFER_PRICE (err u108))
(define-constant ERR_CANNOT_TRANSFER_TO_SELF (err u109))

(define-map kyc-verified-users principal bool)
(define-map access-passes 
  { user: principal, pass-id: uint } 
  { 
    used: bool, 
    created-at: uint, 
    expires-at: uint,
    pass-type: (string-ascii 50),
    transferable: bool
  }
)
(define-map user-pass-count principal uint)
(define-map premium-features principal bool)
(define-map transfer-listings 
  { user: principal, pass-id: uint }
  { price: uint, active: bool }
)

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

(define-read-only (get-transfer-listing (user principal) (pass-id uint))
  (map-get? transfer-listings { user: user, pass-id: pass-id })
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
        pass-type: pass-type,
        transferable: true
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

(define-public (list-pass-for-transfer (pass-id uint) (price uint))
  (let (
    (user tx-sender)
    (pass-key { user: user, pass-id: pass-id })
  )
    (asserts! (is-kyc-verified user) ERR_NOT_KYC_VERIFIED)
    (asserts! (> price u0) ERR_INVALID_TRANSFER_PRICE)
    (match (map-get? access-passes pass-key)
      pass-data
      (begin
        (asserts! (not (get used pass-data)) ERR_PASS_ALREADY_USED)
        (asserts! (< stacks-block-height (get expires-at pass-data)) ERR_PASS_EXPIRED)
        (asserts! (get transferable pass-data) ERR_PASS_NOT_TRANSFERABLE)
        (map-set transfer-listings pass-key { price: price, active: true })
        (ok true)
      )
      ERR_PASS_NOT_FOUND
    )
  )
)

(define-public (cancel-transfer-listing (pass-id uint))
  (let (
    (user tx-sender)
    (listing-key { user: user, pass-id: pass-id })
  )
    (asserts! (is-kyc-verified user) ERR_NOT_KYC_VERIFIED)
    (map-delete transfer-listings listing-key)
    (ok true)
  )
)

(define-public (purchase-listed-pass (seller principal) (pass-id uint))
  (let (
    (buyer tx-sender)
    (pass-key { user: seller, pass-id: pass-id })
    (listing-key { user: seller, pass-id: pass-id })
    (new-pass-key { user: buyer, pass-id: pass-id })
  )
    (asserts! (is-kyc-verified buyer) ERR_NOT_KYC_VERIFIED)
    (asserts! (not (is-eq buyer seller)) ERR_CANNOT_TRANSFER_TO_SELF)
    (match (map-get? transfer-listings listing-key)
      listing-data
      (match (map-get? access-passes pass-key)
        pass-data
        (begin
          (asserts! (get active listing-data) ERR_PASS_NOT_FOUND)
          (asserts! (not (get used pass-data)) ERR_PASS_ALREADY_USED)
          (asserts! (< stacks-block-height (get expires-at pass-data)) ERR_PASS_EXPIRED)
          (asserts! (get transferable pass-data) ERR_PASS_NOT_TRANSFERABLE)
          (try! (stx-transfer? (get price listing-data) buyer seller))
          (map-delete access-passes pass-key)
          (map-delete transfer-listings listing-key)
          (map-set access-passes new-pass-key pass-data)
          (let (
            (seller-count (get-user-pass-count seller))
            (buyer-count (get-user-pass-count buyer))
          )
            (map-set user-pass-count seller (- seller-count u1))
            (map-set user-pass-count buyer (+ buyer-count u1))
          )
          (ok pass-id)
        )
        ERR_PASS_NOT_FOUND
      )
      ERR_PASS_NOT_FOUND
    )
  )
)

(define-public (direct-transfer-pass (pass-id uint) (recipient principal))
  (let (
    (sender tx-sender)
    (pass-key { user: sender, pass-id: pass-id })
    (new-pass-key { user: recipient, pass-id: pass-id })
  )
    (asserts! (is-kyc-verified sender) ERR_NOT_KYC_VERIFIED)
    (asserts! (is-kyc-verified recipient) ERR_NOT_KYC_VERIFIED)
    (asserts! (not (is-eq sender recipient)) ERR_CANNOT_TRANSFER_TO_SELF)
    (match (map-get? access-passes pass-key)
      pass-data
      (begin
        (asserts! (not (get used pass-data)) ERR_PASS_ALREADY_USED)
        (asserts! (< stacks-block-height (get expires-at pass-data)) ERR_PASS_EXPIRED)
        (asserts! (get transferable pass-data) ERR_PASS_NOT_TRANSFERABLE)
        (map-delete access-passes pass-key)
        (map-delete transfer-listings { user: sender, pass-id: pass-id })
        (map-set access-passes new-pass-key pass-data)
        (let (
          (sender-count (get-user-pass-count sender))
          (recipient-count (get-user-pass-count recipient))
        )
          (map-set user-pass-count sender (- sender-count u1))
          (map-set user-pass-count recipient (+ recipient-count u1))
        )
        (ok true)
      )
      ERR_PASS_NOT_FOUND
    )
  )
)