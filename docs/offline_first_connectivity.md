# InvoiceEasy Offline-First Connectivity Architecture

This implementation is intentionally structured so the connectivity layer can be
ported to Farmora later without copying InvoiceEasy business logic.

## Layers

```text
ConnectivityService
        |
        v
ConnectivityProvider
        |
        +---- global connectivity UX
        |
        +---- SyncService
                  |
                  +---- SyncQueue
                  |
                  +---- repositories
                  |
                  +---- Supabase
```

## ConnectivityService

`lib/services/connectivity_service.dart` combines:

1. `connectivity_plus` transport detection.
2. An actual HTTP reachability probe.
3. App lifecycle resume checks.
4. A lightweight periodic reachability check.
5. `checking`, `online`, and `offline` states.

`connectivity_plus` alone is deliberately not treated as proof of internet
access. The HTTP probe verifies that a network request can actually reach an
external/backend endpoint.

## SyncService

`SyncService` listens to both connectivity and the persistent queue.

- Offline: no cloud request is attempted.
- Local mutation while offline: data is saved immediately and queued.
- Local mutation while online: the queue automatically triggers sync.
- Offline -> online: sync starts automatically.
- Multiple triggers: `_running` prevents duplicate sync runs.
- Manual retry: `retryNow()` clears retry delays and starts sync.

## Queue

`SyncQueue` is persistent through `SharedPreferences` and stores:

- entity
- record id
- operation
- payload
- mutation timestamp
- attempt count
- last error
- next retry time
- permanent failure flag

The queue is coalesced by entity + record id, so repeated edits do not create
an unbounded list of stale mutations.

## Conflict policy

InvoiceEasy keeps its existing last-write-wins strategy. Local pending mutation
timestamps are compared with cloud `updated_at` timestamps. Cloud tombstones
are preserved so deleted records do not reappear during a later pull.

## Farmora reuse

For Farmora, the reusable pieces should be copied/adapted as infrastructure:

- `connectivity_service.dart`
- `sync_status.dart`
- `sync_queue.dart`
- the connectivity provider pattern
- the global connectivity/sync banner pattern
- the SyncService locking/retry lifecycle pattern

Farmora-specific repositories, entities, and Supabase tables should remain in
Farmora. The connectivity layer should not contain InvoiceEasy models or
business rules.
