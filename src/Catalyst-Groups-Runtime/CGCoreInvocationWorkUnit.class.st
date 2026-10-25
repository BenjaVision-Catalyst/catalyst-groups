"
Inert same-image development invocation. No actor, credentials or request authority in its payload. The configured bridge registers exact WorkUnit identity and Runtime verifies the originating submission. Not network ingress.
"
Class {
	#name : 'CGCoreInvocationWorkUnit',
	#superclass : 'CRWorkUnit',
	#instVars : [
		'result'
	],
	#category : 'Catalyst-Groups-Runtime',
	#package : 'Catalyst-Groups-Runtime'
}

{ #category : 'development' }
CGCoreInvocationWorkUnit class >> requiredCapabilities [
 ^ { CGCoreCapability }
]

{ #category : 'development' }
CGCoreInvocationWorkUnit class >> serviceClass [
 ^ CGCoreService
]

{ #category : 'development' }
CGCoreInvocationWorkUnit >> completeWith: anOutcome [
 result ifNil: [ result := anOutcome veryDeepCopy ]. ^ result
]

{ #category : 'development' }
CGCoreInvocationWorkUnit >> executeInContext: context [
 ^ (context capability: CGCoreCapability) beginDevelopmentInvocation: self context: context
]

{ #category : 'development' }
CGCoreInvocationWorkUnit >> result [
 ^ result ifNotNil: [ result veryDeepCopy ]
]
