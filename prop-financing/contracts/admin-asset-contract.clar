;; Real Estate Asset Administration Platform

;; Platform error definitions
(define-constant AUTH-ERROR-CODE (err u401))
(define-constant EXISTING-ENTRY-CODE (err u402))
(define-constant BALANCE-INSUFFICIENT-CODE (err u403))
(define-constant ASSET-UNAVAILABLE-CODE (err u404))
(define-constant TENANCY-WAITING-CODE (err u405))
(define-constant SPACE-CONSTRAINT-CODE (err u406))
(define-constant FEE-LIMIT-CODE (err u407))
(define-constant DURATION-CONSTRAINT-CODE (err u408))
(define-constant INVALID-ASSET-ID-CODE (err u409))
(define-constant INACTIVE-ASSET-CODE (err u411))
(define-constant MINIMUM-DEPOSIT-CODE (err u412))
(define-constant LOCATION-REQUIRED-CODE (err u413))
(define-constant AMENITIES-REQUIRED-CODE (err u414))
(define-constant SYSTEM-MAX-VALUE u2000000000)

;; Core data structures
(define-map asset-catalog
  { asset-id: uint }
  {
    proprietor: principal,
    active-occupant: (optional principal),
    square-footage: uint,
    proprietor-fee: uint,
    occupancy-term: uint,
    enrollment-timestamp: (optional uint),
    location-details: (string-ascii 30),
    amenity-details: (string-ascii 20),
    availability-state: (string-ascii 20)
  }
)

(define-map capital-storage principal uint)

(define-map proprietor-trust-score principal uint)

(define-map proprietor-asset-portfolio
  principal
  (list 10 uint)
)

;; Core business logic implementations
(define-public (enroll-asset (square-footage uint) (proprietor-fee uint) (occupancy-term uint) 
                          (location-details (string-ascii 30)) 
                          (amenity-details (string-ascii 20)))
  (let ((asset-id (+ (var-get inventory-counter) u1)))
    ;; Input validation suite
    (asserts! (> square-footage u0) SPACE-CONSTRAINT-CODE)
    (asserts! (<= proprietor-fee u50) FEE-LIMIT-CODE)
    (asserts! (and (> occupancy-term u0) (<= occupancy-term u10000)) DURATION-CONSTRAINT-CODE)
    ;; Location and amenities validation
    (asserts! (> (len location-details) u0) LOCATION-REQUIRED-CODE)
    (asserts! (> (len amenity-details) u0) AMENITIES-REQUIRED-CODE)
    
    ;; Register the new asset
    (map-set asset-catalog 
      { asset-id: asset-id }
      {
        proprietor: tx-sender,
        active-occupant: none,
        square-footage: square-footage,
        proprietor-fee: proprietor-fee,
        occupancy-term: occupancy-term,
        enrollment-timestamp: none,
        location-details: location-details,
        amenity-details: amenity-details,
        availability-state: "OPEN"
      }
    )
    
    ;; Update the proprietor's portfolio record
    (let 
      (
        (current-portfolio (default-to (list) (map-get? proprietor-asset-portfolio tx-sender)))
        (updated-portfolio (unwrap-panic (as-max-len? (concat (list asset-id) current-portfolio) u10)))
      )
      ;; Maintain at most 10 most recent assets
      (map-set proprietor-asset-portfolio tx-sender updated-portfolio)
    )
    
    (var-set inventory-counter asset-id)
    (ok asset-id)
  )
)

(define-public (reserve-occupancy (asset-id uint))
  (let (
    (asset-details (unwrap! (map-get? asset-catalog { asset-id: asset-id }) ASSET-UNAVAILABLE-CODE))
    (occupant-funds (default-to u0 (map-get? capital-storage tx-sender)))
  )
    ;; Validate transaction parameters
    (asserts! (<= asset-id (var-get inventory-counter)) INVALID-ASSET-ID-CODE)
    (asserts! (is-none (get active-occupant asset-details)) EXISTING-ENTRY-CODE)
    (asserts! (is-eq (get availability-state asset-details) "OPEN") ASSET-UNAVAILABLE-CODE)
    (asserts! (>= occupant-funds (get square-footage asset-details)) BALANCE-INSUFFICIENT-CODE)
    
    ;; Update asset occupancy records
    (map-set asset-catalog { asset-id: asset-id }
      (merge asset-details { 
        active-occupant: (some tx-sender),
        enrollment-timestamp: (some block-height),
        availability-state: "RESERVED"
      })
    )
    
    ;; Execute financial transactions
    (map-set capital-storage tx-sender (- occupant-funds (get square-footage asset-details)))
    (map-set capital-storage (get proprietor asset-details) 
      (+ (default-to u0 (map-get? capital-storage (get proprietor asset-details))) 
         (get square-footage asset-details)))
    
    (ok true)
  )
)

