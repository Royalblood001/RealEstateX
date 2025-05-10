;; Real Estate Asset Administration Platform
;; Version 2: Advanced tenancy management with asset details and lifecycle monitoring

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