"
Trusted test composition entry point for synthetic actors. Issues identity-registered work through real Runtime observed routing. This service is deliberately not an authenticated Connect ingress.
"
Class {
	#name : 'CGDevelopmentIngressService',
	#superclass : 'CRWorkerService',
	#instVars : [
		'port',
		'bridge'
	],
	#category : 'Catalyst-Groups-Development',
	#package : 'Catalyst-Groups-Development'
}

{ #category : 'development' }
CGDevelopmentIngressService class >> requiredCapabilities [
 ^ { CRServiceActivationCapability }
]

{ #category : 'development' }
CGDevelopmentIngressService >> bridge: aBridge [
 bridge := aBridge
]

{ #category : 'development' }
CGDevelopmentIngressService >> continueStopping [
 self hasPendingStop ifFalse: [ super stop ]. ^ self
]

{ #category : 'development' }
CGDevelopmentIngressService >> hasPendingStop [
 ^ port notNil and: [ port count > 0 ]
]

{ #category : 'development' }
CGDevelopmentIngressService >> requiresStopProgress [
 ^ true
]

{ #category : 'lifecycle' }
CGDevelopmentIngressService >> start [
 super start.
 port := self capability: CRServiceActivationCapability.
 port activateRecords: 64 bytes: 262144.
 bridge registerPort: port role: #ingress.

 ^ self
]

{ #category : 'development' }
CGDevelopmentIngressService >> stop [
 port ifNotNil: [ port deactivate ]. ^ self continueStopping
]

{ #category : 'development' }
CGDevelopmentIngressService >> submitDevelopmentRequest: request actor: actor [
 ^ bridge issue: request actor: actor
]
