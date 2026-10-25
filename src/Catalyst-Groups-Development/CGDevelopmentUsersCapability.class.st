"
Narrow capability available only to the exact development Users decision WorkUnit and service.
"
Class {
	#name : 'CGDevelopmentUsersCapability',
	#superclass : 'CRServiceBoundCapability',
	#category : 'Catalyst-Groups-Development',
	#package : 'Catalyst-Groups-Development'
}

{ #category : 'development' }
CGDevelopmentUsersCapability class >> canBeGrantedToServiceClass: aClass [
 ^ aClass = CGDevelopmentUsersService
]

{ #category : 'development' }
CGDevelopmentUsersCapability class >> canBeGrantedToWorkUnitClass: aClass [
 ^ aClass = CGDevelopmentCheckWorkUnit
]

{ #category : 'development' }
CGDevelopmentUsersCapability >> checkDevelopmentInvocation: unit context: context [
 ^ service checkDevelopmentInvocation: unit context: context
]
