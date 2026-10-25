"
Typed bounded local refusal with explicit recording and retry semantics. Expected business refusals are recorded only after authorisation; pre-admission failures do not reserve domain outcomes.
"
Class {
	#name : 'CGCoreRefusal',
	#superclass : 'Error',
	#instVars : [
		'code',
		'recorded',
		'retryable'
	],
	#category : 'Catalyst-Groups-Core',
	#package : 'Catalyst-Groups-Core'
}

{ #category : 'accessing' }
CGCoreRefusal class >> code: aCode recorded: flag retryable: retryFlag [
 ^ self new code: aCode; recorded: flag; retryable: retryFlag; signal
]

{ #category : 'accessing' }
CGCoreRefusal >> code [
 ^ code
]

{ #category : 'accessing' }
CGCoreRefusal >> code: value [
 code := value
]

{ #category : 'accessing' }
CGCoreRefusal >> recorded [
 ^ recorded
]

{ #category : 'accessing' }
CGCoreRefusal >> recorded: value [
 recorded := value
]

{ #category : 'accessing' }
CGCoreRefusal >> retryable [
 ^ retryable
]

{ #category : 'accessing' }
CGCoreRefusal >> retryable: value [
 retryable := value
]
