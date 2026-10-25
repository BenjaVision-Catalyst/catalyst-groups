"
GT-only export and round-trip verification for the live Groups source. Exports into a clean, unregistered destination; never synchronises an image-registered checkout.
"
Class {
	#name : 'CGCoreDevelopmentTools',
	#superclass : 'Object',
	#category : 'Catalyst-Groups-Development',
	#package : 'Catalyst-Groups-Development'
}

{ #category : 'development' }
CGCoreDevelopmentTools class >> exportTo: repositoryDirectory [
 | root source |
 root := repositoryDirectory asFileReference.
 (IceRepository registry anySatisfy: [ :repo | repo location = root ]) ifTrue: [ self error: 'Use an independent clean checkout; this destination is registered with the image' ].
 source := root / 'src'. source ensureCreateDirectory.
 self packageNames do: [ :name |
  (source / name) exists ifTrue: [ self error: 'Export destination must be clean; existing package found' ] ].
 self packageNames do: [ :name |
  (TonelWriter on: source) writeSnapshot: (MCPackage named: name) snapshot ].
 ^ self verifyExportAt: root
]

{ #category : 'development' }
CGCoreDevelopmentTools class >> packageNames [
 ^ #('Catalyst-Groups-Core' 'Catalyst-Groups-Development' 'Catalyst-Groups-Runtime' 'Catalyst-Groups-GT' 'Catalyst-Groups-Tests' 'BaselineOfCatalystGroups')
]

{ #category : 'development' }
CGCoreDevelopmentTools class >> verifyExportAt: repositoryDirectory [
 | root report totalClasses totalMethods |
 root := repositoryDirectory asFileReference / 'src'. report := OrderedCollection new.
 totalClasses := 0. totalMethods := 0.
 self packageNames do: [ :name |
  | expected actual |
  expected := (MCPackage named: name) snapshot definitions reject: [ :d | d isOrganizationDefinition ].
  actual := OrderedCollection new.
  (root / name) files do: [ :file |
   file basename = 'package.st' ifFalse: [ actual addAll: (TonelParser parseString: file contents) ] ].
  expected size = actual size ifFalse: [ self error: 'Export definition count mismatch: ', name ].
  expected do: [ :definition |
   | disk |
   definition isMethodDefinition
    ifTrue: [
     disk := actual detect: [ :d | d isMethodDefinition and: [ d className = definition className and: [ d classIsMeta = definition classIsMeta and: [ d selector = definition selector ] ] ] ].
     ((RBParser parseMethod: disk source) formattedCode = (RBParser parseMethod: definition source) formattedCode and: [ disk category = definition category ]) ifFalse: [ self error: 'Method mismatch: ', definition description ].
     totalMethods := totalMethods + 1 ]
    ifFalse: [
     disk := actual detect: [ :d | d isClassDefinition and: [ d className = definition className ] ].
     { disk superclassName. disk instVarNames. disk classInstVarNames. disk classVarNames. disk packageName. disk comment } =
      { definition superclassName. definition instVarNames. definition classInstVarNames. definition classVarNames. definition packageName. definition comment }
      ifFalse: [ self error: 'Class mismatch: ', definition className ].
     totalClasses := totalClasses + 1 ] ].
  report add: { name. expected size } ].
 ^ { #classes -> totalClasses. #methods -> totalMethods. #packages -> report } asDictionary
]
