"
Owner-private published in-memory graph. Mutable domain records are copied for drafts. Retained outcomes and prior audit/journal entries are append-only and can be shared; readers receive detached graphs. Never expose this state as a client-authorised roster.
"
Class {
	#name : 'CGCoreState',
	#superclass : 'Object',
	#instVars : [
		'generation',
		'groups',
		'outcomes',
		'audit',
		'journal',
		'securityRevisions',
		'sourceGeneration',
		'sourceSequence'
	],
	#category : 'Catalyst-Groups-Core',
	#package : 'Catalyst-Groups-Core'
}

{ #category : 'accessing' }
CGCoreState >> audit [
 ^ audit
]

{ #category : 'accessing' }
CGCoreState >> generation [
 ^ generation
]

{ #category : 'accessing' }
CGCoreState >> groups [
 ^ groups
]

{ #category : 'accessing' }
CGCoreState >> initialize [
 super initialize.
 generation := UUID new uuidData copy.
 groups := Dictionary new. outcomes := Dictionary new.
 audit := Dictionary new. journal := Dictionary new. securityRevisions := Dictionary new.
 sourceSequence := 0
]

{ #category : 'accessing' }
CGCoreState >> journal [
 ^ journal
]

{ #category : 'accessing' }
CGCoreState >> outcomes [
 ^ outcomes
]

{ #category : 'copying' }
CGCoreState >> postCopy [
 super postCopy.
 "Published outcomes and old journal/audit entries are append-only values.
 Deep copy only the domain graph that a draft may change."
 generation := generation copy.
 groups := groups veryDeepCopy.
 outcomes := outcomes copy.
 audit := (audit associations collect: [ :entry | entry key -> entry value copy ]) asDictionary.
 journal := (journal associations collect: [ :entry | entry key -> entry value copy ]) asDictionary.
 securityRevisions := securityRevisions copy.
 sourceGeneration := sourceGeneration ifNotNil: [ sourceGeneration copy ]
]

{ #category : 'accessing' }
CGCoreState >> securityRevisions [
 ^ securityRevisions
]

{ #category : 'accessing' }
CGCoreState >> sourceGeneration [
 ^ sourceGeneration
]

{ #category : 'accessing' }
CGCoreState >> sourceGeneration: value [
 sourceGeneration := value
]

{ #category : 'accessing' }
CGCoreState >> sourceSequence [
 ^ sourceSequence
]

{ #category : 'accessing' }
CGCoreState >> sourceSequence: value [
 sourceSequence := value
]
