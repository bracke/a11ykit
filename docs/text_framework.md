# Unicode And Text Framework Guide

The Text Framework exposes text semantics without tying public APIs to UTF-8
bytes, UTF-16 code units, or a native platform text range type.

## Position Model

High-level APIs use opaque text positions and ranges. Backends may convert to
code points, grapheme clusters, or UTF-16 offsets only in backend-private
conversion layers.
Directly constructed ranges are valid only when their start and length can be
represented without overflow; invalid ranges return no last position.
Backends must also validate positions and ranges against the current content
length before projecting them to native offsets. A caret at the end of the text
is valid; a caret beyond the current content length is an invalid range.

`A11y.Text.Grapheme_Cluster_Count` and `Grapheme_Cluster_Range` provide the
portable cluster-level entry point. They validate the requested cluster range
against configured text-return limits and return the existing opaque
code-point-backed `Text_Range`, so backend mappers can share one neutral range
model before converting to AT-SPI, UIA, or NSAccessibility offsets. The current
central boundary rules cover combining marks, variation selectors, emoji
modifiers, zero-width-joiner sequences, and regional-indicator pairs.
`Slice_Grapheme_Clusters` and `Validate_Grapheme_Edit_Request` use that same
central conversion for content-backed snapshots. They keep protected-text,
read-only, replacement-size, and range validation in the common model while
returning the existing opaque edit range expected by providers.

## Range Queries

Small range retrieval should be bounded by requested output length and must not
copy entire large documents. Providers should support streamed or chunked access
when documents are large.
Text controls implement `A11y.Text.Text_Provider`. `Text_Range_Safely` validates
protected-text policy, code-point range bounds, and resource limits before
calling provider range retrieval, and contains provider exceptions as empty
structured failures.
Provider text replies are validated again after the callback. A provider that
returns more code points than the requested bounded range is treated as an
invalid semantic snapshot and no text is projected to native backends.

Editable text controls implement `A11y.Text.Editable_Text_Provider`.
`Apply_Edit_Safely` validates protected text, read-only state, range semantics,
replacement bounds, and target `Node_Id` validity before requesting provider
mutation.

## Protected Text

Protected text is never exposed through text ranges, value properties,
diagnostics, snapshots, selection payloads, text counts, native offset
conversion, caret metadata, or text mutation events. Until a backend has an
explicit native secure-field policy, protected text queries return
`Permission_Denied` rather than length or caret metadata.

## Mutation Events

Insert, remove, replace, caret movement, selection, and attribute changes use
typed event payloads. Distinct text mutations are ordering-sensitive and are not
coalesced. Insert and replace requests must carry non-empty replacement text;
empty insert or replace requests are rejected as malformed no-op mutations.
Whole-text set requests use no range (`Start = 0`, `Count = 0`); nonzero range
arguments are rejected as malformed requests.

## Native Conversion

Windows and macOS UTF-16 conversion stays backend-private. Conversion must
handle supplementary-plane characters, combining marks, bidi text, and stale
range ownership safely.
