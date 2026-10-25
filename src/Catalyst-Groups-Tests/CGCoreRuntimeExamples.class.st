"
Actual three-worker queue-backed development invocation examples. Synthetic identity decisions; no real Users authentication, Connect or native persistence claim.
"
Class {
	#name : 'CGCoreRuntimeExamples',
	#superclass : 'CGCoreExamples',
	#instVars : [
		'runtime',
		'workers',
		'ingress',
		'groups',
		'users',
		'bridge'
	],
	#category : 'Catalyst-Groups-Tests',
	#package : 'Catalyst-Groups-Tests'
}

{ #category : 'tests' }
CGCoreRuntimeExamples >> asynchronousCreation [
 <gtExample>
 ^ self withRuntimeDo: [
  | unit |
  unit := ingress submitDevelopmentRequest: self runtimeCreateRequest actor: alice.
  self assert: unit result isNil.
  workers second driveOne.
  self assert: unit result isNil.
  self assert: (bridge diagnostics at: #pending) equals: 1.
  self assert: workers third workerHandle workQueue depth equals: 1.
  workers third driveOne.
  self assert: unit result isNil.
  workers second driveOne.
  self assert: unit result code equals: #Success.
  self assert: (bridge diagnostics at: #inputs) equals: 0.
  self assert: (bridge diagnostics at: #decisionsIssued) equals: 1.
  unit result ]
]

{ #category : 'tests' }
CGCoreRuntimeExamples >> asynchronousMembershipAndGovernance [
 <gtExample>
 ^ self withRuntimeDo: [
  | group result invitation successor offer |
  group := self runtimeCreate.
  result := self runtimeExecute: (self runtimeRequest: 'InviteMember' body: { 0 -> group id. 1 -> bob asMap. 2 -> 60000 } asDictionary group: group) actor: alice.
  self assert: result isSuccess.
  group := groups developmentGroup: group id. invitation := (group at: #invitations) values anyOne.
  result := self runtimeExecute: (self runtimeRequest: 'AcceptInvitation' body: (self entityBody: invitation group: group) group: group) actor: bob.
  self assert: result isSuccess. group := groups developmentGroup: group id.
  successor := self member: bob group: group.
  result := self runtimeExecute: (self runtimeRequest: 'TransferStewardship' body: {0 -> group id. 1 -> successor id. 2 -> successor revision. 3 -> 60000} asDictionary group: group) actor: alice.
  self assert: result isSuccess. group := groups developmentGroup: group id.
  self assert: (group at: #holder) equals: (self member: alice group: group) id.
  offer := (group at: #offers) values anyOne.
  result := self runtimeExecute: (self runtimeRequest: 'AcceptStewardship' body: (self entityBody: offer group: group) group: group) actor: bob.
  self assert: result isSuccess. group := groups developmentGroup: group id.
  self assert: (group at: #holder) equals: successor id.
  group ]
]

{ #category : 'development' }
CGCoreRuntimeExamples >> drainRuntime [
 | progressed before |
 before := workers collect: [ :worker | worker workerHandle failedWorkUnitExecutions size ].
 [ progressed := false.
  workers do: [ :worker | worker driveOne ifTrue: [ progressed := true ] ].
  progressed ] whileTrue.
 self assert: (workers collect: [ :worker | worker workerHandle failedWorkUnitExecutions size ]) equals: before
]

{ #category : 'tests' }
CGCoreRuntimeExamples >> expiredDecisionCannotCompleteReplacement [
 <gtExample>
 ^ self withRuntimeDo: [
  | request old replacement |
  request := self runtimeCreateRequest.
  old := ingress submitDevelopmentRequest: request actor: alice.
  workers second driveOne. workers third driveOne.
  clock currentMillis: 6000. bridge expireInvocations.
  self assert: old result code equals: #DependencyUnavailable.
  replacement := ingress submitDevelopmentRequest: request actor: alice.
  self drainRuntime.
  self assert: replacement result code equals: #Success.
  self assert: old result code equals: #DependencyUnavailable.
  self assert: (bridge diagnostics at: #inputs) equals: 0.
  replacement result ]
]

{ #category : 'tests' }
CGCoreRuntimeExamples >> runtimeCreate [
 | result |
 result := self runtimeExecute: self runtimeCreateRequest actor: alice.
 self assert: result isSuccess.
 ^ groups developmentGroup: ((result at: #receipt) at: #groupId)
]

{ #category : 'tests' }
CGCoreRuntimeExamples >> runtimeCreateRequest [
 ^ self runtimeRequest: 'CreateGroup' body: { 0 -> 'Async Group'. 1 -> 'open'. 2 -> 'discoverable'. 3 -> 4 } asDictionary group: nil
]

{ #category : 'tests' }
CGCoreRuntimeExamples >> runtimeExecute: request actor: actor [
 | unit |
 unit := ingress submitDevelopmentRequest: request actor: actor.
 self drainRuntime.
 ^ unit result
]

{ #category : 'tests' }
CGCoreRuntimeExamples >> runtimeRequest: name body: body group: group [
 | original payload |
 original := self request: name body: body group: group.
 payload := original payload. payload at: 1 put: groups developmentGeneration.
 ^ CGCoreRequest operation: name payload: payload
]

{ #category : 'tests' }
CGCoreRuntimeExamples >> withRuntimeDo: block [
 self setUp.
 runtime := CRRuntime new.
 workers := { CRRoutingTestWorker new. CRRoutingTestWorker new. CRRoutingTestWorker new }.
 workers withIndexDo: [ :worker :index |
  worker workerHandle workerIdentifier: ('groups-p1-', index asString) asSymbol.
  worker bindRuntime: runtime hostIdentifier: #localhost.
  worker clock: clock ].
 bridge := CGDevelopmentRuntimeBridge new identities: identities clock: clock.
 [
  ingress := workers first services installServiceClass: CGDevelopmentIngressService serviceIdentifier: 'ingress' configuration: CRServiceConfiguration default.
  groups := workers second services installServiceClass: CGCoreService serviceIdentifier: 'groups' configuration: CRServiceConfiguration default.
  users := workers third services installServiceClass: CGDevelopmentUsersService serviceIdentifier: 'users' configuration: CRServiceConfiguration default.
  ingress bridge: bridge. users bridge: bridge.
  groups configureDevelopmentIdentities: identities clock: clock; configureDevelopmentBridge: bridge.
  workers do: [ :worker | worker start ].
  ^ block value
 ] ensure: [
  bridge retireAll.
  workers do: [ :worker | [ worker driveOne ] whileTrue ].
  workers reverseDo: [ :worker | worker stopAndUninstallServices. worker unpublishHandleFromTopology ] ]
]
