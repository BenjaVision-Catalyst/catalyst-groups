"Run in the prepared GT/Runtime image. Synthetic Users decisions only."
| suite result methods examples report |
suite := TestSuite named: 'Groups P1'.
suite addTest: CGCoreTests suite; addTest: CGCoreRuntimeTests suite.
result := suite run.
methods := {CGCoreExamples. CGCoreRuntimeExamples} flatCollect: [ :class |
 class methods select: [ :method | method hasPragmaNamed: #gtExample ] ].
examples := methods collect: [ :method |
 | example |
 example := method gtExample run.
 (example isSuccess and: [ example returnValue notNil and: [ (example returnValue isKindOf: TestCase) not ] ])
  ifFalse: [ self error: 'GT example failed: ', method printString ].
 example ].
report := {
 #sunit -> { #run -> result runCount. #passed -> result passedCount.
  #failures -> result failureCount. #errors -> result errorCount. #skips -> result skippedCount } asDictionary.
 #gtExamples -> examples size.
 #image -> Smalltalk imagePath.
 #platform -> Smalltalk version
} asDictionary.
result isSuccess ifFalse: [ self error: 'Groups SUnit failures/errors; inspect the suites' ].
NeoJSONWriter toString: report
