# Threading And Dispatcher Guide

Provider implementations are not required to be thread-safe. Native backends
must route calls into application/provider code through a configured dispatcher.

## Dispatcher Contract

The dispatcher supports synchronous property and tree queries, action
invocations, asynchronous semantic updates, cancellation, shutdown rejection,
reentrancy detection, and an already-on-dispatch-thread fast path.

## Locking

Backends and registries must not hold global locks while invoking provider
callbacks. Native boundary code resolves and pins session or registry entries,
then releases broad locks before dispatching into application code.

## Timeouts

Timeout categories distinguish simple property queries, tree navigation,
geometry, text, action invocation, window operations, and shutdown. Timeout
results are structured and leave backend/native objects valid. The dispatcher
centralizes elapsed-time classification through `Has_Timed_Out`, which compares
hostkit- or adapter-measured elapsed milliseconds against the configured
resource-limit kind for the call. The conformance identifier is
`dispatcher.timeout.classification`.

## Cancellation

Cancellation tokens are checked before provider mutation and before expensive
native-facing query paths. Cancelled operations return structured results
rather than crossing native boundaries as exceptions.

## Reentrancy

The dispatcher records reentrancy so toolkit adapters can reject unsafe nested
calls. `Immediate_Dispatcher` rejects ordinary nested dispatch with `Busy`, and
exposes an explicit already-on-dispatch-thread fast path for adapter code that
has already entered the dispatch context and knows inline execution is safe.
The inline fast path also has a token-aware form; cancelled cancellable calls
return `Cancelled` before invoking provider code.
