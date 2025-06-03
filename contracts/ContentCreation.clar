;; ContentCreation: Decentralized Content Creation and Reward System
;; Version: 1.0.0

(define-data-var platform-curator principal tx-sender)
(define-data-var content-pool uint u0)
(define-data-var engagement-rate uint u95) ;; engagement tokens per block
(define-data-var last-engagement-block uint u0) ;; last block when engagement was calculated
(define-map creator-portfolios principal uint)

;; Helper function to ensure only the platform curator can perform certain actions
(define-private (is-curator (caller principal))
  (begin
    (asserts! (is-eq caller (var-get platform-curator)) (err u300))
    (ok true)))

;; Initialize the content platform
(define-public (launch-platform (curator principal))
  (begin
    (asserts! (is-none (map-get? creator-portfolios curator)) (err u301))
    (var-set platform-curator curator)
    (ok "ContentCreation platform launched")))

;; Publish content to the platform
(define-public (publish-content (units uint))
  (begin
    (asserts! (> units u0) (err u302))
    (let ((current-portfolio (default-to u0 (map-get? creator-portfolios tx-sender))))
      (map-set creator-portfolios tx-sender (+ current-portfolio units))
      (var-set content-pool (+ (var-get content-pool) units))
      (ok (+ current-portfolio units)))))

;; Calculate engagement for all creators
(define-public (measure-engagement)
  (begin
    (try! (is-curator tx-sender))
    (let ((current-block tenure-height)
          (previous-measurement (var-get last-engagement-block)))
      (asserts! (> current-block previous-measurement) (err u303))
      ;; Calculate engagement based on blocks elapsed
      (let ((elapsed (- current-block previous-measurement))
            (total-engagement (* elapsed (var-get engagement-rate))))
        (var-set last-engagement-block current-block)
        (var-set content-pool (+ (var-get content-pool) total-engagement))
        (ok total-engagement)))))

;; Withdraw content and claim engagement rewards
(define-public (monetize-portfolio)
  (begin
    (let ((creator-position (default-to u0 (map-get? creator-portfolios tx-sender))))
      (asserts! (> creator-position u0) (err u304))
      (let ((total-content (var-get content-pool))
            (new-engagement (* (var-get engagement-rate) (- tenure-height (var-get last-engagement-block))))
            (portfolio-ratio (/ (* creator-position u100000) total-content)))
        ;; Calculate engagement based on portfolio ratio
        (let ((engagement-amount (/ (* portfolio-ratio new-engagement) u100000)))
          (map-delete creator-portfolios tx-sender)
          (var-set content-pool (- (var-get content-pool) creator-position))
          (ok (+ creator-position engagement-amount)))))))