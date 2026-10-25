"
Owner-private domain record. Setters are used only on unpublished drafts. Client, example and diagnostic views must receive detached copies; this class alone is not an immutable or authorised client DTO.
"
Class {
	#name : 'CGCoreRecord',
	#superclass : 'Object',
	#instVars : [
		'fields'
	],
	#category : 'Catalyst-Groups-Core',
	#package : 'Catalyst-Groups-Core'
}

{ #category : 'accessing' }
CGCoreRecord >> advance [
 self revision = 18446744073709551615 ifTrue: [ CGCoreRefusal code: #CapacityReached recorded: true retryable: false ].
 self at: #revision put: self revision + 1
]

{ #category : 'accessing' }
CGCoreRecord >> at: key [
 ^ fields at: key
]

{ #category : 'accessing' }
CGCoreRecord >> at: key ifAbsent: block [
 ^ fields at: key ifAbsent: block
]

{ #category : 'accessing' }
CGCoreRecord >> at: key put: value [
 ^ fields at: key put: value
]

{ #category : 'accessing' }
CGCoreRecord >> id [
 ^ self at: #id
]

{ #category : 'accessing' }
CGCoreRecord >> initialize [
 super initialize. fields := Dictionary new
]

{ #category : 'accessing' }
CGCoreRecord >> revision [
 ^ self at: #revision
]

{ #category : 'accessing' }
CGCoreRecord >> state [
 ^ self at: #state
]

{ #category : 'domain' }
CGCoreRecord >> state: nextState [
 self at: #state put: nextState. self advance
]
