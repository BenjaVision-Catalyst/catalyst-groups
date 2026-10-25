# Catalyst Groups

Catalyst Groups is for developers building applications with group invitations,
membership, and governance rules that need consistent outcomes. Its current
GT/Pharo core lets you explore those workflows over Catalyst Runtime, with
guarded state changes and recoverable operation results. It is an in-memory
development implementation; production identity, network handlers, and durable
storage are not integrated yet.

## Implemented core

- Scoped, exact `CGUserRef` values; Groups and terminal membership incarnations.
- Invite-only, application and open admission; invitations, applications,
  negative decisions, expiry and invalidation, with no reserved seats.
- Suspend/resume/remove/leave, occupied-seat and history limits, and creator quotas.
- Group-local admission restrictions with renewal, removal and terminal expiry.
- One designated Steward, accepted handover, fresh development assurance,
  restricted/orphaned governance, and dissolution awaiting positive cleanup.
- A serial state owner with prepared replacement publication, operation-ID/digest
  binding, retained outcomes, permission-filtered recovery, audit and journal.
- Request/invitation token buckets, generation/reset fences, clock-fault refusal
  and synthetic lifecycle stream continuity checks.
- A narrow Runtime service/capability and copied local development WorkUnits.
- An optional, explicitly synthetic three-service Runtime bridge with verified
  originating work, asynchronous identity decisions, bounded pending ownership,
  duplicate coalescing and fenced callbacks. Operation recovery uses the same path.

Relationship evidence, team building, units/custom roles, shared resources and
native clients remain separate work. There is no standalone Groups C++ library.

## Installation

