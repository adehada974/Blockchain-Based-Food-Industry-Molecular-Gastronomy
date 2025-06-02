;; Innovation Development Contract
;; Advances molecular gastronomy techniques

(define-constant err-not-found (err u501))
(define-constant err-unauthorized (err u502))
(define-constant err-invalid-vote (err u503))

;; Innovation proposal data
(define-map innovation-proposals
  { proposal-id: uint }
  {
    proposer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    technique-category: (string-ascii 50),
    research-phase: (string-ascii 20),
    funding-required: uint,
    votes-for: uint,
    votes-against: uint,
    status: (string-ascii 20),
    created-at: uint
  }
)

;; Research collaboration
(define-map collaborations
  { proposal-id: uint, collaborator: principal }
  {
    role: (string-ascii 50),
    contribution: (string-ascii 200),
    joined-at: uint
  }
)

;; Voting records
(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, voted-at: uint }
)

;; Proposal counter
(define-data-var proposal-counter uint u0)

;; Submit innovation proposal
(define-public (submit-proposal
  (title (string-ascii 100))
  (description (string-ascii 500))
  (technique-category (string-ascii 50))
  (funding-required uint)
)
  (let ((proposal-id (+ (var-get proposal-counter) u1)))
    (map-set innovation-proposals
      { proposal-id: proposal-id }
      {
        proposer: tx-sender,
        title: title,
        description: description,
        technique-category: technique-category,
        research-phase: "proposed",
        funding-required: funding-required,
        votes-for: u0,
        votes-against: u0,
        status: "open",
        created-at: block-height
      }
    )
    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

;; Vote on proposal
(define-public (vote-proposal (proposal-id uint) (vote-for bool))
  (let ((proposal (unwrap! (map-get? innovation-proposals { proposal-id: proposal-id }) err-not-found)))
    (asserts! (is-none (map-get? votes { proposal-id: proposal-id, voter: tx-sender })) err-invalid-vote)
    (map-set votes
      { proposal-id: proposal-id, voter: tx-sender }
      { vote: vote-for, voted-at: block-height }
    )
    (if vote-for
      (map-set innovation-proposals
        { proposal-id: proposal-id }
        (merge proposal { votes-for: (+ (get votes-for proposal) u1) })
      )
      (map-set innovation-proposals
        { proposal-id: proposal-id }
        (merge proposal { votes-against: (+ (get votes-against proposal) u1) })
      )
    )
    (ok true)
  )
)

;; Join collaboration
(define-public (join-collaboration
  (proposal-id uint)
  (role (string-ascii 50))
  (contribution (string-ascii 200))
)
  (let ((proposal (unwrap! (map-get? innovation-proposals { proposal-id: proposal-id }) err-not-found)))
    (map-set collaborations
      { proposal-id: proposal-id, collaborator: tx-sender }
      {
        role: role,
        contribution: contribution,
        joined-at: block-height
      }
    )
    (ok true)
  )
)

;; Update research phase
(define-public (update-research-phase (proposal-id uint) (new-phase (string-ascii 20)))
  (let ((proposal (unwrap! (map-get? innovation-proposals { proposal-id: proposal-id }) err-not-found)))
    (asserts! (is-eq (get proposer proposal) tx-sender) err-unauthorized)
    (map-set innovation-proposals
      { proposal-id: proposal-id }
      (merge proposal { research-phase: new-phase })
    )
    (ok true)
  )
)

;; Get proposal
(define-read-only (get-proposal (proposal-id uint))
  (map-get? innovation-proposals { proposal-id: proposal-id })
)

;; Get collaboration
(define-read-only (get-collaboration (proposal-id uint) (collaborator principal))
  (map-get? collaborations { proposal-id: proposal-id, collaborator: collaborator })
)

;; Get vote
(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)
