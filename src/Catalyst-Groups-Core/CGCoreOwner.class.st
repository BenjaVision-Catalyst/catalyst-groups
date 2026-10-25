"
Single serial owner of the groups-core-dev-1 in-memory domain. Prepares detached domain state, result/digest, audit and journal before one reference publication. Asynchronous execution consumes a scoped decision projection, rechecks domain/security revisions and invocation expiry at publication, and restores the local fixture adapter under the mutex. No asynchronous work or external callback runs under that mutex. Reset changes data generation; no persistence, real Users or Connect claim.
"
Class {
	#name : 'CGCoreOwner',
	#superclass : 'Object',
	#instVars : [
		'state',
		'identities',
		'clock',
		'mutex',
		'running',
		'failurePoint',
		'lastMillis',
		'sourceContinuous',
		'clockFault',
		'requestBuckets',
		'inviteBuckets',
		'invocationDeadline'
	],
	#category : 'Catalyst-Groups-Core',
	#package : 'Catalyst-Groups-Core'
}

{ #category : 'execution' }
CGCoreOwner class >> identities: adapter clock: aClock [
 ^ self new configureIdentities: adapter clock: aClock
]

{ #category : 'execution' }
CGCoreOwner >> appendInternalEvent: kind group: group state: next now: now [
 | entries audits |
 entries := next journal at: group id ifAbsentPut: [ OrderedCollection new ].
 entries add: { #cursor -> group revision. #authorityEpoch -> (group at: #authorityEpoch). #at -> now } asDictionary.
 [ entries size > 1024 or: [ entries notEmpty and: [ now - (entries first at: #at) >= 3600000 ] ] ] whileTrue: [ entries removeFirst ].
 audits := next audit at: group id ifAbsentPut: [ OrderedCollection new ].
 audits add: { #event -> kind. #groupRevision -> group revision. #at -> now } asDictionary.
 [ audits size > 2048 ] whileTrue: [ audits removeFirst ]
]

{ #category : 'execution' }
CGCoreOwner >> appendPublicationFor: draft request: request actor: actor state: next now: now [
 | group entries audits entry |
 group := draft group.
 group ifNil: [ ^ self ].
 audits := next audit at: group id ifAbsentPut: [ OrderedCollection new ].
 entry := { #operationId -> request operationId. #actor -> actor. #operation -> request operation. #groupRevision -> group revision. #at -> now } asDictionary.
 audits add: entry.
 [ audits size > 2048 ] whileTrue: [ audits removeFirst ].
 draft changed ifFalse: [ ^ self ].
 entries := next journal at: group id ifAbsentPut: [ OrderedCollection new ].
 entries add: { #cursor -> group revision. #authorityEpoch -> (group at: #authorityEpoch). #at -> now } asDictionary.
 [ entries size > 1024 or: [ entries notEmpty and: [ now - (entries first at: #at) >= 3600000 ] ] ] whileTrue: [ entries removeFirst ]
]

{ #category : 'publication' }
CGCoreOwner >> appendRefusal: result group: group request: request actor: actor state: next now: now [
 | entries |
 entries := next audit at: group id ifAbsentPut: [ OrderedCollection new ].
 entries add: { #operationId -> request operationId. #actor -> actor. #operation -> request operation. #code -> result code. #at -> now } asDictionary.
 [ entries size > 2048 ] whileTrue: [ entries removeFirst ]
]

{ #category : 'execution' }
CGCoreOwner >> applyDevelopmentFact: sourceFact [
 ^ mutex critical: [
  | fact next user revision kind now group |
  running ifFalse: [ CGCoreRefusal code: #DependencyUnavailable recorded: false retryable: true ].
  fact := identities consumeFact: sourceFact.
  now := self checkedMillis. kind := fact at: #kind.
  (#(baseline restrict eligible close trustedClose finalize) includes: kind) ifFalse: [ CGCoreRefusal code: #NotAuthorised recorded: false retryable: false ].
  next := state copy.
  kind = #baseline ifTrue: [
   next sourceGeneration: (fact at: #generation); sourceSequence: (fact at: #sequence).
   state := next. sourceContinuous := true. ^ #baseline ].
  (state sourceGeneration = (fact at: #generation) and: [ (fact at: #sequence) = (state sourceSequence + 1) ]) ifFalse: [ sourceContinuous := false. CGCoreRefusal code: #DependencyUnavailable recorded: false retryable: true ].
  next sourceSequence: (fact at: #sequence).
  (#(trustedClose finalize) includes: kind) ifTrue: [
   group := next groups at: (fact at: #groupId) ifAbsent: [ CGCoreRefusal code: #NotAuthorised recorded: false retryable: false ].
   kind = #trustedClose ifTrue: [
    group state = #active ifFalse: [ CGCoreRefusal code: #GovernanceBlocked recorded: false retryable: false ].
    group at: #state put: #dissolving; at: #governance put: #closed; at: #holder put: nil.
    (group at: #memberships) values do: [ :m | (#(active suspended) includes: m state) ifTrue: [ m state: #removed ] ].
    #(invitations applications offers) do: [ :key | (group at: key) values do: [ :r | r state = #pending ifTrue: [ r state: #invalidated ] ] ] ].
   kind = #finalize ifTrue: [
    (group state = #dissolving and: [ (fact at: #cleanupConfirmed) == true ]) ifFalse: [ CGCoreRefusal code: #GovernanceBlocked recorded: false retryable: false ].
    group at: #state put: #dissolved ].
   group advance. group at: #cursor put: group revision.
   self incrementEpochOf: group.
   self appendInternalEvent: kind group: group state: next now: now
  ] ifFalse: [
   user := fact at: #subject. revision := fact at: #revision.
   revision <= (state securityRevisions at: user ifAbsent: [ 0 ]) ifTrue: [ state := next. ^ #stale ].
   (next securityRevisions includesKey: user) ifFalse: [ next securityRevisions size >= 512 ifTrue: [ CGCoreRefusal code: #Overloaded recorded: false retryable: true ] ].
   next securityRevisions at: user put: revision.
   next groups values do: [ :g |
    | member affected |
    member := (g at: #memberships) values detect: [ :m | (m at: #subject) = user and: [ #(active suspended) includes: m state ] ] ifNone: [ nil ].
    affected := false.
    member ifNotNil: [
     kind = #close ifTrue: [
      member state: #removed. affected := true.
      member id = (g at: #holder) ifTrue: [ g at: #governance put: #recoveryRequired; at: #holder put: nil ] ].
     member id = (g at: #holder) ifTrue: [
      kind = #restrict ifTrue: [ g at: #governance put: #restricted. affected := true ].
      (kind = #eligible and: [ (g at: #governance) = #restricted ]) ifTrue: [
       identities requireEligible: user minimumRevision: revision.
       g at: #governance put: #operational. affected := true ] ] ].
    kind ~= #eligible ifTrue: [
     #(invitations applications offers) do: [ :key |
      (g at: key) values do: [ :r |
       (r state = #pending and: [ (r at: #subject) = user or: [
        (member notNil and: [ member id = (r at: #issuer ifAbsent: [ nil ]) ]) or: [ (g at: #governance) ~= #operational ] ] ]) ifTrue: [
        r state: #invalidated. affected := true ] ] ] ].
    affected ifTrue: [
     g advance. g at: #cursor put: g revision. self incrementEpochOf: g.
     self appendInternalEvent: kind group: g state: next now: now ] ] ].
  self probe: #beforePublication. state := next. self probe: #afterPublication.
  ^ #applied ]
]

{ #category : 'clock' }
CGCoreOwner >> checkedMillis [
 | now |
 clockFault ifTrue: [ CGCoreRefusal code: #DependencyUnavailable recorded: false retryable: true ].
 now := clock currentMillis.
 ((now isInteger and: [ now between: 0 and: 18446744073709551615 ]) and: [ lastMillis isNil or: [ now >= lastMillis ] ]) ifFalse: [
  clockFault := true. CGCoreRefusal code: #DependencyUnavailable recorded: false retryable: true ].
 lastMillis := now. ^ now
]

{ #category : 'execution' }
CGCoreOwner >> configureIdentities: adapter clock: aClock [
 identities := adapter. clock := aClock. ^ self
]

{ #category : 'admission' }
CGCoreOwner >> consumeRateFor: actor buckets: buckets burst: burst interval: interval now: now [
 | bucket refill tokens anchor |
 bucket := buckets at: actor ifAbsent: [
  buckets size >= 512 ifTrue: [ CGCoreRefusal code: #Overloaded recorded: false retryable: true ].
  { burst. now } ].
 refill := (now - bucket second) // interval.
 tokens := (bucket first + refill) min: burst.
 anchor := bucket second + (refill * interval).
 tokens < 1 ifTrue: [ CGCoreRefusal code: #Overloaded recorded: false retryable: true ].
 buckets at: actor put: { tokens - 1. anchor }
]

{ #category : 'development' }
CGCoreOwner >> developmentDecisionSubjectsFor: request actor: actor [
 ^ mutex critical: [
  | subjects group body record |
  subjects := Set with: actor. body := request body.
  request operation = 'InviteMember' ifTrue: [ subjects add: (CGUserRef fromMap: (body at: 1)) ].
  group := state groups at: (body at: 0 ifAbsent: [ nil ]) ifAbsent: [ nil ].
  group ifNotNil: [
   (#('AcceptInvitation' 'AcceptStewardship') includes: request operation) ifTrue: [
    record := (group at: #memberships) at: (group at: #holder) ifAbsent: [ nil ].
    record ifNotNil: [ subjects add: (record at: #subject) ] ].
   (#('ResumeMember' 'TransferStewardship') includes: request operation) ifTrue: [
    record := (group at: #memberships) at: (body at: 1) ifAbsent: [ nil ].
    record ifNotNil: [ subjects add: (record at: #subject) ] ].
   request operation = 'DecideApplication' ifTrue: [
    record := (group at: #applications) at: (body at: 1) ifAbsent: [ nil ].
    record ifNotNil: [ subjects add: (record at: #subject) ] ] ].
  subjects asArray veryDeepCopy ]
]

{ #category : 'development' }
CGCoreOwner >> developmentGroup: identifier [
 "Detached development inspection; not a permissioned client query."
 ^ mutex critical: [ (state groups at: identifier) veryDeepCopy ]
]

{ #category : 'execution' }
CGCoreOwner >> developmentSnapshot [
 "Diagnostic, detached graph for synthetic development examples only; never a client query."
 ^ mutex critical: [ state veryDeepCopy ]
]

{ #category : 'recovery' }
CGCoreOwner >> disclose: outcome actor: actor now: now [
 | copy receipt group member |
 copy := outcome veryDeepCopy.
 now - (copy at: #recordedAt) >= 86400000 ifTrue: [
  copy at: #code put: #OutcomeUnavailable; at: #receipt put: nil.
  ^ copy ].
 receipt := copy at: #receipt.
 receipt ifNil: [ ^ copy ].
 group := state groups at: (receipt at: #groupId) ifAbsent: [ copy at: #receipt put: nil. ^ copy ].
 member := (group at: #memberships) values detect: [ :m | (m at: #subject) = actor and: [ m state = #active ] ] ifNone: [ nil ].
 (((CGCoreContract operation: (copy at: #operation)) at: 'precondition') = 'group') ifTrue: [
  (member isNil or: [ member id ~= (group at: #holder) or: [ (group at: #governance) ~= #operational ] ]) ifTrue: [
   copy at: #receipt put: nil. ^ copy ] ].
 member ifNil: [
  | own |
  own := (group at: #memberships) at: (receipt at: #entityId) ifAbsent: [ nil ].
  (own notNil and: [ (own at: #subject) = actor ]) ifFalse: [ copy at: #receipt put: nil ] ].
 ^ copy
]

{ #category : 'execution' }
CGCoreOwner >> ensureOutcomeCapacityFor: actor [
 (state outcomes size >= 8192 or: [ (state outcomes keys count: [ :key | key second = actor ]) >= 1024 ]) ifTrue: [ CGCoreRefusal code: #Overloaded recorded: false retryable: true ]
]

{ #category : 'execution' }
CGCoreOwner >> execute: aRequest actor: user [
 ^ mutex critical: [
  [ self executeLocked: aRequest veryDeepCopy actor: user veryDeepCopy ]
   on: CGCoreRefusal do: [ :error | self outcomeCode: error code recorded: error recorded retryable: error retryable ] ]
]

{ #category : 'development' }
CGCoreOwner >> execute: request actor: actor usingDecisions: decisions deadline: deadline [
 ^ mutex critical: [
  | original previousDeadline |
  original := identities. previousDeadline := invocationDeadline.
  identities := decisions. invocationDeadline := deadline.
  [ [ self verifyInvocationDeadline. self executeLocked: request veryDeepCopy actor: actor veryDeepCopy ]
    on: CGCoreRefusal do: [ :error | self outcomeCode: error code recorded: error recorded retryable: error retryable ] ]
   ensure: [ identities := original. invocationDeadline := previousDeadline ] ]
]

{ #category : 'execution' }
CGCoreOwner >> executeLocked: request actor: actor [
 | now key previous next draft result revision |
 running ifFalse: [ CGCoreRefusal code: #DependencyUnavailable recorded: false retryable: true ].
 sourceContinuous ifFalse: [ CGCoreRefusal code: #DependencyUnavailable recorded: false retryable: true ].
 CGCoreContract require: actor class = CGUserRef.
 request operation = 'GetOperationResult' ifTrue: [ ^ self operationLocked: (request body at: 0) actor: actor generation: request generation ].
 (#('CreateGroup' 'UpdateGroup' 'InviteMember' 'WithdrawInvitation' 'AcceptInvitation' 'DeclineInvitation' 'ApplyToJoin' 'WithdrawApplication' 'DecideApplication' 'JoinOpenGroup' 'LeaveGroup' 'SuspendMember' 'ResumeMember' 'RemoveMember' 'SetAdmissionRestriction' 'RemoveAdmissionRestriction' 'TransferStewardship' 'AcceptStewardship' 'WithdrawStewardshipOffer' 'BeginDissolution') includes: request operation) ifFalse: [ CGCoreRefusal code: #NotSupported recorded: false retryable: false ].
 request generation = state generation ifFalse: [ CGCoreRefusal code: #ResyncRequired recorded: false retryable: false ].
 now := self checkedMillis.
 revision := identities requireEligible: actor minimumRevision: (state securityRevisions at: actor ifAbsent: [ 0 ]).
 self consumeRateFor: actor buckets: requestBuckets burst: 120 interval: 500 now: now.
 key := { state generation. actor. request operationId }.
 previous := state outcomes at: key ifAbsent: [ nil ].
 previous ifNotNil: [
  (previous at: #digest) = request digest ifFalse: [ CGCoreRefusal code: #OperationConflict recorded: false retryable: false ].
  ^ self disclose: previous actor: actor now: now ].
 request operation = 'InviteMember' ifTrue: [ self consumeRateFor: actor buckets: inviteBuckets burst: 20 interval: 180000 now: now ].
 self ensureOutcomeCapacityFor: actor.
 next := state copy.
 (next securityRevisions includesKey: actor) ifFalse: [
  next securityRevisions size >= 512 ifTrue: [ CGCoreRefusal code: #Overloaded recorded: false retryable: true ] ].
 next securityRevisions at: actor put: revision.
 draft := CGCoreDraft new state: next actor: actor request: request identities: identities now: now.
 [
  | record |
  record := draft run.
  result := self outcomeCode: #Success recorded: true retryable: false.
  result at: #receipt put: { #groupId -> draft group id. #entityId -> record id. #entityRevision -> record revision. #changeCursor -> (draft group at: #cursor). #state -> (request operation = 'RemoveAdmissionRestriction' ifTrue: [ #cleared ] ifFalse: [ record state ]) } asDictionary
 ] on: CGCoreRefusal do: [ :error |
  error recorded ifFalse: [ error pass ].
  next := state copy.
  result := self outcomeCode: error code recorded: true retryable: error retryable ].
 result at: #operation put: request operation; at: #id put: request operationId; at: #digest put: request digest; at: #actor put: actor; at: #recordedAt put: now; at: #generation put: next generation.
 next outcomes at: key put: result.
 result code = #Success
  ifTrue: [ self appendPublicationFor: draft request: request actor: actor state: next now: now ]
  ifFalse: [ draft group ifNotNil: [ self appendRefusal: result group: draft group request: request actor: actor state: next now: now ] ].
 self probe: #beforePublication.
 self verifyInvocationDeadline.
 state := next.
 self probe: #afterPublication.
 ^ result veryDeepCopy
]

{ #category : 'execution' }
CGCoreOwner >> expireDevelopmentRecords [
 ^ mutex critical: [
  | next now |
  now := self checkedMillis. next := state copy.
  next groups values do: [ :g |
   | changed authorityChanged entries |
   changed := false. authorityChanged := false.
   #(invitations applications offers restrictions) do: [ :key |
    (g at: key) values do: [ :r |
     ((#(pending active) includes: r state) and: [ now >= (r at: #deadline) ]) ifTrue: [
      r state: #expired. changed := true.
      key = #restrictions ifTrue: [ authorityChanged := true ] ] ] ].
   changed ifTrue: [
    g advance. g at: #cursor put: g revision.
    authorityChanged ifTrue: [ self incrementEpochOf: g ].
    self appendInternalEvent: #expire group: g state: next now: now ] ].
  self probe: #beforePublication. state := next. self probe: #afterPublication.
  next veryDeepCopy ]
]

{ #category : 'execution' }
CGCoreOwner >> failAt: point [
 "Deterministic development fault probe. No callback enters business records."
 failurePoint := point
]

{ #category : 'execution' }
CGCoreOwner >> generation [
 ^ mutex critical: [ state generation copy ]
]

{ #category : 'execution' }
CGCoreOwner >> incrementEpochOf: group [
 (group at: #authorityEpoch) = 18446744073709551615 ifTrue: [ CGCoreRefusal code: #CapacityReached recorded: false retryable: false ].
 group at: #authorityEpoch put: (group at: #authorityEpoch) + 1.
 (group at: #offers) values do: [ :r | r state = #pending ifTrue: [ r state: #invalidated ] ]
]

{ #category : 'initialization' }
CGCoreOwner >> initialize [
 super initialize. state := CGCoreState new. mutex := Semaphore forMutualExclusion. running := true. sourceContinuous := true. clockFault := false. requestBuckets := Dictionary new. inviteBuckets := Dictionary new
]

{ #category : 'execution' }
CGCoreOwner >> operation: identifier actor: actor generation: generation [
 ^ mutex critical: [ self operationLocked: identifier actor: actor generation: generation ]
]

{ #category : 'execution' }
CGCoreOwner >> operationLocked: identifier actor: actor generation: generation [
 | outcome now |
  (running and: [ sourceContinuous ]) ifFalse: [ ^ self outcomeCode: #DependencyUnavailable recorded: false retryable: true ].
  generation = state generation ifFalse: [ ^ self outcomeCode: #OutcomeUnavailable recorded: false retryable: false ].
  now := self checkedMillis.
  identities requireEligible: actor minimumRevision: (state securityRevisions at: actor ifAbsent: [ 0 ]).
  outcome := state outcomes at: { generation. actor. identifier } ifAbsent: [ ^ self outcomeCode: #OutcomeUnavailable recorded: false retryable: false ].
  ^ self disclose: outcome actor: actor now: now
]

{ #category : 'execution' }
CGCoreOwner >> outcomeCode: code recorded: recorded retryable: retryable [
 ^ CGOperationOutcome new at: #code put: code; at: #recorded put: recorded; at: #retryable put: retryable; at: #receipt put: nil; yourself
]

{ #category : 'execution' }
CGCoreOwner >> probe: point [
 failurePoint = point ifTrue: [ failurePoint := nil. self error: 'Injected publication interruption' ]
]

{ #category : 'lifecycle' }
CGCoreOwner >> reset [
 mutex critical: [ state := CGCoreState new. lastMillis := nil. clockFault := false. sourceContinuous := true. requestBuckets removeAll. inviteBuckets removeAll ]
]

{ #category : 'execution' }
CGCoreOwner >> start [
 mutex critical: [ running := true ]
]

{ #category : 'execution' }
CGCoreOwner >> stop [
 mutex critical: [ running := false ]
]

{ #category : 'development' }
CGCoreOwner >> verifyInvocationDeadline [
 invocationDeadline ifNotNil: [
  self checkedMillis >= invocationDeadline ifTrue: [
   CGCoreRefusal code: #DependencyUnavailable recorded: false retryable: true ] ]
]