Install Catalyst through [BVC](https://github.com/BenjaVisionPro/bvc#install).
With BVC installed, create and launch a local development project:

```sh
bvc init MyCatalystProject
cd MyCatalystProject
bvc run
```

BVC builds and launches the GT/Pharo DevKit without starting a GemStone deployment.
Your project's BVC configuration selects the components and startup packages.
Package-loading details below describe development inside that environment.

## Packages

| Package | Responsibility |
| --- | --- |
| Catalyst-Groups-Core | Domain records, frozen schema/profile mirrors, canonical intent digest, state owner and guarded mutations. |
| Catalyst-Groups-Development | Explicit synthetic identity/lifecycle fixtures and GT source export/verification tools. |
| Catalyst-Groups-Runtime | CRWorkerService integration, narrow capability and local development command WorkUnit. |
| Catalyst-Groups-GT | Inspector views on detached development records and state. |
| Catalyst-Groups-Tests | SUnit scenarios and object-returning GT examples. |
| BaselineOfCatalystGroups | Local package loading into an already prepared GT/Runtime image. |

The baseline expects Catalyst Runtime, NeoJSON, UUID, SHA256, SUnit and GT tooling
already loaded. It does not fetch or qualify those dependencies. BVC project
configuration must supply them and select the Groups baseline. The Metacello
`Development` group is the default package group for this development core.

The rebuilt SuperGame image loaded the original core successfully. The expanded
P1 bridge passes in that live image; a user-run rebuild of this revision remains
the final clean-load qualification gate. Do not close or rebuild a live image
until pending source has been recovered and verified through GT MCP.

## Tests and examples

```smalltalk
CGCoreTests suite run.
CGCoreRuntimeTests suite run.
CGCoreExamples new invitationAccepted.
CGCoreExamples new acceptedStewardship.
CGCoreExamples new orphanedGovernance.
CGCoreExamples new publishedOutcomeAfterLostReply.
CGCoreRuntimeExamples new asynchronousCreation.
CGCoreRuntimeExamples new asynchronousMembershipAndGovernance.
CGCoreRuntimeExamples new expiredDecisionCannotCompleteReplacement.
```

Verified on 25 October 2026: **88 SUnit tests and 12 distinct GT examples passed**.
These include all 75 frozen valid values/canonical encodings, 34 request digests,
14 invalid values and 198 transition/guard scenarios. Compound behavioral tests
exercise concurrency at capacity, terminal incarnations, rights, source-fact
copy/tamper refusal, expiry, stale authority, lost replies and interrupted publication.
The 256-incarnation test has an explicit 30-second limit; this is correctness
evidence, not a deployment latency benchmark.

See [execution evidence](evidence/p1-gt-2026-10-25.json) for the source hashes and
scope of the original core, and [P1 review evidence](evidence/p1-closeout-gt-2026-10-25.json)
for this revision. Frozen canonical inputs remain in the workspace's
`Groups/contracts/groups-core-dev-1/` bundle; the compiled mirrors were checked
for exact value parity. The frozen manifest is unchanged.

## Execution and security boundary

`CGCoreOwner` owns its private graph under one local mutex. Drafts copy mutable
domain records; existing outcomes and prior audit/journal entries are append-only.
Only a completely prepared state reference is published. Before-publication
interruption preserves the old domain/outcome/audit/journal; after-publication
reply loss recovers the recorded intent instead of executing it again.

`CGDevelopmentIdentities` is a deliberately synthetic adapter. Its caller-selected
development actor is not authenticated network ingress, MFA or delegated Runtime
authority. Issued lifecycle facts are identity-registered, one-use and bound to
their original content. Their baseline is a development fixture, not a production
Users resynchronisation protocol. Diagnostic snapshots expose detached internal
state for test accounts and must not become client queries.

The optional development bridge uses three distinct real queue-backed Runtime
workers: registered ingress, Groups and development Users. Private identity
registries bind exact original/check/callback WorkUnits to the actor, invocation
ID, operation/digest, purpose, service identities/activations and source clock
generation. Copied values cannot introduce authority. The synthetic actor entry
point is disabled on the Groups service while this bridge is configured.

Only one pending check runs for a duplicate intent; conflicts preserve its owner.
The 64-input bound includes duplicate waiters. A five-second deadline is checked
again at publication. Stop/reset/observed lifecycle changes retire pending work;
late callbacks cannot complete replacement attempts. Uncertain publication remains
unknown and scoped operation recovery reads the original result/digest. Queries
do not create mutation outcomes. Original-route network replies are P2 work.

Users decisions are fixture projections, not real authenticated sessions or MFA.
Contact/admission flags are safety-policy decisions, not relationship evidence.
Groups rechecks its state and observed security revisions after the asynchronous
decision. There is no cross-service transaction or instantaneous revocation claim.
Internal expiry/cleanup facts are driven explicitly; production scheduling and
delivery fences are not supplied here.

Only validated value encoding and intent hashing are implemented. An untrusted
CBOR decoder, 34 operation receive bindings/result codecs, permissioned leased
queries, subscriptions and actual Users/Connect/client workflows remain later work.
Local outcome/diagnostic objects are not wire result DTOs. Codec/receive budgets,
deployment performance, the expanded revision's clean-image load and persistence
are not qualified. The Development baseline now declares its dependency on the
Groups Runtime package; Runtime's GT test support must already be loaded for the
queue-backed examples.

Source round-trip verification can be repeated without loading disk source:

```smalltalk
CGCoreDevelopmentTools verifyExportAt:
    '/path/to/CatalystGroups'.
```

The exporter requires a clean, unregistered destination and refuses to overwrite
existing package directories. Keep the image open until recovery is verified.

## License

This repository is licensed under the [Catalyst Developer License](LICENSE).

Each developer using Catalyst for development needs an active
BenjaVision-Catalyst subscription: **$5 per month, billed annually at $60 per
developer**, including access to the BenjaVision-Catalyst repository. New products,
updates, bug fixes, and recompilation require active developer subscriptions.
Automated build machines do not need separate subscriptions.

Products lawfully built during active subscriptions may continue to be used,
hosted, sold, and distributed indefinitely without runtime royalties. Customers
and operators do not need subscriptions solely to use or distribute those builds.
Commercial and proprietary products are permitted; this license does not require
you to publish your own source code.

Existing license grants and separately licensed third-party material remain
unaffected. See [LICENSE](LICENSE) for the complete terms.
