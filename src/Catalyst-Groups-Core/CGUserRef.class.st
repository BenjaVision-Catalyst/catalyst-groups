"
Exact domain/tenant/subject identity value. Validated Unicode scalar and UTF-8 bounds; case and code points are preserved. Copies strings at boundaries; identity never implies access rights.
"
Class {
	#name : 'CGUserRef',
	#superclass : 'Object',
	#instVars : [
		'domain',
		'tenant',
		'subject'
	],
	#category : 'Catalyst-Groups-Core',
	#package : 'Catalyst-Groups-Core'
}

{ #category : 'accessing' }
CGUserRef class >> domain: aDomain tenant: aTenant subject: aSubject [
 ^ self new initializeDomain: aDomain tenant: aTenant subject: aSubject
]

{ #category : 'accessing' }
CGUserRef class >> fromMap: map [
 self validateMap: map.
 ^ self domain: (map at: 0) tenant: (map at: 1) subject: (map at: 2)
]

{ #category : 'accessing' }
CGUserRef class >> validateMap: map [
 CGCoreContract validate: map type: 'UserRef'
]

{ #category : 'accessing' }
CGUserRef >> = other [
 ^ self class = other class and: [ domain = other domain and: [ tenant = other tenant and: [ subject = other subject ] ] ]
]

{ #category : 'accessing' }
CGUserRef >> asMap [
 ^ { 0 -> domain copy. 1 -> tenant copy. 2 -> subject copy } asDictionary
]

{ #category : 'accessing' }
CGUserRef >> domain [
 ^ domain copy
]

{ #category : 'accessing' }
CGUserRef >> hash [
 ^ domain hash bitXor: (tenant hash bitXor: subject hash)
]

{ #category : 'accessing' }
CGUserRef >> initializeDomain: aDomain tenant: aTenant subject: aSubject [
 { aDomain. aTenant. aSubject } do: [ :each | CGCoreContract validate: each type: 'IdentityText' ].
 domain := aDomain copy. tenant := aTenant copy. subject := aSubject copy.
 ^ self
]

{ #category : 'accessing' }
CGUserRef >> sameRealmAs: other [
 ^ domain = other domain and: [ tenant = other tenant ]
]

{ #category : 'accessing' }
CGUserRef >> subject [
 ^ subject copy
]

{ #category : 'accessing' }
CGUserRef >> tenant [
 ^ tenant copy
]
