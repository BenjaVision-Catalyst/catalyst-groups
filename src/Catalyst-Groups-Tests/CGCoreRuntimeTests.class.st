"
Adversarial Runtime invocation and callback lifecycle tests for the P1 development bridge.
"
Class {
	#name : 'CGCoreRuntimeTests',
	#superclass : 'CGCoreRuntimeExamples',
	#category : 'Catalyst-Groups-Tests',
	#package : 'Catalyst-Groups-Tests'
}

{ #category : 'tests' }
CGCoreRuntimeTests >> testAdmissionPolicyUsesUsersDecisionWithoutRelationshipData [
 self withRuntimeDo: [
  | group result |
  group := self runtimeCreate.
  identities contact: false for: bob.
  result := self runtimeExecute: (self runtimeRequest: 'JoinOpenGroup' body: {0 -> group id} asDictionary group: group) actor: bob.
  self assert: result code equals: #NotAuthorised.
  self deny: (result at: #recorded).
  result := self runtimeExecute: (self runtimeRequest: 'UpdateGroup' body: {0 -> group id. 1 -> 'Applications'. 2 -> 'application'. 3 -> 'discoverable'. 4 -> 4} asDictionary group: group) actor: alice.
  self assert: result isSuccess. group := groups developmentGroup: group id.
  result := self runtimeExecute: (self runtimeRequest: 'ApplyToJoin' body: {0 -> group id} asDictionary group: group) actor: bob.
  self assert: result code equals: #NotAuthorised.
  self assert: ((groups developmentGroup: group id) at: #applications) isEmpty ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testAsynchronousCreation [
 self asynchronousCreation
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testAsynchronousMembershipAndGovernance [
 self asynchronousMembershipAndGovernance
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testBeforePublicationFailureLeavesNoOutcomeAndCanRetryAfterRetirement [
 self withRuntimeDo: [
  | request result |
  request := self runtimeCreateRequest.
  groups failDevelopmentAt: #beforePublication.
  result := self runtimeExecute: request actor: alice.
  self assert: result code equals: #OutcomeUnknown.
  self assert: groups developmentSnapshot groups isEmpty.
  self assert: groups developmentSnapshot outcomes isEmpty.
  self assert: (bridge diagnostics at: #inputs) equals: 0.
  groups failDevelopmentAt: nil.
  result := self runtimeExecute: request actor: alice.
  self assert: result isSuccess ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testClockFaultAndGenerationRetirePendingDecisions [
 self withRuntimeDo: [
  | unit |
  unit := ingress submitDevelopmentRequest: self runtimeCreateRequest actor: alice.
  workers second driveOne. workers third driveOne.
  clock currentMillis: 999.
  self drainRuntime.
  self assert: unit result code equals: #DependencyUnavailable.
  bridge resetDevelopmentClock.
  clock currentMillis: 1000.
  unit := ingress submitDevelopmentRequest: self runtimeCreateRequest actor: alice.
  self drainRuntime.
  self assert: unit result code equals: #Success ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testConcurrentRevisionsAreRecheckedAfterUsersDecision [
 self withRuntimeDo: [
  | group request first second |
  group := self runtimeCreate.
  request := self runtimeRequest: 'UpdateGroup' body: {0 -> group id. 1 -> 'Updated'. 2 -> 'open'. 3 -> 'discoverable'. 4 -> 4} asDictionary group: group.
  first := ingress submitDevelopmentRequest: request actor: alice.
  request := CGCoreRequest operation: request operation payload: (request payload at: 0 put: UUID new uuidData; yourself).
  second := ingress submitDevelopmentRequest: request actor: alice.
  workers second driveOne. workers second driveOne.
  workers third driveOne. workers third driveOne.
  self drainRuntime.
  self assert: first result isSuccess.
  self assert: second result code equals: #RevisionConflict.
  self assert: (second result at: #recorded).
  self assert: (groups developmentGroup: group id) revision equals: group revision + 1 ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testCopiedDecisionCannotPublish [
 self withRuntimeDo: [
  | original unit |
  unit := ingress submitDevelopmentRequest: self runtimeCreateRequest actor: alice.
  workers second driveOne. workers third driveOne.
  original := workers second nextEnvelopeOrNil.
  workers second executeWorkUnitInEnvelope: (original copyForRouting workUnit: original workUnit copy; yourself).
  self assert: unit result isNil.
  workers second executeWorkUnitInEnvelope: original.
  self assert: unit result isSuccess ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testCopiedUsersCheckCannotIssueDecision [
 self withRuntimeDo: [
  | original unit |
  unit := ingress submitDevelopmentRequest: self runtimeCreateRequest actor: alice.
  workers second driveOne. original := workers third nextEnvelopeOrNil.
  workers third executeWorkUnitInEnvelope: (original copyForRouting workUnit: original workUnit copy; yourself).
  self assert: (bridge diagnostics at: #decisionsIssued) equals: 0.
  workers third executeWorkUnitInEnvelope: original.
  self drainRuntime. self assert: unit result isSuccess ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testCopiedWorkHasNoRegisteredAuthority [
 self withRuntimeDo: [
  | unit envelope copy |
  unit := ingress submitDevelopmentRequest: self runtimeCreateRequest actor: alice.
  envelope := workers second nextEnvelopeOrNil.
  copy := unit copy.
  envelope workUnit: copy.
  workers second executeWorkUnitInEnvelope: envelope.
  self assert: copy result code equals: #NotAuthorised.
  self assert: workers third workerHandle workQueue depth equals: 0.
  bridge retireAll.
  self assert: unit result code equals: #DependencyUnavailable ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testCurrentIdentityDecisionIsMadeAsynchronously [
 self withRuntimeDo: [
  | unit |
  unit := ingress submitDevelopmentRequest: self runtimeCreateRequest actor: alice.
  workers second driveOne.
  identities deny: alice revision: 2.
  self drainRuntime.
  self assert: unit result code equals: #NotAuthorised.
  self deny: (unit result at: #recorded).
  self assert: (bridge diagnostics at: #inputs) equals: 0 ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testDeniedContactAndExpiredAssuranceCannotPublish [
 self withRuntimeDo: [
  | group request result successor |
  group := self runtimeCreate.
  identities contact: false for: bob.
  result := self runtimeExecute: (self runtimeRequest: 'InviteMember' body: {0 -> group id. 1 -> bob asMap. 2 -> 60000} asDictionary group: group) actor: alice.
  self assert: result code equals: #NotAuthorised.
  self deny: (result at: #recorded).
  identities contact: true for: bob.
  result := self runtimeExecute: (self runtimeRequest: 'JoinOpenGroup' body: {0 -> group id} asDictionary group: group) actor: bob.
  self assert: result isSuccess.
  group := groups developmentGroup: group id. successor := self member: bob group: group.
  clock currentMillis: 301001.
  request := self runtimeRequest: 'TransferStewardship' body: {0 -> group id. 1 -> successor id. 2 -> successor revision. 3 -> 60000} asDictionary group: group.
  result := self runtimeExecute: request actor: alice.
  self assert: result code equals: #AssuranceRequired.
  self deny: (result at: #recorded).
  identities allow: alice revision: 1 authenticatedAt: 301001.
  result := self runtimeExecute: request actor: alice.
  self assert: result isSuccess ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testExpiredDecisionCannotCompleteReplacement [
 self expiredDecisionCannotCompleteReplacement
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testFiniteAdmissionHasNoUnboundedRegistry [
 self withRuntimeDo: [
  | units rejected |
  units := (1 to: 64) collect: [ :each | ingress submitDevelopmentRequest: self runtimeCreateRequest actor: alice ].
  rejected := ingress submitDevelopmentRequest: self runtimeCreateRequest actor: alice.
  self assert: rejected result code equals: #Overloaded.
  self assert: (bridge diagnostics at: #inputs) equals: 64.
  bridge retireAll. self drainRuntime.
  self assert: (bridge diagnostics at: #inputs) equals: 0.
  units do: [ :unit | self assert: unit result code equals: #DependencyUnavailable ] ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testInvocationDeadlineCannotOverflowTheBusinessClockRange [
 self withRuntimeDo: [
  | unit |
  clock currentMillis: 18446744073709551615.
  unit := ingress submitDevelopmentRequest: self runtimeCreateRequest actor: alice.
  self assert: unit result code equals: #DependencyUnavailable.
  self assert: workers second workerHandle workQueue depth equals: 0.
  self assert: (bridge diagnostics at: #inputs) equals: 0 ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testInvocationExpiryIsCheckedAtThePublicationBoundary [
 self setUp.
 owner := CGCoreDeadlineProbeOwner identities: identities clock: clock.
 self assert: (owner execute: (self request: 'CreateGroup' body: {0 -> 'Expiry'. 1 -> 'open'. 2 -> 'discoverable'. 3 -> 4} asDictionary group: nil)
  actor: alice usingDecisions: (identities copyDecisionsFor: {alice}) deadline: 6000) code equals: #DependencyUnavailable.
 self assert: owner developmentSnapshot groups isEmpty.
 self assert: owner developmentSnapshot outcomes isEmpty
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testObservedLifecycleRestrictionRetiresPendingAuthority [
 self withRuntimeDo: [
  | group unit sourceGeneration |
  group := self runtimeCreate.
  unit := ingress submitDevelopmentRequest: (self runtimeRequest: 'InviteMember' body: {0 -> group id. 1 -> bob asMap. 2 -> 60000} asDictionary group: group) actor: alice.
  workers second driveOne. workers third driveOne.
  sourceGeneration := UUID new uuidData.
  groups applyDevelopmentFact: (identities fact: #baseline subject: alice revision: 1 generation: sourceGeneration sequence: 0).
  identities deny: alice revision: 2.
  groups applyDevelopmentFact: (identities fact: #restrict subject: alice revision: 2 generation: sourceGeneration sequence: 1).
  self drainRuntime.
  self assert: unit result code equals: #DependencyUnavailable.
  self assert: ((groups developmentGroup: group id) at: #invitations) isEmpty ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testPendingDuplicatesShareOneDecisionAndConflictsDoNotReplaceIt [
 self withRuntimeDo: [
  | request a b conflict payload |
  request := self runtimeCreateRequest.
  a := ingress submitDevelopmentRequest: request actor: alice.
  b := ingress submitDevelopmentRequest: request actor: alice.
  payload := request payload. (payload at: 4) at: 0 put: 'Different intent'.
  conflict := ingress submitDevelopmentRequest: (CGCoreRequest operation: request operation payload: payload) actor: alice.
  workers second driveOne. workers second driveOne. workers second driveOne.
  self assert: conflict result code equals: #OperationConflict.
  self assert: workers third workerHandle workQueue depth equals: 1.
  self drainRuntime.
  #(code receipt digest recorded generation id) do: [ :key | self assert: (a result at: key) equals: (b result at: key) ].
  self assert: (bridge diagnostics at: #decisionsIssued) equals: 1 ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testReplyLossAfterPublicationRemainsUnknownAndLookupRecovers [
 self withRuntimeDo: [
  | request unit result |
  request := self runtimeCreateRequest. groups failDevelopmentAt: #afterPublication.
  unit := ingress submitDevelopmentRequest: request actor: alice.
  self drainRuntime.
  self assert: unit result code equals: #OutcomeUnknown.
  result := groups developmentOperation: request operationId actor: alice generation: request generation.
  self assert: result isSuccess.
  self assert: (result at: #digest) equals: request digest.
  groups failDevelopmentAt: nil.
  result := self runtimeExecute: request actor: alice.
  self assert: result isSuccess.
  self assert: (groups developmentSnapshot groups size) equals: 1 ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testResetFencesOldGenerationAndCallback [
 self withRuntimeDo: [
  | unit oldRequest retry |
  oldRequest := self runtimeCreateRequest.
  unit := ingress submitDevelopmentRequest: oldRequest actor: alice.
  workers second driveOne. workers third driveOne.
  groups resetDevelopmentState.
  self drainRuntime.
  self assert: unit result code equals: #DependencyUnavailable.
  retry := ingress submitDevelopmentRequest: oldRequest actor: alice.
  self drainRuntime.
  self assert: retry result code equals: #ResyncRequired ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testRuntimeRecoveryAfterGenerationLossReportsUnavailableHistory [
 self withRuntimeDo: [
  | mutation query result |
  mutation := self runtimeCreateRequest.
  result := self runtimeExecute: mutation actor: alice. self assert: result isSuccess.
  query := self runtimeRequest: 'GetOperationResult' body: {0 -> mutation operationId} asDictionary group: nil.
  groups resetDevelopmentState.
  result := self runtimeExecute: query actor: alice.
  self assert: result code equals: #OutcomeUnavailable.
  self assert: groups developmentSnapshot outcomes isEmpty ]
]

{ #category : 'execution' }
CGCoreRuntimeTests >> testRuntimeRecoveryIsScopedAndDoesNotCreateMutationOutcomes [
 self withRuntimeDo: [
  | request result query |
  request := self runtimeCreateRequest.
  result := self runtimeExecute: request actor: alice. self assert: result isSuccess.
  query := self runtimeRequest: 'GetOperationResult' body: {0 -> request operationId} asDictionary group: nil.
  result := self runtimeExecute: query actor: alice.
  self assert: result isSuccess. self assert: (result at: #digest) equals: request digest.
  self assert: groups developmentSnapshot outcomes size equals: 1.
  result := self runtimeExecute: query actor: bob.
  self assert: result code equals: #OutcomeUnavailable.
  self assert: groups developmentSnapshot outcomes size equals: 1 ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testStopRetiresCallbacksBeforeRestart [
 self withRuntimeDo: [
  | old request retry |
  request := self runtimeCreateRequest.
  old := ingress submitDevelopmentRequest: request actor: alice.
  workers second driveOne. workers third driveOne.
  workers second services stopAll.
  self assert: old result code equals: #DependencyUnavailable.
  self assert: workers second driveOne.
  self assert: workers second workerHandle failedWorkUnitExecutions size equals: 1.
  workers second services startAll.
  retry := ingress submitDevelopmentRequest: request actor: alice.
  self drainRuntime.
  self assert: retry result code equals: #Success.
  self assert: old result code equals: #DependencyUnavailable ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testStoppedOriginCannotIntroduceNewAuthority [
 self withRuntimeDo: [
  | unit |
  unit := ingress submitDevelopmentRequest: self runtimeCreateRequest actor: alice.
  ingress stop.
  workers second driveOne.
  self assert: unit result code equals: #NotAuthorised.
  self assert: (bridge diagnostics at: #decisionsIssued) equals: 0 ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testUnavailableUsersCanBeRetriedOnlyAfterPositiveRetirement [
 self withRuntimeDo: [
  | request first retry |
  request := self runtimeCreateRequest.
  identities unavailable: alice.
  first := ingress submitDevelopmentRequest: request actor: alice.
  self drainRuntime.
  self assert: first result code equals: #DependencyUnavailable.
  identities allow: alice.
  retry := ingress submitDevelopmentRequest: request actor: alice.
  self drainRuntime.
  self assert: retry result code equals: #Success ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testUnregisteredAndCallerSelectedActorPathAreRefused [
 self withRuntimeDo: [
  | unit |
  unit := CGCoreInvocationWorkUnit new.
  workers second executeWorkUnitInEnvelope: ((CRWorkUnitEnvelope onWorkUnit: unit) serviceIdentifier: 'groups'; yourself).
  self assert: unit result code equals: #NotAuthorised.
  unit := CGCoreCommandWorkUnit new request: self runtimeCreateRequest actor: alice.
  workers second executeWorkUnitInEnvelope: ((CRWorkUnitEnvelope onWorkUnit: unit) serviceIdentifier: 'groups'; yourself).
  self assert: unit result code equals: #NotAuthorised.
  self assert: (bridge diagnostics at: #decisionsIssued) equals: 0 ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testUnverifiedEnvelopeCannotUseRegisteredInput [
 self withRuntimeDo: [
  | unit original |
  unit := ingress submitDevelopmentRequest: self runtimeCreateRequest actor: alice.
  original := workers second nextEnvelopeOrNil.
  workers second executeWorkUnitInEnvelope: ((CRWorkUnitEnvelope onWorkUnit: unit) serviceIdentifier: 'groups'; yourself).
  self assert: unit result code equals: #NotAuthorised.
  workers second executeWorkUnitInEnvelope: original.
  self assert: (bridge diagnostics at: #decisionsIssued) equals: 0 ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testWrongCallbackOriginCannotPublish [
 self withRuntimeDo: [
  | unit callback forged original |
  unit := ingress submitDevelopmentRequest: self runtimeCreateRequest actor: alice.
  workers second driveOne. workers third driveOne.
  original := workers second nextEnvelopeOrNil.
  callback := original workUnit.
  forged := CRWorkUnitEnvelope onWorkUnit: callback.
  forged serviceIdentifier: 'groups'.
  workers second executeWorkUnitInEnvelope: forged.
  self assert: unit result code equals: #NotAuthorised.
  workers second executeWorkUnitInEnvelope: original.
  self assert: (bridge diagnostics at: #inputs) equals: 0 ]
]

{ #category : 'tests' }
CGCoreRuntimeTests >> testWrongDestinationAndStaleOriginActivationAreRefused [
 self withRuntimeDo: [
  | unit original |
  unit := ingress submitDevelopmentRequest: self runtimeCreateRequest actor: alice.
  original := workers second nextEnvelopeOrNil.
  original serviceIdentifier: 'another-groups-service'.
  workers second executeWorkUnitInEnvelope: original.
  self assert: unit result isNil.
  ingress stop.
  bridge expireInvocations.
  clock currentMillis: 6000. bridge expireInvocations.
  self assert: unit result code equals: #DependencyUnavailable.
  self assert: (bridge diagnostics at: #inputs) equals: 0 ]
]
