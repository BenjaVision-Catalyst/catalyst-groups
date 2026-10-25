Extension { #name : 'CGCoreRecord' }

{ #category : '*Catalyst-Groups-GT' }
CGCoreRecord >> gtFieldsFor: aView [
 <gtView>
 ^ aView columnedList title: 'Fields'; items: [ fields associations sorted: [ :a :b | a key <= b key ] ]; column: 'Field' text: [ :a | a key ]; column: 'Value' text: [ :a | a value ]; yourself
]
