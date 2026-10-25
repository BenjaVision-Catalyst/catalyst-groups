"
Narrow Runtime export restricted to the exact local Groups command WorkUnit and Groups service class. The development command path is synthetic and must not be exposed as authenticated network ingress.
"
Class {
	#name : 'CGCoreCapability',
	#superclass : 'CRServiceBoundCapability',
	#category : 'Catalyst-Groups-Runtime',
	#package : 'Catalyst-Groups-Runtime'
}

{ #category : 'authority' }
CGCoreCapability class >> canBeGrantedToServiceClass: serviceClass [
 ^ serviceClass = CGCoreService
]

{ #category : 'authority' }
CGCoreCapability class >> canBeGrantedToWorkUnitClass: unitClass [
 ^ unitClass = CGCoreCommandWorkUnit
]

{ #category : 'development' }
CGCoreCapability >> executeDevelopmentRequest: request actor: actor [
 ^ service executeDevelopmentRequest: request actor: actor
]
