"
Explicitly synthetic same-image authority adapter. Identity registries bind original/child/callback WorkUnits, exact service class/name/epoch, copied actor/request/digest and source clock generation. Bounded pending state, deduplication and positive retirement prevent stale callbacks from publishing. No live proof or session object enters domain records.
"
Class {
	#name : 'CGDevelopmentRuntimeBridge',
	#superclass : 'Object',
	#instVars : [
		'identities',
		'clock',
		'ports',
		'inputs',
		'pending',
		'checks',
		'replies',
		'mutex',
		'lastMillis',
		'clockFault',
		'clockGeneration',
		'decisionsIssued'
	],
	#category : 'Catalyst-Groups-Development',
	#package : 'Catalyst-Groups-Development'
}

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> begin: unit context: context owner: owner [
 | record check |
 self expireInvocations.
 mutex critical: [
  | key previous |
  record := inputs at: unit ifAbsent: [ unit completeWith: (self outcome: #NotAuthorised). ^ #refused ].
  (self valid: unit context: context origin: #ingress destination: 'groups')
   ifFalse: [ self finishLocked: record with: (self outcome: #NotAuthorised). ^ #refused ].
  (record at: #phase) = #issued ifFalse: [ ^ #duplicateDelivery ].
  (record at: #groupEpoch) = (ports at: #groups) epoch
   ifFalse: [ self finishLocked: record with: (self outcome: #DependencyUnavailable). ^ #refused ].
  key := { (record at: #request) generation. record at: #actor. (record at: #request) operationId. ((CGCoreContract operation: (record at: #request) operation) at: 'mode') }.
  previous := pending at: key ifAbsent: [ nil ].
  previous ifNotNil: [
   (previous at: #request) digest = (record at: #request) digest
    ifFalse: [ self finishLocked: record with: (self outcome: #OperationConflict). ^ #conflict ].
   (previous at: #listeners) add: unit. inputs at: unit put: previous. ^ #joinedPending ].
  ((record at: #request) generation = owner generation or: [ (record at: #request) operation = 'GetOperationResult' ])
   ifFalse: [ self finishLocked: record with: (self outcome: #ResyncRequired). ^ #refused ].
  record at: #origin put: context verifiedSubmission;
   at: #subjects put: (owner developmentDecisionSubjectsFor: (record at: #request) actor: (record at: #actor));
   at: #phase put: #checking.
  pending at: key put: record.
  check := CGDevelopmentCheckWorkUnit new. checks at: check put: record ].
 self route: check origin: #groups destination: 'users' record: record.
 ^ #pending
]

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> complete: unit context: context owner: owner [
 | evidence record result |
 self expireInvocations.
 mutex critical: [
  evidence := replies at: unit ifAbsent: [ ^ #ignored ].
  record := evidence at: #record.
  ((self valid: unit context: context origin: #users destination: 'groups') and: [
   (record at: #phase) = #ready and: [
   (evidence at: #clockGeneration) == clockGeneration and: [
   (record at: #clockGeneration) == clockGeneration and: [
   (record at: #groupEpoch) = (ports at: #groups) epoch and: [
   (evidence at: #origin) == (record at: #origin) and: [
   (evidence at: #digest) = (record at: #request) digest and: [
   ((evidence at: #operation) = (record at: #request) operation and: [
    (evidence at: #invocationId) = (record at: #invocationId) and: [
    (evidence at: #actor) = (record at: #actor) and: [
    (evidence at: #operationId) = (record at: #request) operationId and: [
    (evidence at: #purposes) = (record at: #purposes) ] ] ] ]) ] ] ] ] ] ] ])
   ifFalse: [ self finishLocked: record with: (self outcome: #NotAuthorised). ^ #refused ].
  replies removeKey: unit. record at: #phase put: #publishing ].
 [
  result := owner execute: (record at: #request) actor: (record at: #actor) usingDecisions: (evidence at: #decisions) deadline: (record at: #deadline)
 ] on: Error do: [ :error | result := self outcome: #OutcomeUnknown ].
 mutex critical: [ self finishLocked: record with: result ].
 ^ result
]

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> decide: unit context: context [
 | record callback |
 self expireInvocations.
 mutex critical: [
  | decision |
  record := checks at: unit ifAbsent: [ ^ #ignored ].
  (self valid: unit context: context origin: #groups destination: 'users')
   ifFalse: [ self finishLocked: record with: (self outcome: #NotAuthorised). ^ #refused ].
  (record at: #phase) = #checking ifFalse: [ ^ #ignored ].
  decision := identities copyDecisionsFor: (record at: #subjects).
  decisionsIssued := decisionsIssued + 1.
  record at: #phase put: #ready.
  checks removeKey: unit.
  callback := CGCoreDecisionWorkUnit new.
  replies at: callback put: { #record -> record. #invocationId -> (record at: #invocationId) copy.
   #purposes -> (record at: #purposes) copy. #actor -> (record at: #actor) copy.
   #operationId -> (record at: #request) operationId copy. #decisions -> decision. #issuedAt -> self now.
   #clockGeneration -> clockGeneration. #digest -> (record at: #request) digest copy.
   #operation -> (record at: #request) operation. #origin -> (record at: #origin) } asDictionary ].
 self route: callback origin: #users destination: 'groups' record: record.
 ^ #issued
]

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> diagnostics [
 ^ mutex critical: [ { #inputs -> inputs size. #pending -> pending size.
  #checks -> checks size. #replies -> replies size. #decisionsIssued -> decisionsIssued } asDictionary ]
]

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> expireInvocations [
 mutex critical: [
  | current |
  [ current := self now ] on: CGCoreRefusal do: [ :error | current := nil ].
  inputs values asSet do: [ :record |
   ((current isNil or: [ current >= (record at: #deadline) ]) and: [ (record at: #phase) ~= #publishing ]) ifTrue: [
    self finishLocked: record with: (self outcome: #DependencyUnavailable) ] ] ]
]

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> finishLocked: record with: result [
 (record at: #listeners) do: [ :unit | unit completeWith: result ].
 inputs keys copy do: [ :unit | (inputs at: unit) == record ifTrue: [ inputs removeKey: unit ] ].
 checks keys copy do: [ :unit | (checks at: unit) == record ifTrue: [ checks removeKey: unit ] ].
 replies keys copy do: [ :unit | ((replies at: unit) at: #record) == record ifTrue: [ replies removeKey: unit ] ].
 pending keys copy do: [ :key | (pending at: key) == record ifTrue: [ pending removeKey: key ] ].
 record at: #phase put: #retired
]

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> identities: adapter clock: aClock [
 identities := adapter. clock := aClock. ^ self
]

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> initialize [
 super initialize. mutex := Semaphore forMutualExclusion.
 ports := Dictionary new. inputs := IdentityDictionary new. pending := Dictionary new.
 checks := IdentityDictionary new. replies := IdentityDictionary new.
 clockGeneration := Object new. clockFault := false. decisionsIssued := 0
]

{ #category : 'execution' }
CGDevelopmentRuntimeBridge >> issue: request actor: actor [
 | unit record |
 unit := CGCoreInvocationWorkUnit new.
 [ mutex critical: [
  | now |
  now := self now.
  now > 18446744073709546615 ifTrue: [ CGCoreRefusal code: #DependencyUnavailable recorded: false retryable: true ].
  inputs size >= 64 ifTrue: [ CGCoreRefusal code: #Overloaded recorded: false retryable: true ].
  actor class = CGUserRef ifFalse: [ CGCoreRefusal code: #NotAuthorised recorded: false retryable: false ].
  (((CGCoreContract operation: request operation) at: 'mode') = 'mutation' or: [ request operation = 'GetOperationResult' ])
   ifFalse: [ CGCoreRefusal code: #NotSupported recorded: false retryable: false ].
  record := { #invocationId -> UUID new uuidData copy. #purposes -> (self purposesFor: request).
   #request -> request veryDeepCopy. #actor -> actor veryDeepCopy.
   #deadline -> (now + 5000). #clockGeneration -> clockGeneration.
   #groupEpoch -> (ports at: #groups) epoch. #phase -> #issued.
   #listeners -> (OrderedCollection with: unit) } asDictionary.
  inputs at: unit put: record ] ]
 on: CGCoreRefusal do: [ :error | unit completeWith: (self outcome: error code). ^ unit ].
 self route: unit origin: #ingress destination: 'groups' record: record.
 ^ unit
]

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> now [
 | value |
 clockFault ifTrue: [ CGCoreRefusal code: #DependencyUnavailable recorded: false retryable: true ].
 value := clock currentMillis.
 ((value isInteger and: [ value between: 0 and: 18446744073709551615 ]) and: [ lastMillis isNil or: [ value >= lastMillis ] ])
  ifFalse: [ clockFault := true. CGCoreRefusal code: #DependencyUnavailable recorded: false retryable: true ].
 lastMillis := value. ^ value
]

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> outcome: code [
 ^ CGOperationOutcome new at: #code put: code; at: #recorded put: false;
  at: #retryable put: (#(DependencyUnavailable Overloaded) includes: code); at: #receipt put: nil; yourself
]

{ #category : 'execution' }
CGDevelopmentRuntimeBridge >> purposesFor: request [
 | purposes |
 request operation = 'GetOperationResult' ifTrue: [ ^ #('groups.read') ].
 purposes := OrderedCollection new.
 purposes add: (request operation = 'CreateGroup' ifTrue: [ 'groups.create' ] ifFalse: [
  request operation = 'LeaveGroup' ifTrue: [ 'groups.selfExit' ] ifFalse: [
   ((CGCoreContract operation: request operation) at: 'precondition') = 'group' ifTrue: [ 'groups.admin' ] ifFalse: [ 'groups.member' ] ] ]).
 request operation = 'InviteMember' ifTrue: [ purposes add: 'groups.invite' ].
 request operation = 'AcceptInvitation' ifTrue: [ purposes add: 'groups.accept' ].
 request operation = 'DecideApplication' ifTrue: [ purposes add: 'groups.accept' ].
 request operation = 'ApplyToJoin' ifTrue: [ purposes add: 'groups.apply' ].
 request operation = 'JoinOpenGroup' ifTrue: [ purposes add: 'groups.join' ].
 (#('TransferStewardship' 'AcceptStewardship' 'BeginDissolution') includes: request operation) ifTrue: [ purposes add: 'groups.governance.v1' ].
 ^ purposes asArray
]

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> registerPort: port role: role [
 | expected |
 expected := { #ingress -> CGDevelopmentIngressService. #groups -> CGCoreService. #users -> CGDevelopmentUsersService } asDictionary.
 ((expected at: role) = port serviceClass and: [ port serviceIdentifier = role asString ])
  ifFalse: [ self error: 'Exact configured development service required' ].
 mutex critical: [
  inputs isEmpty ifFalse: [ self error: 'Retire invocations before changing service activations' ].
  ports at: role put: port ]
]

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> resetDevelopmentClock [
 self retireAll.
 mutex critical: [ clockGeneration := Object new. lastMillis := nil. clockFault := false ]
]

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> retireAll [
 mutex critical: [
  inputs values asSet do: [ :record |
   self finishLocked: record with: (self outcome: ((record at: #phase) = #publishing ifTrue: [ #OutcomeUnknown ] ifFalse: [ #DependencyUnavailable ])) ] ]
]

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> route: unit origin: role destination: target record: record [
 | observed |
 [ observed := (ports at: role) submitRouted: ((CRWorkUnitEnvelope onWorkUnit: unit) serviceIdentifier: target; yourself) admittedBy: nil releasedBy: nil ]
  on: Error do: [ :error | observed := nil ].
 (observed isNil or: [ observed admission = #refused ]) ifTrue: [
  mutex critical: [
   (record at: #phase) ~= #retired ifTrue: [
    (record at: #phase) = #publishing
     ifTrue: [ self finishLocked: record with: (self outcome: #OutcomeUnknown) ]
     ifFalse: [ self finishLocked: record with: (self outcome: #DependencyUnavailable) ] ] ] ].
 ^ observed
]

{ #category : 'development invocations' }
CGDevelopmentRuntimeBridge >> valid: unit context: context origin: role destination: destination [
 | observed port |
 observed := context verifiedSubmission.
 port := ports at: role ifAbsent: [ ^ false ].
 ^ observed notNil and: [
  context envelope workUnit == unit and: [
  context envelope serviceIdentifier = destination and: [
  port isActive and: [
  observed originServiceClass = port serviceClass and: [
  observed originServiceIdentifier = port serviceIdentifier and: [
  observed originEpoch = port epoch and: [ observed serviceIdentifier = destination ] ] ] ] ] ] ]
]
