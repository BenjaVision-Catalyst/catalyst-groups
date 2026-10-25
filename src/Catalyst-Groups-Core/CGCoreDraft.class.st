"
Private unpublished aggregate working state. All 20 frozen core mutations enforce actor, scope, fixed Steward/Member authority, revisions, admission, history/capacity and incarnation invariants. Publication belongs to CGCoreOwner. No transport handles, psychological records, relationship evidence or formation state.
"
Class {
	#name : 'CGCoreDraft',
	#superclass : 'Object',
	#instVars : [
		'state',
		'actor',
		'request',
		'identities',
		'now',
		'group',
		'changed',
		'receipt'
	],
	#category : 'Catalyst-Groups-Core',
	#package : 'Catalyst-Groups-Core'
}

{ #category : 'domain' }
CGCoreDraft >> acceptInvitation [
 | record holder member |
 record := self lookup: #invitations id: (self body at: 1).
 self requireEntityRevision: record. self requirePending: record.
 self require: (record at: #terms) = (group at: #admissionRevision) code: #GovernanceBlocked.
 holder := self lookup: #memberships id: (group at: #holder).
 self require: ((record at: #issuer) = holder id and: [ holder state = #active and: [ (group at: #governance) = #operational ] ]) code: #GovernanceBlocked.
 identities requireEligible: (holder at: #subject) minimumRevision: (state securityRevisions at: (holder at: #subject) ifAbsent: [ 0 ]).
 identities requireContactFrom: (holder at: #subject) to: actor.
 member := self admit: actor.
 record state: #accepted.
 ^ member
]

{ #category : 'domain' }
CGCoreDraft >> acceptStewardship [
 | offer successor holder |
 self requireAssurance.
 offer := self lookup: #offers id: (self body at: 1).
 self requireEntityRevision: offer. self requirePending: offer.
 self require: (offer at: #sourceEpoch) = (group at: #authorityEpoch) code: #GovernanceBlocked.
 self require: (group at: #governance) = #operational code: #GovernanceBlocked.
 holder := self lookup: #memberships id: (group at: #holder).
 identities requireEligible: (holder at: #subject) minimumRevision: (state securityRevisions at: (holder at: #subject) ifAbsent: [ 0 ]).
 successor := self lookup: #memberships id: (offer at: #successor).
 self require: successor state = #active code: #GovernanceBlocked.
 self checkTarget: actor.
 group at: #holder put: successor id.
 offer state: #accepted.
 self invalidate: #invitations matching: [ :r | (r at: #issuer) ~= successor id ].
 self markChangedAuthority: true. ^ successor
]

{ #category : 'domain' }
CGCoreDraft >> admit: user [
 | existing member count |
 self ensureRealm: user.
 identities requireEligible: user minimumRevision: (state securityRevisions at: user ifAbsent: [ 0 ]).
 existing := self currentMembership: user.
 existing ifNotNil: [ self require: existing state = #active code: #GovernanceBlocked. ^ existing ].
 (self restricted: user) ifTrue: [ self refuse: #GovernanceBlocked ].
 self require: (self occupiedIn: group) < (group at: #capacity) code: #CapacityReached.
 count := state groups values sumNumbers: [ :g | (g at: #memberships) values count: [ :m | (m at: #subject) = user and: [ #(active suspended) includes: m state ] ] ].
 self require: count < 32 code: #CapacityReached.
 member := self newRecord: CGMembership into: #memberships subject: user.
 member at: #state put: #active; at: #joinedAt put: now.
 self invalidate: #invitations matching: [ :i | (i at: #subject) = user ].
 self invalidate: #applications matching: [ :a | (a at: #subject) = user ].
 self markChangedAuthority: true.
 ^ member
]

{ #category : 'domain' }
CGCoreDraft >> applyToJoin [
 self require: (group at: #joinPolicy) = 'application' code: #GovernanceBlocked.
 ^ self newAdmission: #applications class: CGApplication user: actor ttl: 604800000
]

{ #category : 'domain' }
CGCoreDraft >> authorise [
 | operation record member |
 operation := request operation.
 operation = 'CreateGroup' ifTrue: [ ^ self ].
 group := state groups at: (self body at: 0) ifAbsent: [ self deny ].
 (actor domain = (group at: #domain) and: [ actor tenant = (group at: #tenant) ]) ifFalse: [ self deny ].
 ((CGCoreContract operation: operation) at: 'precondition') = 'group' ifTrue: [
  self isSteward ifFalse: [ self deny ]. ^ self ].
 (#('AcceptInvitation' 'DeclineInvitation') includes: operation) ifTrue: [
  record := self lookup: #invitations id: (self body at: 1).
  (record at: #subject) = actor ifFalse: [ self deny ]. ^ self ].
 operation = 'WithdrawApplication' ifTrue: [
  record := self lookup: #applications id: (self body at: 1).
  (record at: #subject) = actor ifFalse: [ self deny ]. ^ self ].
 operation = 'AcceptStewardship' ifTrue: [
  record := self lookup: #offers id: (self body at: 1).
  (record at: #subject) = actor ifFalse: [ self deny ]. ^ self ].
 operation = 'LeaveGroup' ifTrue: [
  record := self lookup: #memberships id: (self body at: 1).
  (record at: #subject) = actor ifFalse: [ self deny ]. ^ self ].
 (#('ApplyToJoin' 'JoinOpenGroup') includes: operation) ifTrue: [
  member := self currentMembership: actor.
  ((group at: #visibility) = 'discoverable' or: [ member notNil ]) ifFalse: [ self deny ]. ^ self ].
 CGCoreRefusal code: #NotSupported recorded: false retryable: false
]

{ #category : 'domain' }
CGCoreDraft >> beginDissolution [
 self requireAssurance.
 self dissolve.
 ^ group
]

{ #category : 'domain' }
CGCoreDraft >> body [
 ^ request body
]

{ #category : 'domain' }
CGCoreDraft >> changeMembershipTo: nextState subjectScoped: subjectScoped [
 | member |
 member := self lookup: #memberships id: (self body at: 1).
 self requireEntityRevision: member.
 self require: member id ~= (group at: #holder) code: #GovernanceBlocked.
 nextState = #active
  ifTrue: [ self require: member state = #suspended code: #GovernanceBlocked. self checkTarget: (member at: #subject) ]
  ifFalse: [ self require: (#(active suspended) includes: member state) code: #GovernanceBlocked.
   nextState = #suspended ifTrue: [ self require: member state = #active code: #GovernanceBlocked ] ].
 member state: nextState.
 self markChangedAuthority: true.
 ^ member
]

{ #category : 'domain' }
CGCoreDraft >> changed [
 ^ changed
]

{ #category : 'domain' }
CGCoreDraft >> checkTarget: user [
 self ensureRealm: user.
 identities requireEligible: user minimumRevision: (state securityRevisions at: user ifAbsent: [ 0 ]).
 (self restricted: user) ifTrue: [ self refuse: #GovernanceBlocked ]
]

{ #category : 'domain' }
CGCoreDraft >> createGroup [
 | member |
 self require: state groups size < 128 code: #CapacityReached.
 self require: (state groups values count: [ :g | (g at: #creator) = actor and: [ g state ~= #dissolved ] ]) < 4 code: #CapacityReached.
 group := CGGroup new.
 group at: #id put: UUID new uuidData copy; at: #revision put: 1; at: #authorityEpoch put: 1; at: #admissionRevision put: 1; at: #cursor put: 1; at: #state put: #active; at: #governance put: #operational; at: #domain put: actor domain; at: #tenant put: actor tenant; at: #creator put: actor; at: #name put: (self body at: 0); at: #joinPolicy put: (self body at: 1); at: #visibility put: (self body at: 2); at: #capacity put: (self body at: 3).
 #(memberships invitations applications offers restrictions) do: [ :key | group at: key put: Dictionary new ].
 state groups at: group id put: group.
 member := self admit: actor.
 group at: #holder put: member id; at: #authorityEpoch put: 1.
 ^ member
]

{ #category : 'domain' }
CGCoreDraft >> currentMembership: user [
 ^ (self records: #memberships) values detect: [ :m | (m at: #subject) = user and: [ #(active suspended) includes: m state ] ] ifNone: [ nil ]
]

{ #category : 'clock' }
CGCoreDraft >> deadlineAfter: duration [
 self require: now + duration <= 18446744073709551615 code: #CapacityReached.
 ^ now + duration
]

{ #category : 'domain' }
CGCoreDraft >> decideApplication [
 | record member |
 record := self lookup: #applications id: (self body at: 1).
 self requireEntityRevision: record. self requirePending: record.
 (self body at: 3) = 'decline' ifTrue: [ record state: #declined. self markChangedAuthority: false. ^ record ].
 self require: (record at: #terms) = (group at: #admissionRevision) code: #GovernanceBlocked.
 identities requireContactFrom: actor to: (record at: #subject).
 member := self admit: (record at: #subject).
 record state: #accepted. ^ member
]

{ #category : 'domain' }
CGCoreDraft >> declineInvitation [
 | record |
 record := self lookup: #invitations id: (self body at: 1).
 self requireEntityRevision: record. self requirePending: record.
 record state: #declined. self markChangedAuthority: false. ^ record
]

{ #category : 'domain' }
CGCoreDraft >> deny [
 CGCoreRefusal code: #NotAuthorised recorded: false retryable: false
]

{ #category : 'domain' }
CGCoreDraft >> dissolve [
 group at: #state put: #dissolving.
 group at: #governance put: #closed; at: #holder put: nil.
 #(invitations applications offers) do: [ :key | self invalidate: key matching: [ :r | true ] ].
 (self records: #memberships) values do: [ :m | (#(active suspended) includes: m state) ifTrue: [ m state: #removed ] ].
 self markChangedAuthority: true
]

{ #category : 'domain' }
CGCoreDraft >> ensureRealm: user [
 (actor sameRealmAs: user) ifFalse: [ self deny ]
]

{ #category : 'domain' }
CGCoreDraft >> group [
 ^ group
]

{ #category : 'domain' }
CGCoreDraft >> invalidate: key matching: predicate [
 (self records: key) values do: [ :record |
  (record state = #pending and: [ predicate value: record ]) ifTrue: [ record state: #invalidated ] ]
]

{ #category : 'domain' }
CGCoreDraft >> inviteMember [
 | target |
 target := CGUserRef fromMap: (self body at: 1).
 identities requireContactFrom: actor to: target.
 ^ self newAdmission: #invitations class: CGInvitation user: target ttl: (self body at: 2)
]

{ #category : 'domain' }
CGCoreDraft >> isSteward [
 | member |
 group ifNil: [ ^ false ].
 (group at: #governance) = #operational ifFalse: [ ^ false ].
 member := self currentMembership: actor.
 ^ member notNil and: [ member state = #active and: [ member id = (group at: #holder) ] ]
]

{ #category : 'domain' }
CGCoreDraft >> joinOpenGroup [
 self require: (group at: #joinPolicy) = 'open' code: #GovernanceBlocked.
 ^ self admit: actor
]

{ #category : 'domain' }
CGCoreDraft >> leaveGroup [
 ^ self changeMembershipTo: #left subjectScoped: true
]

{ #category : 'domain' }
CGCoreDraft >> lookup: key id: identifier [
 ^ (self records: key) at: identifier ifAbsent: [ self deny ]
]

{ #category : 'domain' }
CGCoreDraft >> markChangedAuthority: flag [
 changed := true.
 flag ifTrue: [ self touchAuthority ]
]

{ #category : 'domain' }
CGCoreDraft >> newAdmission: key class: recordClass user: user ttl: ttl [
 | record total |
 self checkTarget: user.
 self require: (self currentMembership: user) isNil code: #GovernanceBlocked.
 record := self pending: key for: user.
 record ifNotNil: [ ^ record ].
 self require: ((self records: key) values count: [ :r | r state = #pending ]) < 64 code: #CapacityReached.
 total := state groups values sumNumbers: [ :g | (g at: key) values count: [ :r | r state = #pending and: [ (r at: #subject) = user ] ] ].
 self require: total < (key = #invitations ifTrue: [ 64 ] ifFalse: [ 32 ]) code: #CapacityReached.
 (self records: key) values do: [ :r | (r state = #pending and: [ now >= (r at: #deadline) ]) ifTrue: [ r state: #expired ] ].
 record := self newRecord: recordClass into: key subject: user.
 record at: #state put: #pending; at: #deadline put: (self deadlineAfter: ttl); at: #terms put: (group at: #admissionRevision); at: #issuer put: (group at: #holder).
 self markChangedAuthority: false.
 ^ record
]

{ #category : 'domain' }
CGCoreDraft >> newRecord: recordClass into: key subject: user [
 | record records |
 records := self records: key.
 self require: records size < (CGCoreContract limit: (key = #memberships ifTrue: [ 'membershipHistoryPerGroup' ] ifFalse: [ 'recordHistoryPerKindPerGroup' ])) code: #CapacityReached.
 record := recordClass new.
 record at: #id put: UUID new uuidData copy; at: #subject put: user; at: #revision put: 1; at: #groupId put: group id.
 records at: record id put: record.
 ^ record
]

{ #category : 'domain' }
CGCoreDraft >> occupiedIn: aGroup [
 ^ (aGroup at: #memberships) values count: [ :m | #(active suspended) includes: m state ]
]

{ #category : 'domain' }
CGCoreDraft >> pending: key for: user [
 ^ (self records: key) values detect: [ :r | r state = #pending and: [ (r at: #subject) = user and: [ now < (r at: #deadline) ] ] ] ifNone: [ nil ]
]

{ #category : 'domain' }
CGCoreDraft >> records: key [
 ^ group at: key
]

{ #category : 'domain' }
CGCoreDraft >> refuse: code [
 CGCoreRefusal code: code recorded: true retryable: false
]

{ #category : 'domain' }
CGCoreDraft >> removeAdmissionRestriction [
 | record |
 record := self lookup: #restrictions id: (self body at: 1).
 self requireEntityRevision: record.
 self require: record state = #active code: #GovernanceBlocked.
 self require: now < (record at: #deadline) code: #Expired.
 record state: #removed. self markChangedAuthority: true. ^ record
]

{ #category : 'domain' }
CGCoreDraft >> removeMember [
 ^ self changeMembershipTo: #removed subjectScoped: false
]

{ #category : 'domain' }
CGCoreDraft >> require: condition code: code [
 condition ifFalse: [ self refuse: code ]
]

{ #category : 'domain' }
CGCoreDraft >> requireAssurance [
 identities requireAssuranceFor: actor at: now
]

{ #category : 'domain' }
CGCoreDraft >> requireEntityRevision: record [
 self require: record revision = (self body at: 2) code: #RevisionConflict
]

{ #category : 'domain' }
CGCoreDraft >> requirePending: record [
 self require: record state = #pending code: #GovernanceBlocked.
 self require: now < (record at: #deadline) code: #Expired
]

{ #category : 'domain' }
CGCoreDraft >> restricted: user [
 ^ (self records: #restrictions) values anySatisfy: [ :r | (r at: #subject) = user and: [ r state = #active and: [ now < (r at: #deadline) ] ] ]
]

{ #category : 'domain' }
CGCoreDraft >> resumeMember [
 ^ self changeMembershipTo: #active subjectScoped: false
]

{ #category : 'domain' }
CGCoreDraft >> run [
 | selector |
 self authorise.
 group ifNotNil: [
  self require: group state = #active code: #GovernanceBlocked.
  ((CGCoreContract operation: request operation) at: 'precondition') = 'group' ifTrue: [
   self require: (request groupRevision = group revision and: [ request authorityEpoch = (group at: #authorityEpoch) ]) code: #RevisionConflict ] ].
 selector := (request operation first asLowercase asString , request operation allButFirst) asSymbol.
 receipt := self perform: selector.
 changed ifTrue: [
  request operation = 'CreateGroup' ifFalse: [ group advance ].
  group at: #cursor put: group revision ].
 self validateInvariants.
 ^ receipt
]

{ #category : 'domain' }
CGCoreDraft >> setAdmissionRestriction [
 | target record |
 target := CGUserRef fromMap: (self body at: 1). self ensureRealm: target.
 record := (self records: #restrictions) values detect: [ :r | (r at: #subject) = target and: [ r state = #active and: [ now < (r at: #deadline) ] ] ] ifNone: [ nil ].
 record ifNil: [
  (self records: #restrictions) values do: [ :r | (r state = #active and: [ now >= (r at: #deadline) ]) ifTrue: [ r state: #expired ] ].
  self require: ((self records: #restrictions) values count: [ :r | r state = #active ]) < 64 code: #CapacityReached.
  record := self newRecord: CGAdmissionRestriction into: #restrictions subject: target.
  record at: #state put: #active ] ifNotNil: [ record advance ].
 record at: #deadline put: (self deadlineAfter: (self body at: 2)).
 self invalidate: #invitations matching: [ :r | (r at: #subject) = target ].
 self invalidate: #applications matching: [ :r | (r at: #subject) = target ].
 self markChangedAuthority: true. ^ record
]

{ #category : 'domain' }
CGCoreDraft >> state: aState actor: aUser request: aRequest identities: adapter now: millis [
 state := aState. actor := aUser. request := aRequest. identities := adapter. now := millis. changed := false. ^ self
]

{ #category : 'domain' }
CGCoreDraft >> suspendMember [
 ^ self changeMembershipTo: #suspended subjectScoped: false
]

{ #category : 'domain' }
CGCoreDraft >> touchAuthority [
 | epoch |
 epoch := group at: #authorityEpoch.
 self require: epoch < 18446744073709551615 code: #CapacityReached.
 group at: #authorityEpoch put: epoch + 1.
 self invalidate: #offers matching: [ :each | true ]
]

{ #category : 'domain' }
CGCoreDraft >> transferStewardship [
 | successor offer |
 self requireAssurance.
 successor := self lookup: #memberships id: (self body at: 1).
 self require: successor revision = (self body at: 2) code: #RevisionConflict.
 self require: (successor state = #active and: [ successor id ~= (group at: #holder) ]) code: #GovernanceBlocked.
 self checkTarget: (successor at: #subject).
 self require: ((self records: #offers) values noneSatisfy: [ :r | r state = #pending and: [ now < (r at: #deadline) ] ]) code: #GovernanceBlocked.
 (self records: #offers) values do: [ :r | (r state = #pending and: [ now >= (r at: #deadline) ]) ifTrue: [ r state: #expired ] ].
 offer := self newRecord: CGStewardshipOffer into: #offers subject: (successor at: #subject).
 offer at: #state put: #pending; at: #successor put: successor id; at: #sourceEpoch put: (group at: #authorityEpoch); at: #deadline put: (self deadlineAfter: (self body at: 3)).
 self markChangedAuthority: false. ^ offer
]

{ #category : 'domain' }
CGCoreDraft >> updateGroup [
 | admissionChanged authorityChanged |
 self require: (self body at: 4) >= (self occupiedIn: group) code: #CapacityReached.
 admissionChanged := (group at: #joinPolicy) ~= (self body at: 2).
 authorityChanged := admissionChanged or: [ (group at: #visibility) ~= (self body at: 3) or: [ (group at: #capacity) ~= (self body at: 4) ] ].
 group at: #name put: (self body at: 1); at: #joinPolicy put: (self body at: 2); at: #visibility put: (self body at: 3); at: #capacity put: (self body at: 4).
 admissionChanged ifTrue: [
  self require: (group at: #admissionRevision) < 18446744073709551615 code: #CapacityReached.
  group at: #admissionRevision put: (group at: #admissionRevision) + 1.
  self invalidate: #invitations matching: [ :i | true ].
  self invalidate: #applications matching: [ :a | true ] ].
 self markChangedAuthority: authorityChanged.
 ^ group
]

{ #category : 'domain' }
CGCoreDraft >> validateInvariants [
 state groups values do: [ :g |
  | current holder |
  current := (g at: #memberships) values select: [ :m | #(active suspended) includes: m state ].
  self require: (current collect: [ :m | m at: #subject ]) asSet size = current size code: #GovernanceBlocked.
  self require: current size <= (g at: #capacity) code: #CapacityReached.
  (g at: #governance) = #operational ifTrue: [
   holder := (g at: #memberships) at: (g at: #holder) ifAbsent: [ self refuse: #GovernanceBlocked ].
   self require: (g state = #active and: [ holder state = #active ]) code: #GovernanceBlocked ].
  g state ~= #active ifTrue: [ self require: current isEmpty code: #GovernanceBlocked ] ]
]

{ #category : 'domain' }
CGCoreDraft >> withdrawApplication [
 | record |
 record := self lookup: #applications id: (self body at: 1).
 self requireEntityRevision: record. self requirePending: record.
 record state: #withdrawn. self markChangedAuthority: false. ^ record
]

{ #category : 'domain' }
CGCoreDraft >> withdrawInvitation [
 | record |
 record := self lookup: #invitations id: (self body at: 1).
 self requireEntityRevision: record. self requirePending: record.
 record state: #withdrawn. self markChangedAuthority: false. ^ record
]

{ #category : 'domain' }
CGCoreDraft >> withdrawStewardshipOffer [
 | offer |
 offer := self lookup: #offers id: (self body at: 1).
 self requireEntityRevision: offer. self requirePending: offer.
 offer state: #withdrawn. self markChangedAuthority: false. ^ offer
]