(define-public (finalize-tenancy (asset-id uint))
  (let (
    (asset-details (unwrap! (map-get? asset-catalog { asset-id: asset-id }) ASSET-UNAVAILABLE-CODE))
    (occupant-balance (default-to u0 (map-get? capital-storage tx-sender)))
    (base-cost (get square-footage asset-details))
    (proprietor-premium (/ (* (get square-footage asset-details) (get proprietor-fee asset-details)) u100))
    (full-payment (+ base-cost proprietor-premium))
  )
    ;; Comprehensive validation checks
    (asserts! (<= asset-id (var-get inventory-counter)) INVALID-ASSET-ID-CODE)
    (asserts! (is-eq (get active-occupant asset-details) (some tx-sender)) AUTH-ERROR-CODE)
    (asserts! (is-eq (get availability-state asset-details) "RESERVED") ASSET-UNAVAILABLE-CODE)
    (asserts! (>= (- block-height (unwrap! (get enrollment-timestamp asset-details) ASSET-UNAVAILABLE-CODE)) 
                (get occupancy-term asset-details)) TENANCY-WAITING-CODE)
    (asserts! (>= occupant-balance full-payment) BALANCE-INSUFFICIENT-CODE)
    
    ;; Execute payment to proprietor
    (map-set capital-storage tx-sender (- occupant-balance full-payment))
    (map-set capital-storage (get proprietor asset-details) 
      (+ (default-to u0 (map-get? capital-storage (get proprietor asset-details))) 
         full-payment)
    )
    
    ;; Update proprietor's trust score
    (let ((trust-score (default-to u0 (map-get? proprietor-trust-score 
                        (get proprietor asset-details)))))
      (map-set proprietor-trust-score
        (get proprietor asset-details)
        (+ trust-score u1)
      )
    )
    
    ;; Update asset lifecycle status
    (map-set asset-catalog { asset-id: asset-id } 
      (merge asset-details { availability-state: "TENANCY_COMPLETE" }))
    (ok true)
  )
)

(define-public (withdraw-asset (asset-id uint))
  (let (
    (asset-details (unwrap! (map-get? asset-catalog { asset-id: asset-id }) ASSET-UNAVAILABLE-CODE))
  )
    ;; Security validations
    (asserts! (<= asset-id (var-get inventory-counter)) INVALID-ASSET-ID-CODE)
    (asserts! (is-eq (get proprietor asset-details) tx-sender) AUTH-ERROR-CODE)
    (asserts! (is-eq (get availability-state asset-details) "OPEN") ASSET-UNAVAILABLE-CODE)
    
    ;; Change availability status
    (map-set asset-catalog { asset-id: asset-id } 
      (merge asset-details { availability-state: "WITHDRAWN" }))
    (ok true)
  )
)

(define-public (add-funds (amount uint))
  (let (
    (current-balance (default-to u0 (map-get? capital-storage tx-sender)))
  )
    ;; Input validation
    (asserts! (> amount u0) MINIMUM-DEPOSIT-CODE)
    (asserts! (<= amount SYSTEM-MAX-VALUE) MINIMUM-DEPOSIT-CODE)
    (asserts! (<= (+ current-balance amount) SYSTEM-MAX-VALUE) MINIMUM-DEPOSIT-CODE)
    
    ;; Update account balance
    (map-set capital-storage tx-sender (+ current-balance amount))
    (ok true)
  )
)

;; System query interfaces
(define-read-only (fetch-asset-info (asset-id uint))
  (map-get? asset-catalog { asset-id: asset-id })
)

(define-read-only (view-account-balance (entity principal))
  (default-to u0 (map-get? capital-storage entity))
)

(define-read-only (check-proprietor-rating (proprietor principal))
  (default-to u0 (map-get? proprietor-trust-score proprietor))
)

(define-read-only (browse-owned-assets (entity principal))
  (default-to (list) (map-get? proprietor-asset-portfolio entity))
)

;; Asset value calculation
(define-read-only (calculate-asset-value (asset-id uint))
  (let (
    (asset-details (default-to 
                      {
                        proprietor: tx-sender,
                        active-occupant: none,
                        square-footage: u0,
                        proprietor-fee: u0,
                        occupancy-term: u0,
                        enrollment-timestamp: none,
                        location-details: "",
                        amenity-details: "",
                        availability-state: "NOT_FOUND"
                      }
                      (map-get? asset-catalog { asset-id: asset-id })))
  )
    (if (is-eq (get availability-state asset-details) "NOT_FOUND")
        u0
        (let (
              (market-value (get square-footage asset-details))
              (fee-component (/ (* market-value (get proprietor-fee asset-details)) u100))
             )
          (+ market-value fee-component)
        )
    )
  )
)

;; System initialization
(define-data-var inventory-counter uint u0)