"
GT/Pharo Groups Runtime service. A narrow local fixture path is available without a bridge. When configured, the explicit development bridge requires exact originating Runtime submission and asynchronous U1/U2/U3 fixture decisions; caller-selected actor WorkUnits are refused. Stop retires invocations and waits for routed ownership before a new activation. Real Users/Connect authentication remains P2/P3.
"
Class {
	#name : 'CGCoreService',
	#superclass : 'CRWorkerService',
	#instVars : [
		'owner',
		'developmentBridge',
		'invocationPort'
	],
	#category : 'Catalyst-Groups-Runtime',
	#package : 'Catalyst-Groups-Runtime'
}

{ #category : 'development' }
CGCoreService class >> requiredCapabilities [
 ^ { CRServiceActivationCapability }
]

{ #category : 'development inspection' }
CGCoreService >> applyDevelopmentFact: fact [
 | result | result := owner applyDevelopmentFact: fact. developmentBridge ifNotNil: [ developmentBridge retireAll ]. ^ result
]

{ #category : 'development' }
CGCoreService >> beginDevelopmentInvocation: unit context: context [
 developmentBridge ifNil: [ ^ unit completeWith: (owner outcomeCode: #NotAuthorised recorded: false retryable: false) ].
 ^ developmentBridge begin: unit context: context owner: owner
]

{ #category : 'development' }
CGCoreService >> completeDevelopmentInvocation: unit context: context [
 developmentBridge ifNil: [ ^ #ignored ].
 ^ developmentBridge complete: unit context: context owner: owner
]

{ #category : 'development' }
CGCoreService >> configureDevelopmentBridge: aBridge [
 developmentBridge ifNotNil: [ self error: 'Bridge already configured' ].
 developmentBridge := aBridge
]

{ #category : 'development' }
CGCoreService >> configureDevelopmentIdentities: adapter clock: aClock [
 owner ifNotNil: [ self error: 'Groups owner is already configured' ].
 owner := CGCoreOwner identities: adapter clock: aClock
]

{ #category : 'development' }
CGCoreService >> continueStopping [
 self hasPendingStop ifFalse: [ super stop ]. ^ self
]

{ #category : 'development' }
CGCoreService >> developmentGeneration [
 ^ owner generation
]

{ #category : 'development inspection' }
CGCoreService >> developmentGroup: identifier [
 ^ owner developmentGroup: identifier
]

{ #category : 'development inspection' }
CGCoreService >> developmentOperation: operationId actor: actor generation: generation [
 ^ owner operation: operationId actor: actor generation: generation
]

{ #category : 'development inspection' }
CGCoreService >> developmentSnapshot [
 ^ owner developmentSnapshot
]

{ #category : 'development' }
CGCoreService >> executeDevelopmentRequest: request actor: actor [
 developmentBridge ifNotNil: [ ^ owner outcomeCode: #NotAuthorised recorded: false retryable: false ].
 ^ owner execute: request actor: actor
]

{ #category : 'development inspection' }
CGCoreService >> failDevelopmentAt: point [
 owner failAt: point
]

{ #category : 'development' }
CGCoreService >> hasPendingStop [
 ^ invocationPort notNil and: [ invocationPort count > 0 ]
]

{ #category : 'development' }
CGCoreService >> requiresStopProgress [
 ^ true
]

{ #category : 'development' }
CGCoreService >> resetDevelopmentState [
 owner reset.
 developmentBridge ifNotNil: [ developmentBridge retireAll ]
]

{ #category : 'lifecycle' }
CGCoreService >> start [
 owner ifNil: [ self error: 'Explicit development identity configuration required' ].
 super start. owner start.
 developmentBridge ifNotNil: [
  invocationPort := self capability: CRServiceActivationCapability.
  invocationPort activateRecords: 64 bytes: 262144.
  developmentBridge registerPort: invocationPort role: #groups ].
 self provideCapability: CGCoreCapability instance: (CGCoreCapability service: self).
 ^ self
]

{ #category : 'development' }
CGCoreService >> stop [
 owner ifNotNil: [ owner stop ].
 developmentBridge ifNotNil: [ developmentBridge retireAll ].
 invocationPort ifNotNil: [ invocationPort deactivate ].
 ^ self continueStopping
]
