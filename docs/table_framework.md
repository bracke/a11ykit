# Table Framework Guide

Tables are structural semantics layered over ordinary accessible nodes. Rows,
columns, headers, and cells are still normal nodes with stable identity.

## Cell Identity

Cells must not be identified solely by row and column. Every exposed cell has a
stable `Node_Id`, and merged cells are represented once with proper row and
column spans. Materialized cell spans must not overlap. Table event payload
validation rejects cell changes whose item `Node_Id` is the table `Node_Id`.

## Coordinates

The framework distinguishes logical and displayed coordinates, row and column
counts, displayed rows and columns, reverse lookup, current cell, visible rows,
visible columns, and sorting/filtering metadata.
`Configure` sets logical row and column counts and resets displayed counts to
match them. `Configure_Displayed` records filtered or currently presented row
and column counts separately, rejecting values larger than the logical table
without mutating the previous displayed dimensions.
Visible row and column ranges are display-coordinate ranges inside the
displayed dimensions. `Configure_Visible` records the currently visible window
without materializing those rows or cells, and rejects out-of-bounds ranges
without mutating the previous visible ranges.
The current cell is optional metadata stored as a stable `Node_Id`.
`Set_Current_Cell` validates that the node resolves to a materialized table cell
before mutation; missing, invalid, or stale node identities return
`Node_Unavailable` and leave the previous current cell unchanged.
`Clear_Current_Cell` removes the metadata without changing focus, active
descendant, current item, or selection.
Sort metadata records a neutral sort order and an optional stable sort-key
`Node_Id`. Sorted states require a valid key node; `Clear_Sort` returns the
table to `not-sorted` and clears the key. Sorting metadata describes
application semantics only: it does not rename rows, derive row identity from
display positions, or imply selection, focus, or current-cell changes.
`Resolve_Coordinates` is the result-bearing reverse lookup for backend and
provider code that must distinguish a real `(0,0)` cell from a missing or stale
cell identity.

## Virtual Tables

Virtual or very large tables must not eagerly materialize all cells. Providers
answer bounded counts, indexed lookup, spans, headers, and visible ranges.
Table controls implement `A11y.Tables.Table_Provider`. Safe provider helpers
preserve lazy provider-specific cell and reverse-coordinate resolution while
validating provider table snapshots, successful resolved cell identities, and
spans centrally. Snapshot validation checks displayed and visible ranges,
capacity, materialized cell identity, spans, overlap, current-cell metadata,
and sort-key consistency before native projection. Sparse
`Node_Unavailable` results are preserved, invalid reverse-lookup identities are
rejected before provider dispatch, and provider exceptions are contained as
empty references.

## Selection And Editing

Table selection integrates with the Selection Framework. Cell editing is
provided through Text and Value capabilities on ordinary cell nodes.

## Native Projection

Backends map table semantics to AT-SPI Table/TableCell, UIA Grid/Table
patterns, or NSAccessibility table/outline attributes only for supported and
tested operations. The current backend-private router slice exposes current
cell and sort metadata on Linux (`GetCurrentCell`, `GetSortOrder`,
`GetSortKey`), Windows UIA, and macOS NSAccessibility; node-valued metadata is
filtered through the same projection policy as ordinary table cells.
