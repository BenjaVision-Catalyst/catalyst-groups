"
Inert local P1 development command. Carries copied request and synthetic actor values, declares CGCoreService/CGCoreCapability, and uses Runtime's named-service capability resolution. It is not a real Users principal delegation or a network handler.
"
Class {
	#name : 'CGCoreCommandWorkUnit',
	#superclass : 'CRWorkUnit',
	#instVars : [
		'request',
		'actor',
		'result'
	],
	#category : 'Catalyst-Groups-Runtime',
	#package : 'Catalyst-Groups-Runtime'
}

{ #category : 'routing' }
CGCoreCommandWorkUnit class >> requiredCapabilities [
 ^ { CGCoreCapability }
]

{ #category : 'routing' }
CGCoreCommandWorkUnit class >> serviceClass [
 ^ CGCoreService
]

{ #category : 'execution' }
CGCoreCommandWorkUnit >> executeInContext: context [
 result := (context capability: CGCoreCapability) executeDevelopmentRequest: request actor: actor
]

{ #category : 'configuration' }
CGCoreCommandWorkUnit >> request: aRequest actor: user [
 request := aRequest veryDeepCopy. actor := user veryDeepCopy
]

{ #category : 'accessing' }
CGCoreCommandWorkUnit >> result [
 ^ result veryDeepCopy
]
