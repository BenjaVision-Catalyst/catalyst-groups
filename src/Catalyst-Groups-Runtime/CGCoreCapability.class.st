"
Narrow Groups service export for the exact local fixture, invocation and decision WorkUnit classes. A configured development bridge enforces registered observed origin and callback identities. It conveys no serialisable principal or network ingress authority.
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

{ #category : 'development' }
CGCoreCapability class >> canBeGrantedToWorkUnitClass: unitClass [
 ^ { CGCoreCommandWorkUnit. CGCoreInvocationWorkUnit. CGCoreDecisionWorkUnit } includes: unitClass
]

{ #category : 'development' }
CGCoreCapability >> beginDevelopmentInvocation: unit context: context [
 ^ service beginDevelopmentInvocation: unit context: context
]

{ #category : 'development' }
CGCoreCapability >> completeDevelopmentInvocation: unit context: context [
 ^ service completeDevelopmentInvocation: unit context: context
]

{ #category : 'development' }
CGCoreCapability >> executeDevelopmentRequest: request actor: actor [
 ^ service executeDevelopmentRequest: request actor: actor
]
