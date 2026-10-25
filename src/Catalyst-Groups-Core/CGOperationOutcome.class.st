"
Append-only outcome bound to generation, exact actor, operation ID and canonical digest. Receipts are permission-filtered on recovery; expired content keeps its digest binding and cannot trigger execution again.
"
Class {
	#name : 'CGOperationOutcome',
	#superclass : 'CGCoreRecord',
	#category : 'Catalyst-Groups-Core',
	#package : 'Catalyst-Groups-Core'
}

{ #category : 'execution' }
CGOperationOutcome >> code [
 ^ self at: #code
]

{ #category : 'execution' }
CGOperationOutcome >> isSuccess [
 ^ self code = #Success
]
