"
Synthetic P1 fixture only. Explicitly configured identities, contact and freshness decisions; one-use identity-registered facts bind immutable snapshots. This is not authentication, MFA, a production delegated-origin adapter or an authoritative Users resynchronisation implementation.
"
Class {
	#name : 'CGDevelopmentIdentities',
	#superclass : 'Object',
	#instVars : [
		'decisions',
		'facts'
	],
	#category : 'Catalyst-Groups-Development',
	#package : 'Catalyst-Groups-Development'
}

{ #category : 'execution' }
CGDevelopmentIdentities >> allow: user [
 self allow: user revision: 1 authenticatedAt: 0
]

{ #category : 'execution' }
CGDevelopmentIdentities >> allow: user revision: revision authenticatedAt: millis [
 decisions at: user put: { #eligible -> true. #revision -> revision. #authenticatedAt -> millis. #contact -> true } asDictionary
]

{ #category : 'development' }
CGDevelopmentIdentities >> consumeFact: fact [
 | snapshot |
 snapshot := facts removeKey: fact ifAbsent: [ CGCoreRefusal code: #NotAuthorised recorded: false retryable: false ].
 snapshot = fact ifFalse: [ CGCoreRefusal code: #NotAuthorised recorded: false retryable: false ].
 ^ snapshot
]

{ #category : 'execution' }
CGDevelopmentIdentities >> contact: flag for: user [
 (self decisionFor: user) at: #contact put: flag
]

{ #category : 'development' }
CGDevelopmentIdentities >> copyDecisionsFor: subjects [
 | copy |
 subjects size <= 4 ifFalse: [ self error: 'Bounded invocation projection required' ].
 copy := self class new.
 subjects do: [ :user | copy installDecision: (decisions at: user ifAbsent: [ nil ]) for: user ].
 ^ copy
]

{ #category : 'execution' }
CGDevelopmentIdentities >> decisionFor: user [
 ^ decisions at: user ifAbsent: [ CGCoreRefusal code: #DependencyUnavailable recorded: false retryable: true ]
]

{ #category : 'execution' }
CGDevelopmentIdentities >> deny: user revision: revision [
 decisions at: user put: { #eligible -> false. #revision -> revision. #authenticatedAt -> 0. #contact -> false } asDictionary
]

{ #category : 'development' }
CGDevelopmentIdentities >> fact: kind subject: user revision: revision generation: generation sequence: sequence [
 | fact |
 fact := { #kind -> kind. #subject -> user. #revision -> revision. #generation -> generation copy. #sequence -> sequence } asDictionary.
 facts size >= 64 ifTrue: [ CGCoreRefusal code: #Overloaded recorded: false retryable: true ].
 facts at: fact put: fact veryDeepCopy. ^ fact
]

{ #category : 'development' }
CGDevelopmentIdentities >> groupFact: kind group: identifier generation: generation sequence: sequence cleanupConfirmed: confirmed [
 | fact |
 fact := { #kind -> kind. #groupId -> identifier copy. #generation -> generation copy. #sequence -> sequence. #cleanupConfirmed -> confirmed } asDictionary.
 facts size >= 64 ifTrue: [ CGCoreRefusal code: #Overloaded recorded: false retryable: true ].
 facts at: fact put: fact veryDeepCopy. ^ fact
]

{ #category : 'execution' }
CGDevelopmentIdentities >> initialize [
 super initialize. decisions := Dictionary new. facts := IdentityDictionary new
]

{ #category : 'development' }
CGDevelopmentIdentities >> installDecision: value for: user [
 value ifNotNil: [ decisions at: user veryDeepCopy put: value veryDeepCopy ]
]

{ #category : 'execution' }
CGDevelopmentIdentities >> requireAssuranceFor: user at: now [
 | authenticatedAt |
 authenticatedAt := (self decisionFor: user) at: #authenticatedAt.
 (authenticatedAt <= now and: [ now - authenticatedAt <= 300000 ]) ifFalse: [ CGCoreRefusal code: #AssuranceRequired recorded: false retryable: true ]
]

{ #category : 'execution' }
CGDevelopmentIdentities >> requireContactFrom: actor to: target [
 self requireEligible: actor minimumRevision: 0.
 self requireEligible: target minimumRevision: 0.
 ((self decisionFor: actor) at: #contact) ifFalse: [ CGCoreRefusal code: #NotAuthorised recorded: false retryable: false ].
 ((self decisionFor: target) at: #contact) ifFalse: [ CGCoreRefusal code: #NotAuthorised recorded: false retryable: false ]
]

{ #category : 'execution' }
CGDevelopmentIdentities >> requireEligible: user minimumRevision: minimum [
 | decision |
 decision := self decisionFor: user.
 (decision at: #revision) < minimum ifTrue: [ CGCoreRefusal code: #DependencyUnavailable recorded: false retryable: true ].
 (decision at: #eligible) ifFalse: [ CGCoreRefusal code: #NotAuthorised recorded: false retryable: false ].
 ^ decision at: #revision
]

{ #category : 'execution' }
CGDevelopmentIdentities >> unavailable: user [
 decisions removeKey: user ifAbsent: [ ]
]
