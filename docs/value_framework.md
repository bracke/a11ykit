# Value Framework Guide

The Value Framework represents semantic values without forcing all values into
floating point.

## Value Kinds

Values may be integer, fixed point, floating point, exact decimal, ranged,
discrete, enumerated, Boolean-like, unknown, indeterminate, bounded, or
unbounded.

## Range Metadata

Range values carry optional minimum, maximum, small increment, large/page
increment, units, precision, read-only/writable access, and formatted
presentation text.
`Value_Metadata.Presentation_Text` is application-supplied semantic text and is
validated with the same `Text_Returned` bound as unit labels, so backends do not
format exact or indeterminate values independently.

Known increments must be numeric and strictly positive. When both small and
large increments are known, the large increment must not be smaller than the
small increment.

Known numeric current, bounds, and increment fields in one metadata record must
use the same semantic numeric kind. This avoids backend mappers comparing exact
integer/decimal values through lossy floating-point conversion before native
projection. Integer comparisons and same-scale exact-decimal comparisons are
performed directly during validation. Cross-scale exact-decimal comparisons are
also performed in integer space when the required power-of-ten scaling is
bounded by `Long_Long_Integer`; overflow-prone comparisons fail closed as
invalid ranges rather than falling back to approximate native floating-point.
Native floating-point conversion remains an explicit backend projection step.

## Precision

Backends diagnose precision loss when native APIs require floating-point
conversion. Unknown or indeterminate values must not be fabricated as numeric
zero.

## Write Requests

Writable value changes become typed semantic requests routed through the
dispatcher/provider contract. Backends do not mutate semantic value state
directly.
Native numeric write requests use `Validate_Numeric_Set_Request`, which first
validates the committed metadata and resource limits, then rejects read-only
values, nonnumeric native inputs, and candidate values outside the declared
semantic range before any provider mutation can be requested.
`Set_Current_Safely` also rejects invalid target `Node_Id` values before calling
the provider, so native write paths cannot deliver malformed object identities
to application code.

## Provider Contract

Controls with value semantics implement `A11y.Values.Value_Provider`.
`Current_Metadata` returns the authoritative semantic value metadata.
`Set_Current` receives validated semantic value requests and remains responsible
for updating application state through the ordinary semantic update path.
`Current_Metadata_Safely` validates provider metadata and normalizes invalid or
exceptional metadata to read-only unknown values. `Set_Current_Safely` contains
provider exceptions and validates writable numeric requests before calling the
provider.

## Resource Limits

Formatted value text, units, native strings, and native arrays are bounded by
the shared resource-limit configuration.
