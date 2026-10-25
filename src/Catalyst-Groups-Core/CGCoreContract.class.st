"
Frozen groups-core-dev-1 schema, profile and state tables, plus deterministic outbound encoding used to bind domain intents to the normative SHA-256 request digest. Definition caches are private read-only implementation data. This is not an untrusted CBOR decoder or a Connect binding.
"
Class {
	#name : 'CGCoreContract',
	#superclass : 'Object',
	#classInstVars : [
		'frozenSchema',
		'frozenProfile',
		'frozenMachines'
	],
	#category : 'Catalyst-Groups-Core',
	#package : 'Catalyst-Groups-Core'
}

{ #category : 'canonical encoding' }
CGCoreContract class >> encode: value [
 | stream |
 stream := ByteArray new writeStream.
 self encode: value on: stream.
 ^ stream contents
]

{ #category : 'canonical encoding' }
CGCoreContract class >> encode: value on: stream [
 value ifNil: [ ^ stream nextPut: 246 ].
 value == true ifTrue: [ ^ stream nextPut: 245 ].
 value == false ifTrue: [ ^ stream nextPut: 244 ].
 value isInteger ifTrue: [ self require: (value between: 0 and: 18446744073709551615). ^ self head: 0 value: value on: stream ].
 value class = ByteArray ifTrue: [ self head: 2 value: value size on: stream. ^ stream nextPutAll: value ].
 value isString ifTrue: [ | bytes | bytes := value utf8Encoded. self head: 3 value: bytes size on: stream. ^ stream nextPutAll: bytes ].
 value isDictionary ifTrue: [ self head: 5 value: value size on: stream. value keys sorted do: [ :key | self encode: key on: stream. self encode: (value at: key) on: stream ]. ^ self ].
 value isArray ifTrue: [ self head: 4 value: value size on: stream. value do: [ :item | self encode: item on: stream ]. ^ self ].
 self require: false
]

{ #category : 'canonical encoding' }
CGCoreContract class >> head: major value: integer on: stream [
 integer < 24 ifTrue: [ ^ stream nextPut: major * 32 + integer ].
 #((24 1 255) (25 2 65535) (26 4 4294967295) (27 8 18446744073709551615)) do: [ :choice |
  integer <= choice third ifTrue: [
   stream nextPut: major * 32 + choice first.
   choice second - 1 to: 0 by: -1 do: [ :i | stream nextPut: ((integer bitShift: i * -8) bitAnd: 255) ].
   ^ self ] ].
 self require: false
]

{ #category : 'accessing' }
CGCoreContract class >> limit: key [
 ^ (self profile at: 'limits') at: key asString
]

{ #category : 'private contract' }
CGCoreContract class >> machines [
 ^ frozenMachines ifNil: [ frozenMachines := (NeoJSONReader fromString: '{"formatVersion":1,"machines":{"group":{"states":["absent","active","dissolving","dissolved"],"terminalStates":["dissolved"],"transitions":[{"from":"absent","event":"create","to":"active","requires":["actorEligible","quotaAvailable","initialStewardRecorded"]},{"from":"active","event":"beginDissolution","to":"dissolving","requires":["currentSteward","freshGovernanceAssurance","revisionsMatch"]},{"from":"active","event":"trustedClose","to":"dissolving","requires":["trustedDeploymentClosure"]},{"from":"dissolving","event":"finalizeDissolution","to":"dissolved","requires":["noPendingEffects","deliveryFencesConfirmed"]}]},"membership":{"states":["absent","active","suspended","left","removed"],"terminalStates":["left","removed"],"transitions":[{"from":"absent","event":"join","to":"active","requires":["groupActive","actorEligible","admissionPermitted","capacityAvailable","newIncarnation"]},{"from":"active","event":"suspend","to":"suspended","requires":["groupActive","currentSteward","targetNotSteward","revisionsMatch"]},{"from":"suspended","event":"resume","to":"active","requires":["groupActive","currentSteward","targetEligible","noAdmissionRestriction","revisionsMatch"]},{"from":"active","event":"leave","to":"left","requires":["groupActive","actualSubject","targetNotSteward","entityRevisionMatches"]},{"from":"suspended","event":"leave","to":"left","requires":["groupActive","actualSubject","targetNotSteward","entityRevisionMatches"]},{"from":"active","event":"remove","to":"removed","requires":["groupActive","currentSteward","targetNotSteward","revisionsMatch"]},{"from":"suspended","event":"remove","to":"removed","requires":["groupActive","currentSteward","targetNotSteward","revisionsMatch"]},{"from":"active","event":"closeAccount","to":"removed","requires":["verifiedUsersClosure"]},{"from":"suspended","event":"closeAccount","to":"removed","requires":["verifiedUsersClosure"]},{"from":"active","event":"dissolveGroup","to":"removed","requires":["groupDissolving"]},{"from":"suspended","event":"dissolveGroup","to":"removed","requires":["groupDissolving"]}]},"invitation":{"states":["absent","pending","accepted","declined","withdrawn","expired","invalidated"],"terminalStates":["accepted","declined","withdrawn","expired","invalidated"],"transitions":[{"from":"absent","event":"issue","to":"pending","requires":["groupActive","currentSteward","targetContactEligible","pendingCapacity","revisionsMatch"]},{"from":"pending","event":"accept","to":"accepted","requires":["groupActive","actualInvitee","entityRevisionMatches","unexpired","actorEligible","issuerStillAuthorised","termsCurrent","noAdmissionRestriction","capacityAvailable"]},{"from":"pending","event":"decline","to":"declined","requires":["groupActive","actualInvitee","entityRevisionMatches","unexpired"]},{"from":"pending","event":"withdraw","to":"withdrawn","requires":["groupActive","currentSteward","revisionsMatch"]},{"from":"pending","event":"expire","to":"expired","requires":["deadlineReached"]},{"from":"pending","event":"invalidate","to":"invalidated","requires":["sourceAuthorityOrTermsLost"]}]},"application":{"states":["absent","pending","accepted","declined","withdrawn","expired","invalidated"],"terminalStates":["accepted","declined","withdrawn","expired","invalidated"],"transitions":[{"from":"absent","event":"apply","to":"pending","requires":["groupActive","actualSubject","actorEligible","applicationPolicy","noAdmissionRestriction","pendingCapacity"]},{"from":"pending","event":"accept","to":"accepted","requires":["groupActive","currentSteward","revisionsMatch","unexpired","applicantEligible","termsCurrent","noAdmissionRestriction","capacityAvailable"]},{"from":"pending","event":"decline","to":"declined","requires":["groupActive","currentSteward","revisionsMatch","unexpired"]},{"from":"pending","event":"withdraw","to":"withdrawn","requires":["groupActive","actualSubject","entityRevisionMatches","unexpired"]},{"from":"pending","event":"expire","to":"expired","requires":["deadlineReached"]},{"from":"pending","event":"invalidate","to":"invalidated","requires":["sourceAuthorityOrTermsLost"]}]},"stewardshipOffer":{"states":["absent","pending","accepted","withdrawn","expired","invalidated"],"terminalStates":["accepted","withdrawn","expired","invalidated"],"transitions":[{"from":"absent","event":"offer","to":"pending","requires":["groupActive","currentSteward","successorActive","successorDistinct","freshGovernanceAssurance","revisionsMatch"]},{"from":"pending","event":"accept","to":"accepted","requires":["groupActive","actualSuccessor","successorActive","actorEligible","entityRevisionMatches","unexpired","sourceEpochCurrent","freshGovernanceAssurance"]},{"from":"pending","event":"withdraw","to":"withdrawn","requires":["groupActive","currentSteward","revisionsMatch"]},{"from":"pending","event":"expire","to":"expired","requires":["deadlineReached"]},{"from":"pending","event":"invalidate","to":"invalidated","requires":["sourceAuthorityOrTermsLost"]}]},"governance":{"states":["absent","operational","restricted","recoveryRequired","closed"],"terminalStates":["closed"],"transitions":[{"from":"absent","event":"create","to":"operational","requires":["initialStewardRecorded"]},{"from":"operational","event":"acceptHandover","to":"operational","requires":["acceptedOffer","successorActive","atomicHolderReplacement"]},{"from":"operational","event":"restrictHolder","to":"restricted","requires":["verifiedUsersRestriction"]},{"from":"restricted","event":"restoreHolder","to":"operational","requires":["sameHolderIncarnation","verifiedUsersEligibility"]},{"from":"operational","event":"closeHolder","to":"recoveryRequired","requires":["verifiedUsersClosure"]},{"from":"restricted","event":"closeHolder","to":"recoveryRequired","requires":["verifiedUsersClosure"]},{"from":"operational","event":"dissolveGroup","to":"closed","requires":["groupDissolving"]},{"from":"restricted","event":"dissolveGroup","to":"closed","requires":["trustedDeploymentClosure"]},{"from":"recoveryRequired","event":"dissolveGroup","to":"closed","requires":["trustedDeploymentClosure"]}]},"admissionRestriction":{"states":["absent","active","expired","removed"],"terminalStates":["expired","removed"],"transitions":[{"from":"absent","event":"set","to":"active","requires":["groupActive","currentSteward","revisionsMatch","restrictionCapacity"]},{"from":"active","event":"renew","to":"active","requires":["groupActive","currentSteward","revisionsMatch","unexpired"]},{"from":"active","event":"remove","to":"removed","requires":["groupActive","currentSteward","revisionsMatch"]},{"from":"active","event":"expire","to":"expired","requires":["deadlineReached"]}]}},"rules":["All guards must hold; omitted or false guards refuse without a business state change.","Membership terminal records never reactivate; joining creates a new ID/incarnation.","Acceptance and membership/holder effects are one local publication, not separate callbacks.","Only verified, allow-listed Users/deployment WorkUnits can assert service-only events.","recoveryRequired has no self-appointment or public recovery transition in this profile."]}') at: 'machines' ]
]

{ #category : 'accessing' }
CGCoreContract class >> operation: aName [
 ^ (self schema at: 'operations') detect: [ :each | (each at: 'name') = aName asString ] ifNone: [ CGCoreRefusal code: #NotSupported recorded: false retryable: false ]
]

{ #category : 'private contract' }
CGCoreContract class >> profile [
 ^ frozenProfile ifNil: [ frozenProfile := NeoJSONReader fromString: '{"formatVersion":1,"profileId":"groups-core-dev-1","status":"frozen-development","date":"2026-10-25","platform":{"current":"GT/Pharo","state":"in-memory-single-owner","gemstone":"deferred until available; no domain adapter assumed necessary","durabilityClaim":false,"automaticRecovery":false},"connect":{"profileId":"catp-reliable-dev-1","manifestSha256":"3b4744a717ac64a2ce9099407a32baa9bf1bf332d7063a7bac79fbd9640484cd","delivery":"ReliableOrdered","sessionOwner":"Users","receiverService":"groups","contracts":[{"role":"requests","idHex":"7679489479e343fe8be9cce30db77e9e","version":1,"endpoint":"groups.core.requests","maximumPayload":4096},{"role":"results","idHex":"b492d94b6507491d92717ea7d83261dc","version":1,"endpoint":"groups.core.results","maximumPayload":16384},{"role":"changes","idHex":"ba53afafc1ba45129eadf66e96d4f3b3","version":1,"endpoint":"groups.core.changes","maximumPayload":1024}]},"scope":{"tenantRequired":true,"crossRealmMembership":false,"actorFromPayload":false,"currentUnitsSupported":false,"optionalFieldsAllowed":false},"governance":{"roles":["Steward","Member"],"designatedStewards":1,"customRoles":false,"automaticSuccession":false,"clientRecoveryOperation":false,"governanceAssurancePolicy":"groups.governance.v1"},"limits":{"groups":128,"membersPerGroup":64,"membershipHistoryPerGroup":256,"membershipsPerUser":32,"createdActiveGroupsPerUser":4,"pendingInvitationsPerGroup":64,"pendingApplicationsPerGroup":64,"recordHistoryPerKindPerGroup":256,"pendingStewardshipOffersPerGroup":1,"restrictionsPerGroup":64,"mutationsPerUserPerGeneration":1024,"mutationRecordsGlobal":8192,"retainedResultMillis":86400000,"journalEntriesPerGroup":1024,"journalMillis":3600000,"auditEntriesPerGroup":2048,"snapshotsGlobal":64,"snapshotsPerUser":2,"snapshotLeaseMillis":30000,"pageRows":8,"subscriptionsGlobal":128,"subscriptionsPerUser":4,"subscriptionQueueEvents":32,"subscriptionLeaseMillis":300000,"requestedUsersPerRecipientBatch":32,"maxExactSessionsPerBatch":64,"pendingUsersInvocationsGlobal":64,"usersInvocationDeadlineMillis":5000,"governanceAuthenticationMaxAgeMillis":300000,"maxRequestsPerUserPerMinute":120,"maxInvitesPerIssuerPerHour":20,"applicationTTLMillis":604800000,"requestPayloadBytes":4096,"resultPayloadBytes":16384,"eventPayloadBytes":1024,"codecBudgetBytes":131072,"receiveBudgetBytes":262144,"maxCborDepth":8,"maxCborMapFields":16,"maxCborArrayItems":34,"maxCborItems":1024,"subjectsGlobal":512,"pendingInvitationsPerUser":64,"pendingApplicationsPerUser":32},"deferred":["unit wire contracts","custom hierarchy/roles","relationship projections","personality/type indicators","shared resources","rich messaging/media","UE/Apple deployment versions and packaging","GemStone qualification"],"excluded":["AI","automatic team assignment","relationship-derived permissions","production credentials in fixtures"],"ratePolicy":{"kind":"token-bucket","requestsBurst":120,"requestsRefillIntervalMillis":500,"invitesBurst":20,"invitesRefillIntervalMillis":180000},"permissions":{"stewardOnlyQueries":["QueryApplications","QueryInvitations","QueryAdmissionRestrictions"],"activeMemberQueries":["GetGroupSnapshot","SubscribeGroupChanges"],"ownOrStewardQueries":["GetInvitation","GetStewardshipOffer"],"recordedMutationReceipts":{"CreateGroup":"new founder Membership; active","UpdateGroup":"Group; active","InviteMember":"Invitation; pending","WithdrawInvitation":"Invitation; withdrawn","AcceptInvitation":"Membership; active","DeclineInvitation":"Invitation; declined","ApplyToJoin":"Application; pending","WithdrawApplication":"Application; withdrawn","DecideApplication":"accept: Membership active; decline: Application declined","JoinOpenGroup":"Membership; active","LeaveGroup":"Membership; left","SuspendMember":"Membership; suspended","ResumeMember":"Membership; active","RemoveMember":"Membership; removed","SetAdmissionRestriction":"Restriction; active","RemoveAdmissionRestriction":"Restriction; cleared","TransferStewardship":"Offer; pending","AcceptStewardship":"new holder Membership; active","WithdrawStewardshipOffer":"Offer; withdrawn","BeginDissolution":"Group; dissolving"}}}' ]
]

{ #category : 'accessing' }
CGCoreContract class >> require: condition [
 condition ifFalse: [ CGCoreRefusal code: #InvalidRequest recorded: false retryable: false ]
]

{ #category : 'private contract' }
CGCoreContract class >> schema [
 ^ frozenSchema ifNil: [ frozenSchema := NeoJSONReader fromString: '{
  "formatVersion": 1,
  "types": {
    "Id": {
      "kind": "bytes",
      "length": 16
    },
    "U64": {
      "kind": "uint",
      "min": 0,
      "max": 18446744073709551615
    },
    "Revision": {
      "kind": "uint",
      "min": 1,
      "max": 18446744073709551615
    },
    "Null": {
      "kind": "null"
    },
    "Bool": {
      "kind": "bool"
    },
    "IdentityText": {
      "kind": "text",
      "minCharacters": 1,
      "maxCharacters": 128,
      "maxUtf8Bytes": 512
    },
    "Name": {
      "kind": "text",
      "minCharacters": 1,
      "maxCharacters": 64,
      "maxUtf8Bytes": 256
    },
    "JoinPolicy": {
      "kind": "enum",
      "values": [
        "inviteOnly",
        "application",
        "open"
      ]
    },
    "Visibility": {
      "kind": "enum",
      "values": [
        "private",
        "discoverable"
      ]
    },
    "GroupState": {
      "kind": "enum",
      "values": [
        "active",
        "dissolving",
        "dissolved"
      ]
    },
    "GovernanceState": {
      "kind": "enum",
      "values": [
        "operational",
        "restricted",
        "recoveryRequired",
        "closed"
      ]
    },
    "MembershipState": {
      "kind": "enum",
      "values": [
        "active",
        "suspended",
        "left",
        "removed"
      ]
    },
    "DecisionState": {
      "kind": "enum",
      "values": [
        "pending",
        "accepted",
        "declined",
        "withdrawn",
        "expired",
        "invalidated"
      ]
    },
    "OfferState": {
      "kind": "enum",
      "values": [
        "pending",
        "accepted",
        "withdrawn",
        "expired",
        "invalidated"
      ]
    },
    "Capacity": {
      "kind": "uint",
      "min": 1,
      "max": 64
    },
    "PageSize": {
      "kind": "uint",
      "min": 1,
      "max": 8
    },
    "Offset": {
      "kind": "uint",
      "min": 0,
      "max": 256
    },
    "InvitationTTL": {
      "kind": "uint",
      "min": 60000,
      "max": 604800000
    },
    "OfferTTL": {
      "kind": "uint",
      "min": 60000,
      "max": 900000
    },
    "RestrictionTTL": {
      "kind": "uint",
      "min": 60000,
      "max": 2592000000
    },
    "Decision": {
      "kind": "enum",
      "values": [
        "accept",
        "decline"
      ]
    },
    "ErrorCode": {
      "kind": "enum",
      "values": [
        "NotAuthorised",
        "InvalidRequest",
        "RevisionConflict",
        "CapacityReached",
        "GovernanceBlocked",
        "AssuranceRequired",
        "DependencyUnavailable",
        "Overloaded",
        "ResyncRequired",
        "OperationConflict",
        "OutcomeUnavailable",
        "NotSupported",
        "Expired"
      ]
    },
    "ReceiptState": {
      "kind": "enum",
      "values": [
        "active",
        "suspended",
        "left",
        "removed",
        "pending",
        "accepted",
        "declined",
        "withdrawn",
        "expired",
        "invalidated",
        "dissolving",
        "dissolved",
        "restricted",
        "cleared"
      ]
    },
    "Empty": {
      "kind": "map",
      "fields": {}
    },
    "UserRef": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "domain",
          "type": "IdentityText"
        },
        "1": {
          "name": "tenant",
          "type": "IdentityText"
        },
        "2": {
          "name": "subject",
          "type": "IdentityText"
        }
      }
    },
    "GroupBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        }
      }
    },
    "MemberBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "membershipId",
          "type": "Id"
        },
        "2": {
          "name": "membershipRevision",
          "type": "Revision"
        }
      }
    },
    "InvitationBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "invitationId",
          "type": "Id"
        },
        "2": {
          "name": "invitationRevision",
          "type": "Revision"
        }
      }
    },
    "ApplicationBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "applicationId",
          "type": "Id"
        },
        "2": {
          "name": "applicationRevision",
          "type": "Revision"
        }
      }
    },
    "OfferBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "offerId",
          "type": "Id"
        },
        "2": {
          "name": "offerRevision",
          "type": "Revision"
        }
      }
    },
    "GroupSummary": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "name",
          "type": "Name"
        },
        "2": {
          "name": "joinPolicy",
          "type": "JoinPolicy"
        },
        "3": {
          "name": "visibility",
          "type": "Visibility"
        },
        "4": {
          "name": "capacity",
          "type": "Capacity"
        },
        "5": {
          "name": "lifecycle",
          "type": "GroupState"
        }
      }
    },
    "MembershipView": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "membershipId",
          "type": "Id"
        },
        "1": {
          "name": "groupId",
          "type": "Id"
        },
        "2": {
          "name": "user",
          "type": "UserRef"
        },
        "3": {
          "name": "state",
          "type": "MembershipState"
        },
        "4": {
          "name": "revision",
          "type": "Revision"
        },
        "5": {
          "name": "isSteward",
          "type": "Bool"
        }
      }
    },
    "InvitationView": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "invitationId",
          "type": "Id"
        },
        "1": {
          "name": "groupId",
          "type": "Id"
        },
        "2": {
          "name": "target",
          "type": "UserRef"
        },
        "3": {
          "name": "state",
          "type": "DecisionState"
        },
        "4": {
          "name": "revision",
          "type": "Revision"
        },
        "5": {
          "name": "expiresAt",
          "type": "U64"
        }
      }
    },
    "ApplicationView": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "applicationId",
          "type": "Id"
        },
        "1": {
          "name": "groupId",
          "type": "Id"
        },
        "2": {
          "name": "applicant",
          "type": "UserRef"
        },
        "3": {
          "name": "state",
          "type": "DecisionState"
        },
        "4": {
          "name": "revision",
          "type": "Revision"
        },
        "5": {
          "name": "expiresAt",
          "type": "U64"
        }
      }
    },
    "OfferView": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "offerId",
          "type": "Id"
        },
        "1": {
          "name": "groupId",
          "type": "Id"
        },
        "2": {
          "name": "successorMembershipId",
          "type": "Id"
        },
        "3": {
          "name": "state",
          "type": "OfferState"
        },
        "4": {
          "name": "revision",
          "type": "Revision"
        },
        "5": {
          "name": "expiresAt",
          "type": "U64"
        }
      }
    },
    "Receipt": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "entityId",
          "type": "Id"
        },
        "2": {
          "name": "state",
          "type": "ReceiptState"
        },
        "3": {
          "name": "changeCursor",
          "type": "U64"
        }
      }
    },
    "OwnOperationStatus": {
      "kind": "enum",
      "values": [
        "succeeded",
        "refused",
        "pending",
        "unavailable"
      ]
    },
    "Subscription": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "subscriptionId",
          "type": "Id"
        },
        "1": {
          "name": "groupId",
          "type": "Id"
        },
        "2": {
          "name": "nextCursor",
          "type": "U64"
        }
      }
    },
    "CapabilityType": {
      "kind": "uint",
      "min": 1,
      "max": 34
    },
    "NullableId": {
      "kind": "nullable",
      "of": "Id"
    },
    "NullableRevision": {
      "kind": "nullable",
      "of": "Revision"
    },
    "NullableReceipt": {
      "kind": "nullable",
      "of": "Receipt"
    },
    "NullableError": {
      "kind": "nullable",
      "of": "ErrorCode"
    },
    "MembershipRows": {
      "kind": "array",
      "of": "MembershipView",
      "maxItems": 8
    },
    "InvitationRows": {
      "kind": "array",
      "of": "InvitationView",
      "maxItems": 8
    },
    "ApplicationRows": {
      "kind": "array",
      "of": "ApplicationView",
      "maxItems": 8
    },
    "EnabledTypes": {
      "kind": "array",
      "of": "CapabilityType",
      "maxItems": 34
    },
    "Capabilities": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "profileId",
          "type": "ProfileName"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "enabledTypes",
          "type": "EnabledTypes"
        },
        "3": {
          "name": "schemaDigest",
          "type": "Digest"
        },
        "4": {
          "name": "developmentOnly",
          "type": "TrueBool"
        }
      }
    },
    "ProfileName": {
      "kind": "enum",
      "values": [
        "groups-core-dev-1"
      ]
    },
    "Digest": {
      "kind": "bytes",
      "length": 32
    },
    "GroupSnapshot": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "snapshotId",
          "type": "Id"
        },
        "1": {
          "name": "group",
          "type": "GroupSummary"
        },
        "2": {
          "name": "groupRevision",
          "type": "Revision"
        },
        "3": {
          "name": "authorityEpoch",
          "type": "Revision"
        },
        "4": {
          "name": "cursor",
          "type": "U64"
        },
        "5": {
          "name": "members",
          "type": "MembershipRows"
        },
        "6": {
          "name": "nextOffset",
          "type": "Offset"
        },
        "7": {
          "name": "complete",
          "type": "Bool"
        },
        "8": {
          "name": "expiresAt",
          "type": "U64"
        },
        "9": {
          "name": "governance",
          "type": "GovernanceState"
        }
      }
    },
    "MembershipPage": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "snapshotId",
          "type": "Id"
        },
        "1": {
          "name": "rows",
          "type": "MembershipRows"
        },
        "2": {
          "name": "nextOffset",
          "type": "Offset"
        },
        "3": {
          "name": "complete",
          "type": "Bool"
        },
        "4": {
          "name": "expiresAt",
          "type": "U64"
        }
      }
    },
    "InvitationPage": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "snapshotId",
          "type": "Id"
        },
        "1": {
          "name": "rows",
          "type": "InvitationRows"
        },
        "2": {
          "name": "nextOffset",
          "type": "Offset"
        },
        "3": {
          "name": "complete",
          "type": "Bool"
        },
        "4": {
          "name": "expiresAt",
          "type": "U64"
        }
      }
    },
    "ApplicationPage": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "snapshotId",
          "type": "Id"
        },
        "1": {
          "name": "rows",
          "type": "ApplicationRows"
        },
        "2": {
          "name": "nextOffset",
          "type": "Offset"
        },
        "3": {
          "name": "complete",
          "type": "Bool"
        },
        "4": {
          "name": "expiresAt",
          "type": "U64"
        }
      }
    },
    "RecoveredOutcome": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "status",
          "type": "OwnOperationStatus"
        },
        "2": {
          "name": "receipt",
          "type": "NullableReceipt"
        },
        "3": {
          "name": "error",
          "type": "NullableError"
        },
        "4": {
          "name": "requestDigest",
          "type": "NullableDigest"
        }
      }
    },
    "SnapshotBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "snapshotId",
          "type": "NullableId"
        },
        "2": {
          "name": "offset",
          "type": "Offset"
        },
        "3": {
          "name": "pageSize",
          "type": "PageSize"
        }
      }
    },
    "OwnPageBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "snapshotId",
          "type": "NullableId"
        },
        "1": {
          "name": "offset",
          "type": "Offset"
        },
        "2": {
          "name": "pageSize",
          "type": "PageSize"
        }
      }
    },
    "GetCapabilitiesRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "NullableId"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "Empty"
        }
      }
    },
    "GetCapabilitiesSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "FalseBool"
        },
        "3": {
          "name": "data",
          "type": "Capabilities"
        }
      }
    },
    "CreateGroupBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "name",
          "type": "Name"
        },
        "1": {
          "name": "joinPolicy",
          "type": "JoinPolicy"
        },
        "2": {
          "name": "visibility",
          "type": "Visibility"
        },
        "3": {
          "name": "capacity",
          "type": "Capacity"
        }
      }
    },
    "CreateGroupRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "CreateGroupBody"
        }
      }
    },
    "CreateGroupSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "UpdateGroupBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "name",
          "type": "Name"
        },
        "2": {
          "name": "joinPolicy",
          "type": "JoinPolicy"
        },
        "3": {
          "name": "visibility",
          "type": "Visibility"
        },
        "4": {
          "name": "capacity",
          "type": "Capacity"
        }
      }
    },
    "UpdateGroupRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Revision"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Revision"
        },
        "4": {
          "name": "body",
          "type": "UpdateGroupBody"
        }
      }
    },
    "UpdateGroupSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "GetGroupSummaryRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "GroupBody"
        }
      }
    },
    "GetGroupSummarySuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "FalseBool"
        },
        "3": {
          "name": "data",
          "type": "GroupSummary"
        }
      }
    },
    "GetGroupSnapshotRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "SnapshotBody"
        }
      }
    },
    "GetGroupSnapshotSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "FalseBool"
        },
        "3": {
          "name": "data",
          "type": "GroupSnapshot"
        }
      }
    },
    "ListMyMembershipsRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "OwnPageBody"
        }
      }
    },
    "ListMyMembershipsSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "FalseBool"
        },
        "3": {
          "name": "data",
          "type": "MembershipPage"
        }
      }
    },
    "GetMyMembershipRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "GroupBody"
        }
      }
    },
    "GetMyMembershipSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "FalseBool"
        },
        "3": {
          "name": "data",
          "type": "MembershipView"
        }
      }
    },
    "InviteMemberBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "target",
          "type": "UserRef"
        },
        "2": {
          "name": "ttlMillis",
          "type": "InvitationTTL"
        }
      }
    },
    "InviteMemberRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Revision"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Revision"
        },
        "4": {
          "name": "body",
          "type": "InviteMemberBody"
        }
      }
    },
    "InviteMemberSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "GetInvitationBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "invitationId",
          "type": "Id"
        }
      }
    },
    "GetInvitationRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "GetInvitationBody"
        }
      }
    },
    "GetInvitationSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "FalseBool"
        },
        "3": {
          "name": "data",
          "type": "InvitationView"
        }
      }
    },
    "WithdrawInvitationRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Revision"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Revision"
        },
        "4": {
          "name": "body",
          "type": "InvitationBody"
        }
      }
    },
    "WithdrawInvitationSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "AcceptInvitationRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "InvitationBody"
        }
      }
    },
    "AcceptInvitationSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "DeclineInvitationRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "InvitationBody"
        }
      }
    },
    "DeclineInvitationSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "ApplyToJoinBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        }
      }
    },
    "ApplyToJoinRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "ApplyToJoinBody"
        }
      }
    },
    "ApplyToJoinSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "WithdrawApplicationRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "ApplicationBody"
        }
      }
    },
    "WithdrawApplicationSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "DecideApplicationBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "applicationId",
          "type": "Id"
        },
        "2": {
          "name": "applicationRevision",
          "type": "Revision"
        },
        "3": {
          "name": "decision",
          "type": "Decision"
        }
      }
    },
    "DecideApplicationRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Revision"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Revision"
        },
        "4": {
          "name": "body",
          "type": "DecideApplicationBody"
        }
      }
    },
    "DecideApplicationSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "JoinOpenGroupRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "GroupBody"
        }
      }
    },
    "JoinOpenGroupSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "LeaveGroupRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "MemberBody"
        }
      }
    },
    "LeaveGroupSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "SuspendMemberRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Revision"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Revision"
        },
        "4": {
          "name": "body",
          "type": "MemberBody"
        }
      }
    },
    "SuspendMemberSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "ResumeMemberRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Revision"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Revision"
        },
        "4": {
          "name": "body",
          "type": "MemberBody"
        }
      }
    },
    "ResumeMemberSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "RemoveMemberRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Revision"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Revision"
        },
        "4": {
          "name": "body",
          "type": "MemberBody"
        }
      }
    },
    "RemoveMemberSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "SetAdmissionRestrictionBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "target",
          "type": "UserRef"
        },
        "2": {
          "name": "ttlMillis",
          "type": "RestrictionTTL"
        }
      }
    },
    "SetAdmissionRestrictionRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Revision"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Revision"
        },
        "4": {
          "name": "body",
          "type": "SetAdmissionRestrictionBody"
        }
      }
    },
    "SetAdmissionRestrictionSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "RemoveAdmissionRestrictionBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "restrictionId",
          "type": "Id"
        },
        "2": {
          "name": "restrictionRevision",
          "type": "Revision"
        }
      }
    },
    "RemoveAdmissionRestrictionRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Revision"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Revision"
        },
        "4": {
          "name": "body",
          "type": "RemoveAdmissionRestrictionBody"
        }
      }
    },
    "RemoveAdmissionRestrictionSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "TransferStewardshipBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "successorMembershipId",
          "type": "Id"
        },
        "2": {
          "name": "successorRevision",
          "type": "Revision"
        },
        "3": {
          "name": "ttlMillis",
          "type": "OfferTTL"
        }
      }
    },
    "TransferStewardshipRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Revision"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Revision"
        },
        "4": {
          "name": "body",
          "type": "TransferStewardshipBody"
        }
      }
    },
    "TransferStewardshipSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "GetStewardshipOfferBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "offerId",
          "type": "Id"
        }
      }
    },
    "GetStewardshipOfferRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "GetStewardshipOfferBody"
        }
      }
    },
    "GetStewardshipOfferSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "FalseBool"
        },
        "3": {
          "name": "data",
          "type": "OfferView"
        }
      }
    },
    "AcceptStewardshipRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "OfferBody"
        }
      }
    },
    "AcceptStewardshipSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "WithdrawStewardshipOfferRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Revision"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Revision"
        },
        "4": {
          "name": "body",
          "type": "OfferBody"
        }
      }
    },
    "WithdrawStewardshipOfferSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "BeginDissolutionRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Revision"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Revision"
        },
        "4": {
          "name": "body",
          "type": "GroupBody"
        }
      }
    },
    "BeginDissolutionSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "TrueBool"
        },
        "3": {
          "name": "data",
          "type": "Receipt"
        }
      }
    },
    "GetOperationResultBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "targetOperationId",
          "type": "Id"
        }
      }
    },
    "GetOperationResultRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "GetOperationResultBody"
        }
      }
    },
    "GetOperationResultSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "FalseBool"
        },
        "3": {
          "name": "data",
          "type": "RecoveredOutcome"
        }
      }
    },
    "SubscribeGroupChangesBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "groupId",
          "type": "Id"
        },
        "1": {
          "name": "afterCursor",
          "type": "U64"
        }
      }
    },
    "SubscribeGroupChangesRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "SubscribeGroupChangesBody"
        }
      }
    },
    "SubscribeGroupChangesSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "FalseBool"
        },
        "3": {
          "name": "data",
          "type": "Subscription"
        }
      }
    },
    "UnsubscribeGroupChangesBody": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "subscriptionId",
          "type": "Id"
        }
      }
    },
    "UnsubscribeGroupChangesRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "UnsubscribeGroupChangesBody"
        }
      }
    },
    "UnsubscribeGroupChangesSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "FalseBool"
        },
        "3": {
          "name": "data",
          "type": "Empty"
        }
      }
    },
    "ListMyInvitationsRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "OwnPageBody"
        }
      }
    },
    "ListMyInvitationsSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "FalseBool"
        },
        "3": {
          "name": "data",
          "type": "InvitationPage"
        }
      }
    },
    "QueryApplicationsRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "SnapshotBody"
        }
      }
    },
    "QueryApplicationsSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "FalseBool"
        },
        "3": {
          "name": "data",
          "type": "ApplicationPage"
        }
      }
    },
    "QueryInvitationsRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "SnapshotBody"
        }
      }
    },
    "QueryInvitationsSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "FalseBool"
        },
        "3": {
          "name": "data",
          "type": "InvitationPage"
        }
      }
    },
    "Refused": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "error",
          "type": "ErrorCode"
        },
        "3": {
          "name": "recorded",
          "type": "Bool"
        },
        "4": {
          "name": "retryable",
          "type": "Bool"
        }
      }
    },
    "Unknown": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        }
      }
    },
    "Invalidation": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "generation",
          "type": "Id"
        },
        "1": {
          "name": "subscriptionId",
          "type": "Id"
        },
        "2": {
          "name": "cursor",
          "type": "U64"
        },
        "3": {
          "name": "groupId",
          "type": "Id"
        },
        "4": {
          "name": "groupRevision",
          "type": "Revision"
        },
        "5": {
          "name": "authorityEpoch",
          "type": "Revision"
        }
      }
    },
    "ResyncRequiredEvent": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "generation",
          "type": "Id"
        },
        "1": {
          "name": "subscriptionId",
          "type": "Id"
        }
      }
    },
    "InvitationAvailable": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "generation",
          "type": "Id"
        },
        "1": {
          "name": "groupId",
          "type": "Id"
        },
        "2": {
          "name": "invitationId",
          "type": "Id"
        },
        "3": {
          "name": "invitationRevision",
          "type": "Revision"
        }
      }
    },
    "RestrictionView": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "restrictionId",
          "type": "Id"
        },
        "1": {
          "name": "groupId",
          "type": "Id"
        },
        "2": {
          "name": "target",
          "type": "UserRef"
        },
        "3": {
          "name": "revision",
          "type": "Revision"
        },
        "4": {
          "name": "expiresAt",
          "type": "U64"
        }
      }
    },
    "RestrictionRows": {
      "kind": "array",
      "of": "RestrictionView",
      "maxItems": 8
    },
    "RestrictionPage": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "snapshotId",
          "type": "Id"
        },
        "1": {
          "name": "rows",
          "type": "RestrictionRows"
        },
        "2": {
          "name": "nextOffset",
          "type": "Offset"
        },
        "3": {
          "name": "complete",
          "type": "Bool"
        },
        "4": {
          "name": "expiresAt",
          "type": "U64"
        }
      }
    },
    "QueryAdmissionRestrictionsRequest": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "expectedGroupRevision",
          "type": "Null"
        },
        "3": {
          "name": "expectedAuthorityEpoch",
          "type": "Null"
        },
        "4": {
          "name": "body",
          "type": "SnapshotBody"
        }
      }
    },
    "QueryAdmissionRestrictionsSuccess": {
      "kind": "map",
      "fields": {
        "0": {
          "name": "operationId",
          "type": "Id"
        },
        "1": {
          "name": "generation",
          "type": "Id"
        },
        "2": {
          "name": "recorded",
          "type": "FalseBool"
        },
        "3": {
          "name": "data",
          "type": "RestrictionPage"
        }
      }
    },
    "TrueBool": {
      "kind": "bool",
      "equals": true
    },
    "FalseBool": {
      "kind": "bool",
      "equals": false
    },
    "NullableDigest": {
      "kind": "nullable",
      "of": "Digest"
    }
  },
  "operations": [
    {
      "typeId": 1,
      "name": "GetCapabilities",
      "mode": "query",
      "precondition": "none",
      "requestType": "GetCapabilitiesRequest",
      "successType": "GetCapabilitiesSuccess"
    },
    {
      "typeId": 2,
      "name": "CreateGroup",
      "mode": "mutation",
      "precondition": "create",
      "requestType": "CreateGroupRequest",
      "successType": "CreateGroupSuccess"
    },
    {
      "typeId": 3,
      "name": "UpdateGroup",
      "mode": "mutation",
      "precondition": "group",
      "requestType": "UpdateGroupRequest",
      "successType": "UpdateGroupSuccess"
    },
    {
      "typeId": 4,
      "name": "GetGroupSummary",
      "mode": "query",
      "precondition": "none",
      "requestType": "GetGroupSummaryRequest",
      "successType": "GetGroupSummarySuccess"
    },
    {
      "typeId": 5,
      "name": "GetGroupSnapshot",
      "mode": "query",
      "precondition": "none",
      "requestType": "GetGroupSnapshotRequest",
      "successType": "GetGroupSnapshotSuccess"
    },
    {
      "typeId": 6,
      "name": "ListMyMemberships",
      "mode": "query",
      "precondition": "none",
      "requestType": "ListMyMembershipsRequest",
      "successType": "ListMyMembershipsSuccess"
    },
    {
      "typeId": 7,
      "name": "GetMyMembership",
      "mode": "query",
      "precondition": "none",
      "requestType": "GetMyMembershipRequest",
      "successType": "GetMyMembershipSuccess"
    },
    {
      "typeId": 8,
      "name": "InviteMember",
      "mode": "mutation",
      "precondition": "group",
      "requestType": "InviteMemberRequest",
      "successType": "InviteMemberSuccess"
    },
    {
      "typeId": 9,
      "name": "GetInvitation",
      "mode": "query",
      "precondition": "none",
      "requestType": "GetInvitationRequest",
      "successType": "GetInvitationSuccess"
    },
    {
      "typeId": 10,
      "name": "WithdrawInvitation",
      "mode": "mutation",
      "precondition": "group",
      "requestType": "WithdrawInvitationRequest",
      "successType": "WithdrawInvitationSuccess"
    },
    {
      "typeId": 11,
      "name": "AcceptInvitation",
      "mode": "mutation",
      "precondition": "subject",
      "requestType": "AcceptInvitationRequest",
      "successType": "AcceptInvitationSuccess"
    },
    {
      "typeId": 12,
      "name": "DeclineInvitation",
      "mode": "mutation",
      "precondition": "subject",
      "requestType": "DeclineInvitationRequest",
      "successType": "DeclineInvitationSuccess"
    },
    {
      "typeId": 13,
      "name": "ApplyToJoin",
      "mode": "mutation",
      "precondition": "subject",
      "requestType": "ApplyToJoinRequest",
      "successType": "ApplyToJoinSuccess"
    },
    {
      "typeId": 14,
      "name": "WithdrawApplication",
      "mode": "mutation",
      "precondition": "subject",
      "requestType": "WithdrawApplicationRequest",
      "successType": "WithdrawApplicationSuccess"
    },
    {
      "typeId": 15,
      "name": "DecideApplication",
      "mode": "mutation",
      "precondition": "group",
      "requestType": "DecideApplicationRequest",
      "successType": "DecideApplicationSuccess"
    },
    {
      "typeId": 16,
      "name": "JoinOpenGroup",
      "mode": "mutation",
      "precondition": "subject",
      "requestType": "JoinOpenGroupRequest",
      "successType": "JoinOpenGroupSuccess"
    },
    {
      "typeId": 17,
      "name": "LeaveGroup",
      "mode": "mutation",
      "precondition": "subject",
      "requestType": "LeaveGroupRequest",
      "successType": "LeaveGroupSuccess"
    },
    {
      "typeId": 18,
      "name": "SuspendMember",
      "mode": "mutation",
      "precondition": "group",
      "requestType": "SuspendMemberRequest",
      "successType": "SuspendMemberSuccess"
    },
    {
      "typeId": 19,
      "name": "ResumeMember",
      "mode": "mutation",
      "precondition": "group",
      "requestType": "ResumeMemberRequest",
      "successType": "ResumeMemberSuccess"
    },
    {
      "typeId": 20,
      "name": "RemoveMember",
      "mode": "mutation",
      "precondition": "group",
      "requestType": "RemoveMemberRequest",
      "successType": "RemoveMemberSuccess"
    },
    {
      "typeId": 21,
      "name": "SetAdmissionRestriction",
      "mode": "mutation",
      "precondition": "group",
      "requestType": "SetAdmissionRestrictionRequest",
      "successType": "SetAdmissionRestrictionSuccess"
    },
    {
      "typeId": 22,
      "name": "RemoveAdmissionRestriction",
      "mode": "mutation",
      "precondition": "group",
      "requestType": "RemoveAdmissionRestrictionRequest",
      "successType": "RemoveAdmissionRestrictionSuccess"
    },
    {
      "typeId": 23,
      "name": "TransferStewardship",
      "mode": "mutation",
      "precondition": "group",
      "requestType": "TransferStewardshipRequest",
      "successType": "TransferStewardshipSuccess"
    },
    {
      "typeId": 24,
      "name": "GetStewardshipOffer",
      "mode": "query",
      "precondition": "none",
      "requestType": "GetStewardshipOfferRequest",
      "successType": "GetStewardshipOfferSuccess"
    },
    {
      "typeId": 25,
      "name": "AcceptStewardship",
      "mode": "mutation",
      "precondition": "subject",
      "requestType": "AcceptStewardshipRequest",
      "successType": "AcceptStewardshipSuccess"
    },
    {
      "typeId": 26,
      "name": "WithdrawStewardshipOffer",
      "mode": "mutation",
      "precondition": "group",
      "requestType": "WithdrawStewardshipOfferRequest",
      "successType": "WithdrawStewardshipOfferSuccess"
    },
    {
      "typeId": 27,
      "name": "BeginDissolution",
      "mode": "mutation",
      "precondition": "group",
      "requestType": "BeginDissolutionRequest",
      "successType": "BeginDissolutionSuccess"
    },
    {
      "typeId": 28,
      "name": "GetOperationResult",
      "mode": "query",
      "precondition": "none",
      "requestType": "GetOperationResultRequest",
      "successType": "GetOperationResultSuccess"
    },
    {
      "typeId": 29,
      "name": "SubscribeGroupChanges",
      "mode": "query",
      "precondition": "none",
      "requestType": "SubscribeGroupChangesRequest",
      "successType": "SubscribeGroupChangesSuccess"
    },
    {
      "typeId": 30,
      "name": "UnsubscribeGroupChanges",
      "mode": "query",
      "precondition": "none",
      "requestType": "UnsubscribeGroupChangesRequest",
      "successType": "UnsubscribeGroupChangesSuccess"
    },
    {
      "typeId": 31,
      "name": "ListMyInvitations",
      "mode": "query",
      "precondition": "none",
      "requestType": "ListMyInvitationsRequest",
      "successType": "ListMyInvitationsSuccess"
    },
    {
      "typeId": 32,
      "name": "QueryApplications",
      "mode": "query",
      "precondition": "none",
      "requestType": "QueryApplicationsRequest",
      "successType": "QueryApplicationsSuccess"
    },
    {
      "typeId": 33,
      "name": "QueryInvitations",
      "mode": "query",
      "precondition": "none",
      "requestType": "QueryInvitationsRequest",
      "successType": "QueryInvitationsSuccess"
    },
    {
      "typeId": 34,
      "name": "QueryAdmissionRestrictions",
      "mode": "query",
      "precondition": "none",
      "requestType": "QueryAdmissionRestrictionsRequest",
      "successType": "QueryAdmissionRestrictionsSuccess"
    }
  ],
  "resultTypes": {
    "success": "same typeId as original request",
    "refused": 101,
    "unknown": 102
  },
  "eventTypes": {
    "Invalidation": 1,
    "ResyncRequiredEvent": 2,
    "InvitationAvailable": 3
  },
  "textLengthUnit": "Unicode scalar values; separate UTF-8 byte limits; no implicit normalisation"
}
' ]
]

