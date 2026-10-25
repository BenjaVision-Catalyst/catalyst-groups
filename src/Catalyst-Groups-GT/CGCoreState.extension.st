Extension { #name : 'CGCoreState' }

{ #category : '*Catalyst-Groups-GT' }
CGCoreState >> gtGroupsFor: aView [
 <gtView>
 ^ aView columnedList title: 'Groups'; items: [ groups values ]; column: 'Name' text: [ :g | g at: #name ]; column: 'State' text: [ :g | g state ]; column: 'Governance' text: [ :g | g at: #governance ]; column: 'Revision' text: [ :g | g revision ]; yourself
]
