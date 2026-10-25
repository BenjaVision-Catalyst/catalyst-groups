"
Development U1/U2/U3 decision source over actual asynchronous Runtime work. Copies only required synthetic eligibility/contact/assurance records; actual Users and session security remain P2/P3.
"
Class {
	#name : 'CGDevelopmentUsersService',
	#superclass : 'CRWorkerService',
	#instVars : [
		'port',
		'bridge'
	],
	#category : 'Catalyst-Groups-Development',
	#package : 'Catalyst-Groups-Development'
}

{ #category : 'development' }
CGDevelopmentUsersService class >> requiredCapabilities [
 ^ { CRServiceActivationCapability }
]

{ #category : 'development' }
CGDevelopmentUsersService >> bridge: aBridge [
 bridge := aBridge
]

{ #category : 'development' }
CGDevelopmentUsersService >> checkDevelopmentInvocation: unit context: context [
 ^ bridge decide: unit context: context
]

{ #category : 'development' }
CGDevelopmentUsersService >> continueStopping [
 self hasPendingStop ifFalse: [ super stop ]. ^ self
]

{ #category : 'development' }
CGDevelopmentUsersService >> hasPendingStop [
 ^ port notNil and: [ port count > 0 ]
]

{ #category : 'development' }
CGDevelopmentUsersService >> requiresStopProgress [
 ^ true
]

{ #category : 'development' }
CGDevelopmentUsersService >> start [
 super start.
 port := self capability: CRServiceActivationCapability.
 port activateRecords: 64 bytes: 262144.
 bridge registerPort: port role: #users.
 self provideCapability: CGDevelopmentUsersCapability instance: (CGDevelopmentUsersCapability service: self).
 ^ self
]

{ #category : 'development' }
CGDevelopmentUsersService >> stop [
 port ifNotNil: [ port deactivate ]. ^ self continueStopping
]