{ #category : 'state machines' }
CGCoreContract class >> transition: machine from: source event: event guards: guards [
 | spec transition |
 spec := self machines at: machine asString.
 transition := (spec at: 'transitions') detect: [ :each | (each at: 'from') = source asString and: [ (each at: 'event') = event asString ] ] ifNone: [ CGCoreRefusal code: #InvalidRequest recorded: false retryable: false ].
 ((transition at: 'requires') allSatisfy: [ :key | (guards at: key ifAbsent: [ false ]) == true ]) ifFalse: [ CGCoreRefusal code: #GovernanceBlocked recorded: false retryable: false ].
 ^ transition at: 'to'
]

{ #category : 'validation' }
CGCoreContract class >> validate: value type: name [
 | spec kind |
 spec := (self schema at: 'types') at: name.
 kind := spec at: 'kind'.
 (spec includesKey: 'equals') ifTrue: [ self require: value = (spec at: 'equals') ].
 kind = 'null' ifTrue: [ ^ self require: value isNil ].
 kind = 'nullable' ifTrue: [ value ifNil: [ ^ self ]. ^ self validate: value type: (spec at: 'of') ].
 kind = 'bytes' ifTrue: [ ^ self require: (value class = ByteArray and: [ value size = (spec at: 'length') ]) ].
 kind = 'uint' ifTrue: [ ^ self require: (value isInteger and: [ value between: (spec at: 'min') and: (spec at: 'max') ]) ].
 kind = 'bool' ifTrue: [ ^ self require: (value == true or: [ value == false ]) ].
 kind = 'enum' ifTrue: [ ^ self require: ((value isString) and: [ (spec at: 'values') includes: value ]) ].
 kind = 'text' ifTrue: [
  self require: value isString.
  self require: (value allSatisfy: [ :ch | ch codePoint <= 16r10FFFF and: [ (ch codePoint between: 16rD800 and: 16rDFFF) not ] ]).
  self require: (value size between: (spec at: 'minCharacters' ifAbsent: [ 0 ]) and: (spec at: 'maxCharacters')).
  ^ self require: value utf8Encoded size <= (spec at: 'maxUtf8Bytes') ].
 kind = 'map' ifTrue: [
  self require: value isDictionary.
  self require: value keys asSet = ((spec at: 'fields') keys collect: [ :k | k asInteger ]) asSet.
  (spec at: 'fields') keysAndValuesDo: [ :key :field | self validate: (value at: key asInteger) type: (field at: 'type') ]. ^ self ].
 kind = 'array' ifTrue: [
  self require: (value isArray and: [ value size <= (spec at: 'maxItems') ]).
  value do: [ :item | self validate: item type: (spec at: 'of') ]. ^ self ].
 self error: 'Unsupported frozen schema kind'
]
