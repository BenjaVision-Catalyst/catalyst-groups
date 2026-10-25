"
Inert callback to the named Groups service. Only an exact bridge registration and verified originating Users-fixture activation can associate it with one pending invocation.
"
Class {
	#name : 'CGCoreDecisionWorkUnit',
	#superclass : 'CRWorkUnit',
	#category : 'Catalyst-Groups-Runtime',
	#package : 'Catalyst-Groups-Runtime'
}

{ #category : 'development' }
CGCoreDecisionWorkUnit class >> requiredCapabilities [
 ^ { CGCoreCapability }
]

{ #category : 'development' }
CGCoreDecisionWorkUnit class >> serviceClass [
 ^ CGCoreService
]

{ #category : 'development' }
CGCoreDecisionWorkUnit >> executeInContext: context [
 ^ (context capability: CGCoreCapability) completeDevelopmentInvocation: self context: context
]
