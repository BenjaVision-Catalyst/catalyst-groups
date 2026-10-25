"
Runtime service for the local P1 development core. Requires explicit development-identity configuration before start. Exports only its narrow command capability; stop retires execution while retaining in-memory state. Real Users/Connect and asynchronous invocation integration are later gates.
"
Class {
	#name : 'CGCoreService',
	#superclass : 'CRWorkerService',
	#instVars : [
		'owner'
	],
	#category : 'Catalyst-Groups-Runtime',
	#package : 'Catalyst-Groups-Runtime'
}

{ #category : 'development' }
CGCoreService >> configureDevelopmentIdentities: adapter clock: aClock [
 owner ifNotNil: [ self error: 'Groups owner is already configured' ].
 owner := CGCoreOwner identities: adapter clock: aClock
]

{ #category : 'development' }
CGCoreService >> developmentGeneration [
 ^ owner generation
]

{ #category : 'development' }
CGCoreService >> executeDevelopmentRequest: request actor: actor [
 ^ owner execute: request actor: actor
]

{ #category : 'lifecycle' }
CGCoreService >> start [
 owner ifNil: [ self error: 'P1 requires an explicitly configured development identity adapter' ].
 super start. owner start.
 self provideCapability: CGCoreCapability instance: (CGCoreCapability service: self).
 ^ self
]

{ #category : 'lifecycle' }
CGCoreService >> stop [
 owner ifNotNil: [ owner stop ]. ^ super stop
]
