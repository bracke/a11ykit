with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

package body A11y_Documentation_Report is
   use Ada.Strings.Unbounded;

   type Document_Record is record
      Path : String (1 .. 48);
      Marker_1 : String (1 .. 64);
      Marker_2 : String (1 .. 64);
      Marker_3 : String (1 .. 64);
   end record;

   function Pad (Value : String; Size : Positive) return String is
      Result : String (1 .. Size) := [others => ' '];
      Last : constant Natural := Natural'Min (Value'Length, Size);
   begin
      if Last > 0 then
         Result (1 .. Last) := Value (Value'First .. Value'First + Last - 1);
      end if;
      return Result;
   end Pad;

   function Trimmed (Value : String) return String is
      Last : Natural := Value'Last;
   begin
      while Last >= Value'First and then Value (Last) = ' ' loop
         if Last = Value'First then
            return "";
         end if;
         Last := Last - 1;
      end loop;
      return Value (Value'First .. Last);
   end Trimmed;

   function Q (Value : String) return String is
      Result : Unbounded_String;
   begin
      Append (Result, '"');
      for Ch of Value loop
         if Ch = '"' then
            Append (Result, "\""");
         elsif Ch = '\' then
            Append (Result, "\\");
         elsif Character'Pos (Ch) < 32 then
            Append (Result, ' ');
         else
            Append (Result, Ch);
         end if;
      end loop;
      Append (Result, '"');
      return To_String (Result);
   end Q;

   function Repository_Path (Path : String) return String is
      Parent_Path : constant String := "../" & Path;
   begin
      if Ada.Directories.Exists (Path) then
         return Path;
      elsif Ada.Directories.Exists (Parent_Path) then
         return Parent_Path;
      else
         return Path;
      end if;
   end Repository_Path;

   function Item
     (Path : String;
      Marker_1 : String;
      Marker_2 : String;
      Marker_3 : String) return Document_Record is
     ((Path => Pad (Path, 48),
       Marker_1 => Pad (Marker_1, 64),
       Marker_2 => Pad (Marker_2, 64),
       Marker_3 => Pad (Marker_3, 64)));

   Documents : constant array (Positive range <>) of Document_Record :=
     [Item
        ("README.md",
         "## Packages",
         "## Backend Status",
         "tests/bin/release_check"),
      Item
        ("docs/architecture.md",
         "## Dependency Direction",
         "## Conformance",
         "## Native Backend Status"),
      Item
        ("docs/quickstart.md",
         "## Provider Setup",
         "## Backend Selection",
         "## Protected Text"),
      Item
        ("docs/security.md",
         "## Protected Text",
         "## Native Boundaries",
         "## Resource Limits"),
      Item
        ("docs/testing.md",
         "## Semantic Tests",
         "## Release Gates",
         "## Native Qualification"),
      Item
        ("docs/conformance.md",
         "## Support Levels",
         "## Capability Matrix",
         "## Native Claims"),
      Item
        ("docs/backend_authoring.md",
         "## Dependency Direction",
         "## Native Identity",
         "## Conformance"),
      Item
        ("docs/linux_atspi.md",
         "## Bus Lifecycle",
         "## Method Routing",
         "## Transport Status"),
      Item
        ("docs/windows_uia.md",
         "## Provider Boundary",
         "## Properties And Patterns",
         "## Transport Status"),
      Item
        ("docs/macos_nsaccessibility.md",
         "## Main Thread",
         "## Attributes And Actions",
         "## Transport Status"),
      Item
        ("docs/provider_guide.md",
         "## Core Node Contract",
         "## Capability Providers",
         "## Virtual Nodes"),
      Item
        ("docs/tree_lifecycle.md",
         "## Tree Invariants",
         "## Lifecycle States",
         "## Exposure Policy"),
      Item
        ("docs/threading_dispatcher.md",
         "## Dispatcher Contract",
         "## Timeouts",
         "## Reentrancy"),
      Item
        ("docs/events.md",
         "## Event Envelope",
         "## Commit Order",
         "## Shutdown"),
      Item
        ("docs/relations.md",
         "## Canonical Directions",
         "## Target Validity",
         "## Native Projection"),
      Item
        ("docs/actions.md",
         "## Action Discovery",
         "## Preconditions",
         "## Security"),
      Item
        ("docs/text_framework.md",
         "## Position Model",
         "## Protected Text",
         "## Native Conversion"),
      Item
        ("docs/value_framework.md",
         "## Value Kinds",
         "## Precision",
         "## Resource Limits"),
      Item
        ("docs/selection_framework.md",
         "## Selection Modes",
         "## Stable Identity",
         "## Native Projection"),
      Item
        ("docs/table_framework.md",
         "## Cell Identity",
         "## Virtual Tables",
         "## Native Projection"),
      Item
        ("docs/document_image_framework.md",
         "## Document Semantics",
         "## Image Semantics",
         "## No Automatic Description"),
      Item
        ("docs/window_surface.md",
         "## Surface Kinds",
         "## Ownership And Modality",
         "## Native Projection"),
      Item
        ("docs/resource_limits.md",
         "## Shared Limits",
         "## Overflow Behavior",
         "## Testing"),
      Item
        ("docs/diagnostics.md",
         "## Diagnostic Records",
         "## Categories",
         "## Native Boundaries"),
      Item
        ("docs/troubleshooting.md",
         "## Build Failures",
         "## Release Gate Failures",
         "## Native Backend Unavailable"),
      Item
        ("docs/contributor.md",
         "## Build Discipline",
         "## Change Scope",
         "## Native Claims"),
      Item
        ("docs/release.md",
         "## Required Commands",
         "## Release Gate",
         "## Failure Policy"),
      Item
        ("docs/api_reference.md",
         "## Semantic Packages",
         "## Provider Packages",
         "## Backend Packages"),
      Item
        ("docs/toolkit_adapter.md",
         "## Semantic Mapping",
         "## Dispatcher Integration",
         "## Exposure Policy"),
      Item
        ("docs/ai_implementation.md",
         "## Build Rule",
         "## Release Tools",
         "## Known Gaps")];

   function File_Contains (Path : String; Needle : String) return Boolean is
      File : Ada.Text_IO.File_Type;
      Actual_Path : constant String := Repository_Path (Path);
   begin
      if not Ada.Directories.Exists (Actual_Path) then
         return False;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Actual_Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            if Ada.Strings.Fixed.Index (Line, Needle) /= 0 then
               Ada.Text_IO.Close (File);
               return True;
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);
      return False;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return False;
   end File_Contains;

   function Present (Document : Document_Record) return Boolean is
     (Ada.Directories.Exists (Repository_Path (Trimmed (Document.Path))));

   function Complete (Document : Document_Record) return Boolean is
     (Present (Document)
      and then File_Contains
        (Trimmed (Document.Path), Trimmed (Document.Marker_1))
      and then File_Contains
        (Trimmed (Document.Path), Trimmed (Document.Marker_2))
      and then File_Contains
        (Trimmed (Document.Path), Trimmed (Document.Marker_3)));

   function Document_Count return Natural is (Documents'Length);

   function All_Required_Content_Present return Boolean is
   begin
      for Document of Documents loop
         if not Complete (Document) then
            return False;
         end if;
      end loop;
      return True;
   end All_Required_Content_Present;

   function Markdown return String is
      Report : Unbounded_String :=
        To_Unbounded_String
          ("# a11y Documentation Report" & ASCII.LF & ASCII.LF
           & "| Path | Marker 1 | Marker 2 | Marker 3 | Status |"
           & ASCII.LF
           & "| --- | --- | --- | --- | --- |" & ASCII.LF);
   begin
      for Document of Documents loop
         Append
           (Report,
            "| "
            & Trimmed (Document.Path)
            & " | "
            & Trimmed (Document.Marker_1)
            & " | "
            & Trimmed (Document.Marker_2)
            & " | "
            & Trimmed (Document.Marker_3)
            & " | "
            & (if Complete (Document) then "present" else "missing")
            & " |"
            & ASCII.LF);
      end loop;
      return To_String (Report);
   end Markdown;

   function JSON return String is
      Report : Unbounded_String :=
        To_Unbounded_String
          ("{" & ASCII.LF
           & "  ""schema"": "
           & Q (Schema)
           & "," & ASCII.LF
           & "  ""document_count"": "
           & Natural'Image (Document_Count)
           & "," & ASCII.LF
           & "  ""complete"": "
           & (if All_Required_Content_Present then "true" else "false")
           & "," & ASCII.LF
           & "  ""documents"": [" & ASCII.LF);
   begin
      for Index in Documents'Range loop
         declare
            Document : Document_Record renames Documents (Index);
            Suffix : constant String :=
              (if Index = Documents'Last then "" else ",");
         begin
            Append
              (Report,
               "    {""path"": "
               & Q (Trimmed (Document.Path))
               & ", ""marker_1"": "
               & Q (Trimmed (Document.Marker_1))
               & ", ""marker_2"": "
               & Q (Trimmed (Document.Marker_2))
               & ", ""marker_3"": "
               & Q (Trimmed (Document.Marker_3))
               & ", ""present"": "
               & (if Present (Document) then "true" else "false")
               & ", ""complete"": "
               & (if Complete (Document) then "true" else "false")
               & "}" & Suffix & ASCII.LF);
         end;
      end loop;
      Append (Report, "  ]" & ASCII.LF & "}" & ASCII.LF);
      return To_String (Report);
   end JSON;
end A11y_Documentation_Report;
