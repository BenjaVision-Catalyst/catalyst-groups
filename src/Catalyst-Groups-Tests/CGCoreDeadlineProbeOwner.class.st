"
Test-only clock advance at the actual before-publication boundary. Verifies invocation expiry cannot publish a prepared graph after waiting or preparation.
"
Class {
	#name : 'CGCoreDeadlineProbeOwner',
	#superclass : 'CGCoreOwner',
	#category : 'Catalyst-Groups-Tests',
	#package : 'Catalyst-Groups-Tests'
}

{ #category : 'tests' }
CGCoreDeadlineProbeOwner >> probe: point [
 point = #beforePublication ifTrue: [ clock currentMillis: 6000 ].
 ^ super probe: point
]
