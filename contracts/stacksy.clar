

;; Stacksy - NFT Marketplace
;; A simple SIP-009 NFT marketplace with royalties support

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-not-seller (err u102))
(define-constant err-token-listed (err u103))
(define-constant err-token-not-listed (err u104))
(define-constant err-transfer-failed (err u105))
(define-constant err-invalid-price (err u106))
(define-constant err-invalid-contract (err u107))
(define-constant err-invalid-token (err u108))

(define-trait nft-trait 
  ((get-last-token-id () (response uint uint))
   (get-token-uri (uint) (response (optional (string-ascii 256)) uint))
   (get-owner (uint) (response (optional principal) uint))
   (transfer (uint principal principal) (response bool uint))))

(define-map listings
  { token-id: uint }
  { seller: principal, price: uint, nft: principal })

(define-map royalties
  { nft: principal }
  { rate: uint })

(define-private (is-owner)
  (is-eq tx-sender contract-owner))

(define-private (get-listing (token-id uint))
  (map-get? listings { token-id: token-id }))

(define-private (check-is-owner (token-id uint) (nft-contract <nft-trait>))
  (let ((owner-opt (try! (contract-call? nft-contract get-owner token-id))))
    (match owner-opt 
      owner (if (is-eq tx-sender owner) 
              (ok true)
              err-not-token-owner)
      err-not-token-owner)))

(define-private (get-royalty-rate (nft principal))
  (get rate 
    (default-to 
      { rate: u0 } 
      (map-get? royalties { nft: nft }))))

(define-private (handle-royalty (price uint) (royalty uint))
  (if (> royalty u0)
    (stx-transfer? royalty tx-sender contract-owner)
    (ok true)))

(define-public (list-token (nft-contract <nft-trait>) (token-id uint) (price uint))
  (begin
    (asserts! (> token-id u0) err-invalid-token)
    (let ((listing (get-listing token-id)))
      (asserts! (is-none listing) err-token-listed)
      (asserts! (> price u0) err-invalid-price)
      (try! (check-is-owner token-id nft-contract))
      (let ((nft-principal (contract-of nft-contract)))
        (asserts! (not (is-eq nft-principal .stacksy)) err-invalid-contract)
        (try! (contract-call? nft-contract transfer token-id tx-sender (as-contract tx-sender)))
        (ok (map-set listings 
          { token-id: token-id }
          { seller: tx-sender, price: price, nft: nft-principal }))))))

(define-public (cancel-listing (nft-contract <nft-trait>) (token-id uint))
  (begin
    (asserts! (> token-id u0) err-invalid-token)
    (let ((listing (unwrap! (get-listing token-id) err-token-not-listed)))
      (let ((owner (get seller listing))
            (nft-principal (contract-of nft-contract)))
        (asserts! (is-eq tx-sender owner) err-not-seller)
        (asserts! (not (is-eq nft-principal .stacksy)) err-invalid-contract)
        (asserts! (is-eq nft-principal (get nft listing)) err-not-token-owner)
        (try! (as-contract
          (contract-call? nft-contract transfer token-id tx-sender owner)))
        (ok (map-delete listings { token-id: token-id }))))))

(define-public (buy-nft-token (nft-contract <nft-trait>) (token-id uint))
  (begin
    (asserts! (> token-id u0) err-invalid-token)
    (let ((listing (unwrap! (get-listing token-id) err-token-not-listed)))
      (let ((price (get price listing))
            (seller (get seller listing))
            (nft-principal (contract-of nft-contract))
            (listing-nft (get nft listing)))
        (asserts! (not (is-eq nft-principal .stacksy)) err-invalid-contract)
        (asserts! (is-eq nft-principal listing-nft) err-not-token-owner)
        (let ((royalty-rate (get-royalty-rate listing-nft))
              (royalty (/ (* price royalty-rate) u100)))
          (try! (stx-transfer? price tx-sender seller))
          (try! (handle-royalty price royalty))
          (try! (as-contract
            (contract-call? nft-contract transfer token-id tx-sender tx-sender)))
          (ok (map-delete listings { token-id: token-id })))))))

(define-public (set-royalty (nft <nft-trait>) (rate uint))
  (begin
    (asserts! (is-owner) err-owner-only)
    (asserts! (<= rate u100) err-invalid-price)
    (let ((nft-principal (contract-of nft)))
      (asserts! (not (is-eq nft-principal .stacksy)) err-invalid-contract)
      (ok (map-set royalties 
        { nft: nft-principal }
        { rate: rate })))))
