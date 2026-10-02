# Document And Image Framework Guide

Documents and images are semantic subtrees and metadata in the main
accessibility tree, not separate document or rendering trees.

## Document Semantics

Documents expose format-neutral structure: article, section, heading,
paragraph, list, table, figure, caption, footnote, navigation, header, footer,
form, landmarks, embedded objects, language, title, author, subject, version,
revision, creation/modification metadata, and pagination where available.

Heading levels are semantic heading metadata. A nonzero heading level is valid
only on a `Heading` document role; non-heading roles keep heading level `0`.
Pagination is optional. When a document supplies `Page_Count`, `Current_Page`
must be within that declared range; documents without pagination keep both
values at `0`. Pagination metadata applies only to structural document blocks,
not annotations or embedded objects.

## Incremental Documents

Documents may load incrementally or grow as streams. Providers should publish
typed document and tree events as content becomes available.
Document controls implement `A11y.Documents.Document_Provider`. Its safe
metadata query validates role, heading, pagination, landmark, and bounded text
metadata, and contains provider exceptions as empty document metadata with a
structured `Internal_Error` result.
Invalid provider metadata is also normalized to empty document metadata before
native projection, while preserving the structured validation failure.

## Image Semantics

Images distinguish informative and decorative content. Informative images may
carry alternative text, long description, caption, category, intrinsic
dimensions, actions, and ordinary child nodes for maps, charts, diagrams, or
interactive regions.
Image controls implement `A11y.Images.Image_Provider`. Its safe metadata query
validates the returned metadata and contains provider exceptions as decorative,
non-exposed metadata with a structured `Internal_Error` result.
Invalid provider metadata is also normalized to decorative, non-exposed
metadata before native projection, while preserving the structured validation
failure.

When intrinsic dimensions are present, both width and height must be positive.
Use absent intrinsic dimensions for unknown or not-applicable image size.

## Decorative Images

Decorative images should normally be omitted from the accessibility tree.
Decorative image metadata must not carry alternative text, long descriptions,
or captions; use an informative or structured image kind when text alternatives
are semantically meaningful.
Backends must not expose image buffers or rendering formats.

## No Automatic Description

The library does not perform OCR or AI image description. Applications may
supply generated descriptions as ordinary semantic text when appropriate.
