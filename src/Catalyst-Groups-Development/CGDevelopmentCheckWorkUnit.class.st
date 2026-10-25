"
Asynchronous identity-decision fixture WorkUnit targeted to the explicitly named development Users service. No production authentication claim.
"
Class {
	#name : 'CGDevelopmentCheckWorkUnit',
	#superclass : 'CRWorkUnit',
	#category : 'Catalyst-Groups-Development',
	#package : 'Catalyst-Groups-Development'
}

{ #category : 'development' }
CGDevelopmentCheckWorkUnit class >> requiredCapabilities [
 ^ { CGDevelopmentUsersCapability }
]

{ #category : 'development' }
CGDevelopmentCheckWorkUnit class >> serviceClass [
 ^ CGDevelopmentUsersService
]

{ #category : 'development' }
CGDevelopmentCheckWorkUnit >> executeInContext: context [
 ^ (context capability: CGDevelopmentUsersCapability) checkDevelopmentInvocation: self context: context
]
