"
Behavioral SUnit tests plus executable frozen-schema, canonical digest and transition-guard vectors. Covers compound state effects, permissions, quota/rate/history limits, concurrent admission, correction of lifecycle state and interrupted publication. No real authentication or native client claim.
"
Class {
	#name : 'CGCoreTests',
	#superclass : 'CGCoreExamples',
	#category : 'Catalyst-Groups-Tests',
	#package : 'Catalyst-Groups-Tests'
}

{ #category : 'tests' }
CGCoreTests >> testAcceptedStewardship [
 self acceptedStewardship
]

{ #category : 'tests' }
CGCoreTests >> testAdmissionRestrictionDoesNotEraseExistingActiveMembership [
 | group member result |
 group := self create. self assert: (self join: bob group: group) isSuccess.
 group := self group: group id. member := self member: bob group: group.
 self assert: (self execute: 'SetAdmissionRestriction' body: { 0 -> group id. 1 -> bob asMap. 2 -> 60000 } asDictionary actor: alice group: group) isSuccess.
 group := self group: group id. result := self join: bob group: group.
 self assert: result isSuccess.
 self assert: ((result at: #receipt) at: #entityId) equals: member id.
 self assert: (self group: group id) revision equals: group revision
]

{ #category : 'tests' }
CGCoreTests >> testApplicationAcceptAndDecline [
 | group application result |
 group := self createPolicy: 'application' capacity: 4.
 result := self execute: 'ApplyToJoin' body: { 0 -> group id } asDictionary actor: bob group: group.
 self assert: result isSuccess. group := self group: group id.
 application := (group at: #applications) values anyOne.
 result := self execute: 'DecideApplication' body: ((self entityBody: application group: group) at: 3 put: 'accept'; yourself) actor: alice group: group.
 self assert: result isSuccess. group := self group: group id.
 self assert: (self member: bob group: group) state equals: #active.
 self assert: (((group at: #applications) at: application id) state) equals: #accepted.
 result := self execute: 'ApplyToJoin' body: { 0 -> group id } asDictionary actor: casey group: group.
 self assert: result isSuccess. group := self group: group id.
 application := (group at: #applications) values detect: [ :r | r state = #pending ].
 result := self execute: 'DecideApplication' body: ((self entityBody: application group: group) at: 3 put: 'decline'; yourself) actor: alice group: group.
 self assert: result isSuccess.
 self assert: (((self group: group id) at: #applications) at: application id) state equals: #declined
]

{ #category : 'tests' }
CGCoreTests >> testApplicationWithdrawalIsSubjectOwned [
 | group application result |
 group := self createPolicy: 'application' capacity: 4.
 self assert: (self execute: 'ApplyToJoin' body: { 0 -> group id } asDictionary actor: bob group: group) isSuccess.
 group := self group: group id. application := (group at: #applications) values anyOne.
 result := self execute: 'WithdrawApplication' body: (self entityBody: application group: group) actor: casey group: group.
 self assert: result code equals: #NotAuthorised.
 result := self execute: 'WithdrawApplication' body: (self entityBody: application group: group) actor: bob group: group.
 self assert: result isSuccess.
 self assert: (((self group: group id) at: #applications) at: application id) state equals: #withdrawn
]

{ #category : 'tests' }
CGCoreTests >> testBackwardClockFaultStaysClosedUntilReset [
 | group |
 group := self create. clock currentMillis: 999.
 self assert: (self join: bob group: group) code equals: #DependencyUnavailable.
 clock currentMillis: 2000.
 self assert: (self join: bob group: group) code equals: #DependencyUnavailable.
 owner reset. self assert: (self create) state equals: #active
]

{ #category : 'tests' }
CGCoreTests >> testCapacityCannotFallBelowSuspendedSeats [
 | group member result |
 group := self create. self assert: (self join: bob group: group) isSuccess.
 group := self group: group id. member := self member: bob group: group.
 self assert: (self execute: 'SuspendMember' body: (self entityBody: member group: group) actor: alice group: group) isSuccess.
 group := self group: group id.
 result := self execute: 'UpdateGroup' body: { 0 -> group id. 1 -> 'Small'. 2 -> 'open'. 3 -> 'discoverable'. 4 -> 1 } asDictionary actor: alice group: group.
 self assert: result code equals: #CapacityReached
]

{ #category : 'tests' }
CGCoreTests >> testCapacityRefusalKeepsInvitationPendingAndRecordsOutcome [
 | group invitation request result |
 group := self createPolicy: 'inviteOnly' capacity: 1.
 self assert: (self invite: bob group: group) isSuccess. group := self group: group id.
 invitation := (group at: #invitations) values anyOne.
 request := self request: 'AcceptInvitation' body: (self entityBody: invitation group: group) group: group.
 result := owner execute: request actor: bob.
 self assert: result code equals: #CapacityReached.
 self assert: (result at: #recorded).
 self assert: ((self group: group id) at: #invitations) values anyOne state equals: #pending.
 self assert: (owner execute: request actor: bob) code equals: #CapacityReached
]

{ #category : 'tests' }
CGCoreTests >> testConcurrentAdmissionCannotOverfillGroup [
 | group requests answers done |
 group := self createPolicy: 'open' capacity: 2.
 requests := { self request: 'JoinOpenGroup' body: { 0 -> group id } asDictionary group: group. self request: 'JoinOpenGroup' body: { 0 -> group id } asDictionary group: group }.
 answers := Array new: 2. done := Semaphore new.
 [ [ answers at: 1 put: (owner execute: requests first actor: bob) ] ensure: [ done signal ] ] fork.
 [ [ answers at: 2 put: (owner execute: requests second actor: casey) ] ensure: [ done signal ] ] fork.
 2 timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 10000) not ].
 self assert: (answers count: [ :r | r isSuccess ]) equals: 1.
 self assert: (answers count: [ :r | r code = #CapacityReached ]) equals: 1.
 self assert: ((self group: group id) at: #memberships) size equals: 2
]

{ #category : 'tests' }
CGCoreTests >> testCopiedLifecycleFactAndStreamGapRefuse [
 | group source fact |
 group := self create. source := UUID new uuidData copy.
 owner applyDevelopmentFact: (identities fact: #baseline subject: alice revision: 1 generation: source sequence: 0).
 fact := identities fact: #restrict subject: alice revision: 2 generation: source sequence: 1.
 self should: [ owner applyDevelopmentFact: fact veryDeepCopy ] raise: CGCoreRefusal.
 self assert: (owner applyDevelopmentFact: fact) equals: #applied.
 self assert: ((self group: group id) at: #governance) equals: #restricted.
 self should: [ owner applyDevelopmentFact: (identities fact: #eligible subject: alice revision: 3 generation: source sequence: 3) ] raise: CGCoreRefusal
]

{ #category : 'tests' }
CGCoreTests >> testCreatedGroup [
 self createdGroup
]

{ #category : 'tests' }
CGCoreTests >> testCreatorQuotaRefusesFifthGroup [
 | result |
 4 timesRepeat: [ self create ].
 result := self execute: 'CreateGroup' body: { 0 -> 'Fifth'. 1 -> 'open'. 2 -> 'discoverable'. 3 -> 4 } asDictionary actor: alice group: nil.
 self assert: result code equals: #CapacityReached.
 self assert: owner developmentSnapshot groups size equals: 4
]

{ #category : 'tests' }
CGCoreTests >> testCrossRealmAndPrivateTargetsAreNotDisclosed [
 | group foreign result |
 group := self create.
 foreign := CGUserRef domain: 'other' tenant: 'test' subject: 'bob'.
 identities allow: foreign.
 result := self execute: 'InviteMember' body: { 0 -> group id. 1 -> foreign asMap. 2 -> 60000 } asDictionary actor: alice group: group.
 self assert: result code equals: #NotAuthorised.
 group := self createPolicy: 'inviteOnly' capacity: 4.
 result := self execute: 'SuspendMember' body: { 0 -> group id. 1 -> UUID new uuidData copy. 2 -> 1 } asDictionary actor: bob group: group.
 self assert: result code equals: #NotAuthorised
]

{ #category : 'tests' }
CGCoreTests >> testDetachedSnapshotsAndRequestInputsCannotMutatePublishedState [
 | group copy request payload |
 group := self create. copy := owner developmentSnapshot.
 (copy groups at: group id) at: #capacity put: 0.
 self assert: ((self group: group id) at: #capacity) equals: 4.
 request := self request: 'JoinOpenGroup' body: { 0 -> group id } asDictionary group: group.
 payload := request payload. (payload at: 4) at: 0 put: UUID new uuidData copy.
 self assert: (owner execute: request actor: bob) isSuccess
]

{ #category : 'tests' }
CGCoreTests >> testDissolutionAwaitingCleanup [
 self dissolutionAwaitingCleanup
]

{ #category : 'tests' }
CGCoreTests >> testDissolutionWaitsForPositiveCleanup [
 | group source |
 group := self create. self assert: (self join: bob group: group) isSuccess. group := self group: group id.
 self assert: (self execute: 'BeginDissolution' body: { 0 -> group id } asDictionary actor: alice group: group) isSuccess.
 group := self group: group id.
 self assert: group state equals: #dissolving.
 self assert: (group at: #governance) equals: #closed.
 self assert: ((group at: #memberships) values allSatisfy: [ :m | m state = #removed ]).
 self assert: (self join: casey group: group) code equals: #GovernanceBlocked.
 source := UUID new uuidData copy.
 owner applyDevelopmentFact: (identities fact: #baseline subject: alice revision: 1 generation: source sequence: 0).
 self should: [ owner applyDevelopmentFact: (identities groupFact: #finalize group: group id generation: source sequence: 1 cleanupConfirmed: false) ] raise: CGCoreRefusal.
 self assert: (self group: group id) state equals: #dissolving.
 owner applyDevelopmentFact: (identities groupFact: #finalize group: group id generation: source sequence: 1 cleanupConfirmed: true).
 self assert: (self group: group id) state equals: #dissolved
]

{ #category : 'tests' }
CGCoreTests >> testDuplicateOpenAdmissionDoesNotCreateFalseChange [
 | group before result |
 group := self create. self assert: (self join: bob group: group) isSuccess.
 group := self group: group id. before := group revision.
 result := self join: bob group: group.
 self assert: result isSuccess.
 self assert: (self group: group id) revision equals: before.
 self assert: ((self group: group id) at: #memberships) size equals: 2
]

{ #category : 'tests' }
CGCoreTests >> testDuplicateOperationAndConflict [
 | request first second altered count |
 request := self request: 'CreateGroup' body: { 0 -> 'One'. 1 -> 'open'. 2 -> 'discoverable'. 3 -> 4 } asDictionary group: nil.
 first := owner execute: request actor: alice.
 second := owner execute: request actor: alice.
 self assert: (first at: #receipt) equals: (second at: #receipt).
 self assert: owner developmentSnapshot groups size equals: 1.
 self assert: owner developmentSnapshot outcomes size equals: 1.
 altered := request payload. (altered at: 4) at: 0 put: 'Other'.
 second := owner execute: (CGCoreRequest operation: 'CreateGroup' payload: altered) actor: alice.
 self assert: second code equals: #OperationConflict.
 self assert: owner developmentSnapshot groups size equals: 1
]

{ #category : 'tests' }
CGCoreTests >> testExpiredInvitationCannotWinBeforeCleanup [
 | group invitation result |
 group := self create. self assert: (self invite: bob group: group) isSuccess.
 group := self group: group id. invitation := (group at: #invitations) values anyOne.
 clock advanceMillis: 60000.
 result := self execute: 'AcceptInvitation' body: (self entityBody: invitation group: group) actor: bob group: group.
 self assert: result code equals: #Expired.
 self assert: ((self group: group id) at: #memberships) size equals: 1.
 owner expireDevelopmentRecords.
 self assert: (((self group: group id) at: #invitations) at: invitation id) state equals: #expired
]

{ #category : 'tests' }
CGCoreTests >> testExpiredOutcomeKeepsDigestTombstoneAndNeverExecutesAgain [
 | request original recovered changed |
 request := self request: 'CreateGroup' body: { 0 -> 'Retained'. 1 -> 'open'. 2 -> 'discoverable'. 3 -> 4 } asDictionary group: nil.
 original := owner execute: request actor: alice. self assert: original isSuccess.
 clock advanceMillis: 86400000.
 recovered := owner execute: request actor: alice.
 self assert: recovered code equals: #OutcomeUnavailable.
 self assert: (recovered at: #digest) equals: request digest.
 self assert: (recovered at: #receipt) isNil.
 self assert: owner developmentSnapshot groups size equals: 1.
 changed := request payload. (changed at: 4) at: 0 put: 'Different'.
 self assert: (owner execute: (CGCoreRequest operation: 'CreateGroup' payload: changed) actor: alice) code equals: #OperationConflict
]

{ #category : 'tests' }
CGCoreTests >> testFormerStewardRecoveryWithholdsAdministrativeReceipt [
 | group request result member offer |
 group := self create. self assert: (self join: bob group: group) isSuccess.
 group := self group: group id.
 request := self request: 'InviteMember' body: { 0 -> group id. 1 -> casey asMap. 2 -> 60000 } asDictionary group: group.
 self assert: (owner execute: request actor: alice) isSuccess.
 group := self group: group id. member := self member: bob group: group.
 self assert: (self execute: 'TransferStewardship' body: { 0 -> group id. 1 -> member id. 2 -> member revision. 3 -> 60000 } asDictionary actor: alice group: group) isSuccess.
 group := self group: group id. offer := (group at: #offers) values anyOne.
 self assert: (self execute: 'AcceptStewardship' body: (self entityBody: offer group: group) actor: bob group: group) isSuccess.
 result := owner operation: request operationId actor: alice generation: owner generation.
 self assert: result isSuccess. self assert: (result at: #receipt) isNil.
 self assert: (result at: #digest) equals: request digest
]

{ #category : 'tests' }
CGCoreTests >> testFrozenCanonicalVectorsAndDigests [
 (self frozenVectors at: 'valid') do: [ :vector |
  | value expected operation request |
  value := self decodeFixture: (vector at: 'value').
  CGCoreContract validate: value type: (vector at: 'type').
  expected := ByteArray readHexFrom: (vector at: 'cborHex').
  self assert: (CGCoreContract encode: value) equals: expected.
  (vector includesKey: 'requestDigestSha256') ifTrue: [
   operation := ((vector at: 'type') allButLast: 7).
   request := CGCoreRequest operation: operation payload: value.
   self assert: request digest equals: (ByteArray readHexFrom: (vector at: 'requestDigestSha256')) ] ]
]

{ #category : 'tests' }
CGCoreTests >> testFrozenInvalidValues [
 (self frozenVectors at: 'invalidValues') do: [ :vector |
  self should: [ CGCoreContract validate: (self decodeFixture: (vector at: 'value')) type: (vector at: 'type') ] raise: CGCoreRefusal ]
]

{ #category : 'tests' }
CGCoreTests >> testFrozenTransitionGuards [
 (self frozenVectors at: 'stateScenarios') do: [ :scenario |
  | block |
  block := [ CGCoreContract transition: (scenario at: 'machine') from: (scenario at: 'from') event: (scenario at: 'event') guards: (scenario at: 'facts') ].
  (scenario at: 'expected') = 'refused'
   ifTrue: [ self should: block raise: CGCoreRefusal ]
   ifFalse: [ self assert: block value equals: (scenario at: 'expected') ] ]
]

{ #category : 'tests' }
CGCoreTests >> testGovernanceAssuranceIsRequiredAndRetryable [
 | group request result |
 group := self create.
 clock advanceMillis: 300001.
 request := self request: 'BeginDissolution' body: { 0 -> group id } asDictionary group: group.
 result := owner execute: request actor: alice.
 self assert: result code equals: #AssuranceRequired.
 self deny: (result at: #recorded).
 identities allow: alice revision: 2 authenticatedAt: clock currentMillis.
 self assert: (owner execute: request actor: alice) isSuccess
]

{ #category : 'tests' }
CGCoreTests >> testHandoverCannotUseHolderWhoseEligibilityWasRevoked [
 | group member offer result |
 group := self create. self assert: (self join: bob group: group) isSuccess.
 group := self group: group id. member := self member: bob group: group.
 result := self execute: 'TransferStewardship' body: { 0 -> group id. 1 -> member id. 2 -> member revision. 3 -> 60000 } asDictionary actor: alice group: group.
 self assert: result isSuccess. group := self group: group id. offer := (group at: #offers) values anyOne.
 identities deny: alice revision: 2.
 result := self execute: 'AcceptStewardship' body: (self entityBody: offer group: group) actor: bob group: group.
 self assert: result code equals: #NotAuthorised.
 self assert: ((self group: group id) at: #holder) equals: (self member: alice group: group) id
]

{ #category : 'tests' }
CGCoreTests >> testHolderClosureNeverBlocksAccountClosureOrSelfAppoints [
 | group source fact |
 group := self create. self assert: (self join: bob group: group) isSuccess. group := self group: group id.
 source := UUID new uuidData copy.
 owner applyDevelopmentFact: (identities fact: #baseline subject: alice revision: 1 generation: source sequence: 0).
 identities deny: alice revision: 2.
 fact := identities fact: #close subject: alice revision: 2 generation: source sequence: 1.
 self assert: (owner applyDevelopmentFact: fact) equals: #applied.
 group := self group: group id.
 self assert: (group at: #governance) equals: #recoveryRequired.
 self assert: (group at: #holder) isNil.
 self assert: (self execute: 'BeginDissolution' body: { 0 -> group id } asDictionary actor: bob group: group) code equals: #NotAuthorised.
 self assert: (self execute: 'LeaveGroup' body: (self entityBody: (self member: bob group: group) group: group) actor: bob group: group) isSuccess
]

{ #category : 'tests' }
CGCoreTests >> testIdentityExactnessAndInputOwnership [
 | original first second map |
 original := 'Alice' copy.
 first := CGUserRef domain: 'catalyst' tenant: 'test' subject: original.
 original at: 1 put: $x.
 second := CGUserRef domain: 'catalyst' tenant: 'test' subject: 'alice'.
 self assert: first subject equals: 'Alice'. self deny: first = second.
 map := first asMap. (map at: 2) at: 1 put: $x.
 self assert: first subject equals: 'Alice'.
 self assert: (Set with: first with: (CGUserRef fromMap: first asMap)) size equals: 1.
 self should: [ CGUserRef domain: '' tenant: 'test' subject: 'a' ] raise: CGCoreRefusal
]

{ #category : 'tests' }
CGCoreTests >> testInterruptionBeforePublicationPublishesNothing [
 | request |
 request := self request: 'CreateGroup' body: { 0 -> 'Before'. 1 -> 'open'. 2 -> 'discoverable'. 3 -> 4 } asDictionary group: nil.
 owner failAt: #beforePublication.
 self should: [ owner execute: request actor: alice ] raise: Error.
 self assert: owner developmentSnapshot groups isEmpty.
 self assert: owner developmentSnapshot outcomes isEmpty.
 self assert: owner developmentSnapshot audit isEmpty.
 self assert: (owner execute: request actor: alice) isSuccess
]

{ #category : 'tests' }
CGCoreTests >> testInvitationAccepted [
 self invitationAccepted
]

{ #category : 'tests' }
CGCoreTests >> testInvitationNegativeDecisions [
 #('DeclineInvitation' 'WithdrawInvitation') do: [ :operation |
  | group invitation result |
  self setUp. group := self create. self assert: (self invite: bob group: group) isSuccess.
  group := self group: group id. invitation := (group at: #invitations) values anyOne.
  result := self execute: operation body: (self entityBody: invitation group: group) actor: (operation = 'DeclineInvitation' ifTrue: [ bob ] ifFalse: [ alice ]) group: group.
  self assert: result isSuccess.
  self assert: (((self group: group id) at: #invitations) at: invitation id) state equals: (operation = 'DeclineInvitation' ifTrue: [ #declined ] ifFalse: [ #withdrawn ]).
  self assert: ((self group: group id) at: #memberships) size equals: 1 ]
]

{ #category : 'tests' }
CGCoreTests >> testInvitationTokenBucketIsSeparate [
 | group |
 group := self create.
 20 timesRepeat: [ self assert: (self invite: bob group: group) isSuccess ].
 self assert: (self invite: bob group: group) code equals: #Overloaded.
 clock advanceMillis: 180000.
 self assert: (self invite: bob group: group) isSuccess
]

{ #category : 'tests' }
CGCoreTests >> testLostReplyAfterPublicationRecoversSameOutcome [
 | request recovered snapshot |
 request := self request: 'CreateGroup' body: { 0 -> 'After'. 1 -> 'open'. 2 -> 'discoverable'. 3 -> 4 } asDictionary group: nil.
 owner failAt: #afterPublication.
 self should: [ owner execute: request actor: alice ] raise: Error.
 snapshot := owner developmentSnapshot.
 self assert: snapshot groups size equals: 1.
 self assert: snapshot outcomes size equals: 1.
 self assert: snapshot audit values anyOne size equals: 1.
 self assert: snapshot journal values anyOne size equals: 1.
 recovered := owner operation: request operationId actor: alice generation: owner generation.
 self assert: recovered isSuccess. self assert: (recovered at: #digest) equals: request digest.
 self assert: (owner execute: request actor: alice) isSuccess.
 self assert: owner developmentSnapshot journal values anyOne size equals: 1
]

{ #category : 'tests' }
CGCoreTests >> testMemberCannotAdministerAndSuspendedMemberMayLeave [
 | group member result |
 group := self create. self assert: (self join: bob group: group) isSuccess.
 group := self group: group id. member := self member: bob group: group.
 result := self execute: 'InviteMember' body: { 0 -> group id. 1 -> casey asMap. 2 -> 60000 } asDictionary actor: bob group: group.
 self assert: result code equals: #NotAuthorised.
 self assert: (self execute: 'SuspendMember' body: (self entityBody: member group: group) actor: alice group: group) isSuccess.
 group := self group: group id. member := self member: bob group: group.
 self assert: (self execute: 'LeaveGroup' body: (self entityBody: member group: group) actor: bob group: group) isSuccess.
 self assert: (((self group: group id) at: #memberships) at: member id) state equals: #left
]

{ #category : 'tests' }
CGCoreTests >> testMissingGuardAndTerminalTransitionRefuse [
 self should: [ CGCoreContract transition: 'membership' from: 'absent' event: 'join' guards: Dictionary new ] raise: CGCoreRefusal.
 self should: [ CGCoreContract transition: 'membership' from: 'left' event: 'join' guards: Dictionary new ] raise: CGCoreRefusal
]

{ #category : 'tests' }
CGCoreTests >> testOfferWithdrawalRetainsHolderAndExpiresCleanly [
 | group member offer result |
 group := self create. self assert: (self join: bob group: group) isSuccess.
 group := self group: group id. member := self member: bob group: group.
 self assert: (self execute: 'TransferStewardship' body: { 0 -> group id. 1 -> member id. 2 -> member revision. 3 -> 60000 } asDictionary actor: alice group: group) isSuccess.
 group := self group: group id. offer := (group at: #offers) values anyOne.
 self assert: (self execute: 'WithdrawStewardshipOffer' body: (self entityBody: offer group: group) actor: alice group: group) isSuccess.
 group := self group: group id.
 self assert: (group at: #holder) equals: (self member: alice group: group) id.
 self assert: ((group at: #offers) at: offer id) state equals: #withdrawn.
 self assert: (self execute: 'TransferStewardship' body: { 0 -> group id. 1 -> member id. 2 -> member revision. 3 -> 60000 } asDictionary actor: alice group: group) isSuccess.
 clock advanceMillis: 60000. owner expireDevelopmentRecords.
 self assert: (((self group: group id) at: #offers) values count: [ :record | record state = #expired ]) equals: 1
]

{ #category : 'tests' }
CGCoreTests >> testOrphanedGovernance [
 self orphanedGovernance
]

{ #category : 'tests' }
CGCoreTests >> testPendingInvitationIsReturnedWithoutExtendingDeadline [
 | group first record revision second |
 group := self create. first := self invite: bob group: group.
 group := self group: group id. record := (group at: #invitations) values anyOne. revision := group revision.
 clock advanceMillis: 1000. second := self invite: bob group: group.
 self assert: (first at: #receipt) equals: (second at: #receipt).
 group := self group: group id.
 self assert: group revision equals: revision.
 self assert: (group at: #invitations) values anyOne id equals: record id.
 self assert: ((group at: #invitations) values anyOne at: #deadline) equals: (record at: #deadline)
]

{ #category : 'tests' }
CGCoreTests >> testPreparedCopiesCannotMutatePublishedHistoryOnRefusal [
 | group member revision before |
 group := self create. self assert: (self join: bob group: group) isSuccess.
 group := self group: group id. before := owner developmentSnapshot.
 member := self member: bob group: group.
 owner failAt: #beforePublication.
 self should: [ self execute: 'SuspendMember' body: (self entityBody: member group: group) actor: alice group: group ] raise: Error.
 group := self group: group id.
 self assert: (self member: bob group: group) state equals: #active.
 self assert: owner developmentSnapshot outcomes size equals: before outcomes size.
 self assert: (owner developmentSnapshot audit at: group id) size equals: (before audit at: group id) size.
 self assert: (owner developmentSnapshot journal at: group id) size equals: (before journal at: group id) size
]

{ #category : 'tests' }
CGCoreTests >> testPublishedOutcomeAfterLostReply [
 self publishedOutcomeAfterLostReply
]

{ #category : 'tests' }
CGCoreTests >> testRejoinedWithNewIncarnation [
 self rejoinedWithNewIncarnation
]

{ #category : 'tests' }
CGCoreTests >> testRemovedMembershipCannotResume [
 | group member result |
 group := self create. self assert: (self join: bob group: group) isSuccess.
 group := self group: group id. member := self member: bob group: group.
 self assert: (self execute: 'RemoveMember' body: (self entityBody: member group: group) actor: alice group: group) isSuccess.
 group := self group: group id. member := (group at: #memberships) at: member id.
 self assert: member state equals: #removed.
 result := self execute: 'ResumeMember' body: (self entityBody: member group: group) actor: alice group: group.
 self assert: result code equals: #GovernanceBlocked.
 self assert: (self join: bob group: group) isSuccess.
 self deny: (self member: bob group: (self group: group id)) id = member id
]

{ #category : 'tests' }
CGCoreTests >> testRequestTokenBucketAndRefill [
 | request result |
 request := self request: 'CreateGroup' body: { 0 -> 'Rate'. 1 -> 'open'. 2 -> 'discoverable'. 3 -> 4 } asDictionary group: nil.
 120 timesRepeat: [ self assert: (owner execute: request actor: alice) isSuccess ].
 result := owner execute: request actor: alice.
 self assert: result code equals: #Overloaded. self deny: (result at: #recorded).
 clock advanceMillis: 500.
 self assert: (owner execute: request actor: alice) isSuccess.
 self assert: owner developmentSnapshot groups size equals: 1
]

{ #category : 'tests' }
CGCoreTests >> testRestrictionInvalidatesPendingAdmissionWithoutRemovingMember [
 | group invitation result restriction |
 group := self create. self assert: (self join: bob group: group) isSuccess.
 group := self group: group id. self assert: (self invite: casey group: group) isSuccess.
 group := self group: group id. invitation := (group at: #invitations) values anyOne.
 result := self execute: 'SetAdmissionRestriction' body: { 0 -> group id. 1 -> casey asMap. 2 -> 60000 } asDictionary actor: alice group: group.
 self assert: result isSuccess. group := self group: group id.
 self assert: ((group at: #invitations) at: invitation id) state equals: #invalidated.
 self assert: (self join: casey group: group) code equals: #GovernanceBlocked.
 self assert: (self member: bob group: group) state equals: #active.
 restriction := (group at: #restrictions) values anyOne.
 self assert: (self execute: 'RemoveAdmissionRestriction' body: (self entityBody: restriction group: group) actor: alice group: group) isSuccess.
 group := self group: group id.
 self assert: (self join: casey group: group) isSuccess
]

{ #category : 'tests' }
CGCoreTests >> testRestrictionRenewalAndNewIncarnationAfterExpiry [
 | group first result current |
 group := self create.
 result := self execute: 'SetAdmissionRestriction' body: { 0 -> group id. 1 -> bob asMap. 2 -> 60000 } asDictionary actor: alice group: group.
 self assert: result isSuccess. first := (result at: #receipt) at: #entityId.
 clock advanceMillis: 1000. group := self group: group id.
 result := self execute: 'SetAdmissionRestriction' body: { 0 -> group id. 1 -> bob asMap. 2 -> 60000 } asDictionary actor: alice group: group.
 self assert: ((result at: #receipt) at: #entityId) equals: first.
 group := self group: group id. current := (group at: #restrictions) at: first.
 self assert: current revision equals: 2.
 clock advanceMillis: 60000. owner expireDevelopmentRecords.
 group := self group: group id.
 result := self execute: 'SetAdmissionRestriction' body: { 0 -> group id. 1 -> bob asMap. 2 -> 60000 } asDictionary actor: alice group: group.
 self assert: result isSuccess. self deny: ((result at: #receipt) at: #entityId) = first.
 self assert: (((self group: group id) at: #restrictions) at: first) state equals: #expired
]

{ #category : 'tests' }
CGCoreTests >> testRetainedMembershipIncarnationsAreNeverEvicted [
 | group member result |
 self timeLimit: 30 seconds.
 group := self createPolicy: 'open' capacity: 2.
 255 timesRepeat: [
  clock advanceMillis: 1000.
  group := self group: group id. result := self join: bob group: group.
  self assert: result isSuccess.
  group := self group: group id. member := self member: bob group: group.
  self assert: (self execute: 'LeaveGroup' body: (self entityBody: member group: group) actor: bob group: group) isSuccess ].
 group := self group: group id.
 self assert: (group at: #memberships) size equals: 256.
 result := self join: bob group: group.
 self assert: result code equals: #CapacityReached.
 self assert: ((self group: group id) at: #memberships) size equals: 256
]

{ #category : 'tests' }
CGCoreTests >> testRuntimeCapabilityCannotBindWrongService [
 self deny: (CGCoreCapability canBeGrantedToWorkUnitClass: CRStatisticsQueryTestWorkUnit).
 self deny: (CGCoreCapability canBeGrantedToServiceClass: CRWorkerService).
 self should: [ CRCapabilityResolver new capabilitiesForWorkUnit: CGCoreCommandWorkUnit new inWorker: CRWorkerQueueTestWorker new service: (CRWorkerService new start) ] raise: CRMissingCapabilityException
]

{ #category : 'tests' }
CGCoreTests >> testRuntimeNamedService [
 self runtimeNamedService
]

{ #category : 'tests' }
CGCoreTests >> testSameHolderCanRestoreButClosedMembershipCannot [
 | group source |
 group := self create. source := UUID new uuidData copy.
 owner applyDevelopmentFact: (identities fact: #baseline subject: alice revision: 1 generation: source sequence: 0).
 identities deny: alice revision: 2.
 owner applyDevelopmentFact: (identities fact: #restrict subject: alice revision: 2 generation: source sequence: 1).
 identities allow: alice revision: 3 authenticatedAt: clock currentMillis.
 owner applyDevelopmentFact: (identities fact: #eligible subject: alice revision: 3 generation: source sequence: 2).
 self assert: ((self group: group id) at: #governance) equals: #operational.
 identities deny: alice revision: 4.
 owner applyDevelopmentFact: (identities fact: #close subject: alice revision: 4 generation: source sequence: 3).
 identities allow: alice revision: 5 authenticatedAt: clock currentMillis.
 owner applyDevelopmentFact: (identities fact: #eligible subject: alice revision: 5 generation: source sequence: 4).
 self assert: ((self group: group id) at: #governance) equals: #recoveryRequired
]

{ #category : 'tests' }
CGCoreTests >> testStaleAndReplayedLifecycleFactsCannotRestoreClosedHolder [
 | group source fact |
 group := self create. source := UUID new uuidData copy.
 owner applyDevelopmentFact: (identities fact: #baseline subject: alice revision: 1 generation: source sequence: 0).
 identities deny: alice revision: 2.
 fact := identities fact: #close subject: alice revision: 2 generation: source sequence: 1.
 owner applyDevelopmentFact: fact.
 self should: [ owner applyDevelopmentFact: fact ] raise: CGCoreRefusal.
 identities allow: alice revision: 1 authenticatedAt: clock currentMillis.
 self assert: (owner applyDevelopmentFact: (identities fact: #eligible subject: alice revision: 1 generation: source sequence: 2)) equals: #stale.
 group := self group: group id.
 self assert: (group at: #governance) equals: #recoveryRequired.
 self assert: (group at: #holder) isNil.
 self assert: (self join: alice group: group) code equals: #DependencyUnavailable
]

{ #category : 'tests' }
CGCoreTests >> testStaleGroupRevisionRefusalIsStable [
 | group stale result |
 group := self create.
 stale := self request: 'InviteMember' body: { 0 -> group id. 1 -> bob asMap. 2 -> 60000 } asDictionary group: group.
 self assert: (self join: casey group: group) isSuccess.
 result := owner execute: stale actor: alice.
 self assert: result code equals: #RevisionConflict.
 self assert: (result at: #recorded).
 self assert: (owner execute: stale actor: alice) code equals: #RevisionConflict
]

{ #category : 'tests' }
CGCoreTests >> testStewardCannotLeaveSuspendOrRemoveSelf [
 | group member |
 group := self create. member := self member: alice group: group.
 #('LeaveGroup' 'SuspendMember' 'RemoveMember') do: [ :operation |
  self assert: (self execute: operation body: (self entityBody: member group: group) actor: alice group: group) code equals: #GovernanceBlocked ].
 self assert: (self group: group id) revision equals: 1
]

{ #category : 'tests' }
CGCoreTests >> testStopRestartRetainsGenerationResetFencesCommands [
 | group request generation |
 group := self create. generation := owner generation.
 request := self request: 'JoinOpenGroup' body: { 0 -> group id } asDictionary group: group.
 owner stop.
 self assert: (owner execute: request actor: bob) code equals: #DependencyUnavailable.
 owner start. self assert: owner generation equals: generation.
 self assert: (owner execute: request actor: bob) isSuccess.
 owner reset. self deny: owner generation = generation.
 self assert: (owner execute: request actor: bob) code equals: #ResyncRequired
]

{ #category : 'tests' }
CGCoreTests >> testStreamGapFencesCommandsUntilDevelopmentBaseline [
 | group source |
 group := self create. source := UUID new uuidData copy.
 owner applyDevelopmentFact: (identities fact: #baseline subject: alice revision: 1 generation: source sequence: 0).
 self should: [ owner applyDevelopmentFact: (identities fact: #restrict subject: alice revision: 2 generation: source sequence: 2) ] raise: CGCoreRefusal.
 self assert: (self join: bob group: group) code equals: #DependencyUnavailable.
 owner applyDevelopmentFact: (identities fact: #baseline subject: alice revision: 1 generation: source sequence: 2).
 self assert: (self join: bob group: group) isSuccess
]

{ #category : 'tests' }
CGCoreTests >> testSuspendedThenResumed [
 self suspendedThenResumed
]

{ #category : 'tests' }
CGCoreTests >> testTamperedLifecycleFactCannotRetarget [
 | group source fact |
 group := self create. source := UUID new uuidData copy.
 owner applyDevelopmentFact: (identities fact: #baseline subject: alice revision: 1 generation: source sequence: 0).
 fact := identities fact: #close subject: bob revision: 2 generation: source sequence: 1.
 fact at: #subject put: alice.
 self should: [ owner applyDevelopmentFact: fact ] raise: CGCoreRefusal.
 self assert: ((self group: group id) at: #governance) equals: #operational
]

{ #category : 'tests' }
CGCoreTests >> testTermChangeInvalidatesInvitationsButNameChangeDoesNot [
 | group invitation result |
 group := self create. self assert: (self invite: bob group: group) isSuccess.
 group := self group: group id. invitation := (group at: #invitations) values anyOne.
 result := self execute: 'UpdateGroup' body: { 0 -> group id. 1 -> 'Renamed'. 2 -> 'open'. 3 -> 'discoverable'. 4 -> 4 } asDictionary actor: alice group: group.
 self assert: result isSuccess. group := self group: group id.
 self assert: ((group at: #invitations) at: invitation id) state equals: #pending.
 result := self execute: 'UpdateGroup' body: { 0 -> group id. 1 -> 'Renamed'. 2 -> 'application'. 3 -> 'discoverable'. 4 -> 4 } asDictionary actor: alice group: group.
 self assert: result isSuccess.
 self assert: (((self group: group id) at: #invitations) at: invitation id) state equals: #invalidated
]

{ #category : 'tests' }
CGCoreTests >> testTrustedDevelopmentClosureCanEndOrphanedGroup [
 | group source |
 group := self create. self assert: (self join: bob group: group) isSuccess.
 source := UUID new uuidData copy.
 owner applyDevelopmentFact: (identities fact: #baseline subject: alice revision: 1 generation: source sequence: 0).
 identities deny: alice revision: 2.
 owner applyDevelopmentFact: (identities fact: #close subject: alice revision: 2 generation: source sequence: 1).
 owner applyDevelopmentFact: (identities groupFact: #trustedClose group: group id generation: source sequence: 2 cleanupConfirmed: false).
 group := self group: group id.
 self assert: group state equals: #dissolving.
 self assert: (group at: #governance) equals: #closed.
 self assert: ((group at: #memberships) values allSatisfy: [ :member | member state = #removed ]).
 owner applyDevelopmentFact: (identities groupFact: #finalize group: group id generation: source sequence: 3 cleanupConfirmed: true).
 self assert: (self group: group id) state equals: #dissolved
]

{ #category : 'tests' }
CGCoreTests >> testUnavailableIdentityFailsClosedWithoutReservation [
 | group request result |
 group := self create. request := self request: 'JoinOpenGroup' body: { 0 -> group id } asDictionary group: group.
 identities unavailable: bob.
 result := owner execute: request actor: bob.
 self assert: result code equals: #DependencyUnavailable. self deny: (result at: #recorded).
 identities allow: bob.
 self assert: (owner execute: request actor: bob) isSuccess
]

{ #category : 'tests' }
CGCoreTests >> testUnknownQueryFeatureIsNotReserved [
 | request result |
 request := self request: 'GetGroupSummary' body: { 0 -> UUID new uuidData copy } asDictionary group: nil.
 result := owner execute: request actor: alice.
 self assert: result code equals: #NotSupported.
 self deny: (result at: #recorded).
 self assert: owner developmentSnapshot outcomes isEmpty
]

{ #category : 'tests' }
CGCoreTests >> testWrongActorCannotAcceptInvitation [
 | group invitation result |
 group := self create. self assert: (self invite: bob group: group) isSuccess.
 group := self group: group id. invitation := (group at: #invitations) values anyOne.
 result := self execute: 'AcceptInvitation' body: (self entityBody: invitation group: group) actor: casey group: group.
 self assert: result code equals: #NotAuthorised.
 self deny: (result at: #recorded)
]
