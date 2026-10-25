"
Validated exact frozen request value, copied at construction; canonical request-contract/version/type/payload SHA-256 digest. Actor identity is deliberately absent from the payload. The local development entry point receives an explicitly synthetic actor separately.
"
Class {
	#name : 'CGCoreRequest',
	#superclass : 'Object',
	#instVars : [
		'operation',
		'payload',
		'digest'
	],
	#category : 'Catalyst-Groups-Core',
	#package : 'Catalyst-Groups-Core'
}

{ #category : 'accessing' }
CGCoreRequest class >> operation: name payload: map [
 ^ self new initializeOperation: name payload: map
]

{ #category : 'accessing' }
CGCoreRequest >> authorityEpoch [
 ^ payload at: 3
]

{ #category : 'accessing' }
CGCoreRequest >> body [
 ^ (payload at: 4) veryDeepCopy
]

{ #category : 'accessing' }
CGCoreRequest >> digest [
 ^ digest copy
]

{ #category : 'accessing' }
CGCoreRequest >> generation [
 ^ (payload at: 1) copy
]

{ #category : 'accessing' }
CGCoreRequest >> groupRevision [
 ^ payload at: 2
]

{ #category : 'accessing' }
CGCoreRequest >> initializeOperation: name payload: map [
 | spec bytes prefix |
 spec := CGCoreContract operation: name.
 CGCoreContract validate: map type: (spec at: 'requestType').
 operation := name asString copy. payload := map veryDeepCopy.
 bytes := CGCoreContract encode: payload.
 CGCoreContract require: bytes size <= 4096.
 prefix := ByteArray readHexFrom: '7679489479e343fe8be9cce30db77e9e00000001'.
 prefix := prefix , (ByteArray with: 0 with: 0 with: 0 with: (spec at: 'typeId')).
 digest := SHA256 hashMessage: prefix , bytes.
 ^ self
]

{ #category : 'accessing' }
CGCoreRequest >> operation [
 ^ operation copy
]

{ #category : 'accessing' }
CGCoreRequest >> operationId [
 ^ (payload at: 0) copy
]

{ #category : 'accessing' }
CGCoreRequest >> payload [
 ^ payload veryDeepCopy
]
