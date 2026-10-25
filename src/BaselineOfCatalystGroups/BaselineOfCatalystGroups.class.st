"
Loads Groups packages into a GT/Pharo image that already has Catalyst Runtime, NeoJSON, UUID, SHA256 and SUnit. No speculative GemStone adapter or standalone C++ client.
"
Class {
	#name : 'BaselineOfCatalystGroups',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfCatalystGroups',
	#package : 'BaselineOfCatalystGroups'
}

{ #category : 'baseline' }
BaselineOfCatalystGroups >> baseline: spec [
 <baseline>
 spec for: #common do: [
  spec package: 'Catalyst-Groups-Core'.
  spec package: 'Catalyst-Groups-Development' with: [ spec requires: #('Catalyst-Groups-Core') ].
  spec package: 'Catalyst-Groups-Runtime' with: [ spec requires: #('Catalyst-Groups-Core') ].
  spec package: 'Catalyst-Groups-GT' with: [ spec requires: #('Catalyst-Groups-Core') ].
  spec package: 'Catalyst-Groups-Tests' with: [ spec requires: #('Catalyst-Groups-Development' 'Catalyst-Groups-Runtime' 'Catalyst-Groups-GT') ].
  spec group: 'Core' with: #('Catalyst-Groups-Core').
  spec group: 'Development' with: #('Catalyst-Groups-Development' 'Catalyst-Groups-Runtime' 'Catalyst-Groups-GT' 'Catalyst-Groups-Tests').
  spec group: 'default' with: #('Development') ]
]
