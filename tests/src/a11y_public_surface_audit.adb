with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Directories;

package body A11y_Public_Surface_Audit is
   use Ada.Strings.Unbounded;

   type Spec_Path_Array is array (Positive range <>) of Unbounded_String;

   Spec_Paths : constant Spec_Path_Array :=
     [To_Unbounded_String ("src/a11y.ads"),
      To_Unbounded_String ("src/a11y-actions.ads"),
      To_Unbounded_String ("src/a11y-backends.ads"),
      To_Unbounded_String ("src/a11y-capabilities.ads"),
      To_Unbounded_String ("src/a11y-diagnostics.ads"),
      To_Unbounded_String ("src/a11y-dispatchers.ads"),
      To_Unbounded_String ("src/a11y-documents.ads"),
      To_Unbounded_String ("src/a11y-event_queues.ads"),
      To_Unbounded_String ("src/a11y-event_subscriptions.ads"),
      To_Unbounded_String ("src/a11y-events.ads"),
      To_Unbounded_String ("src/a11y-geometry.ads"),
      To_Unbounded_String ("src/a11y-images.ads"),
      To_Unbounded_String ("src/a11y-localization.ads"),
      To_Unbounded_String ("src/a11y-live_regions.ads"),
      To_Unbounded_String ("src/a11y-native_identity.ads"),
      To_Unbounded_String ("src/a11y-node_keys.ads"),
      To_Unbounded_String ("src/a11y-node_ids.ads"),
      To_Unbounded_String ("src/a11y-nodes.ads"),
      To_Unbounded_String ("src/a11y-platforms.ads"),
      To_Unbounded_String ("src/a11y-properties.ads"),
      To_Unbounded_String ("src/a11y-registry.ads"),
      To_Unbounded_String ("src/a11y-relations.ads"),
      To_Unbounded_String ("src/a11y-resource_limits.ads"),
      To_Unbounded_String ("src/a11y-results.ads"),
      To_Unbounded_String ("src/a11y-roles.ads"),
      To_Unbounded_String ("src/a11y-selection.ads"),
      To_Unbounded_String ("src/a11y-sessions.ads"),
      To_Unbounded_String ("src/a11y-states.ads"),
      To_Unbounded_String ("src/a11y-tables.ads"),
      To_Unbounded_String ("src/a11y-text.ads"),
      To_Unbounded_String ("src/a11y-trees.ads"),
      To_Unbounded_String ("src/a11y-trees-exposure_views.ads"),
      To_Unbounded_String ("src/a11y-values.ads"),
      To_Unbounded_String ("src/a11y-windows.ads"),
      To_Unbounded_String ("src/a11ykit.ads"),
      To_Unbounded_String ("src/a11ykit-provider.ads"),
      To_Unbounded_String ("src/a11ykit-tree.ads")];

   function Q (Value : String) return String is
      Result : Unbounded_String;
   begin
      Append (Result, '"');
      for Ch of Value loop
         case Ch is
            when '"' =>
               Append (Result, "\""");
            when '\' =>
               Append (Result, "\\");
            when Character'Val (8) =>
               Append (Result, "\b");
            when Character'Val (9) =>
               Append (Result, "\t");
            when Character'Val (10) =>
               Append (Result, "\n");
            when Character'Val (12) =>
               Append (Result, "\f");
            when Character'Val (13) =>
               Append (Result, "\r");
            when others =>
               if Character'Pos (Ch) < 32 then
                  Append (Result, ' ');
               else
                  Append (Result, Ch);
               end if;
         end case;
      end loop;
      Append (Result, '"');
      return To_String (Result);
   end Q;

   function Spec_Count return Natural is (Spec_Paths'Length);
   function Forbidden_Token_Count return Natural is (17);

   function Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Image;

   function Has_Token (Line : String) return Boolean is
     (Ada.Strings.Fixed.Index (Line, "D-Bus") /= 0
      or else Ada.Strings.Fixed.Index (Line, "DBus") /= 0
      or else Ada.Strings.Fixed.Index (Line, "AT-SPI") /= 0
      or else Ada.Strings.Fixed.Index (Line, "ATSPI") /= 0
      or else Ada.Strings.Fixed.Index (Line, "HRESULT") /= 0
      or else Ada.Strings.Fixed.Index (Line, "BSTR") /= 0
      or else Ada.Strings.Fixed.Index (Line, "VARIANT") /= 0
      or else Ada.Strings.Fixed.Index (Line, "SAFEARRAY") /= 0
      or else Ada.Strings.Fixed.Index (Line, "COM") /= 0
      or else Ada.Strings.Fixed.Index (Line, "HWND") /= 0
      or else Ada.Strings.Fixed.Index (Line, "Objective-C") /= 0
      or else Ada.Strings.Fixed.Index (Line, "NSString") /= 0
      or else Ada.Strings.Fixed.Index (Line, "NSArray") /= 0
      or else Ada.Strings.Fixed.Index (Line, "NSView") /= 0
      or else Ada.Strings.Fixed.Index (Line, "NSWindow") /= 0
      or else Ada.Strings.Fixed.Index (Line, "NSAccessibilityElement") /= 0
      or else Ada.Strings.Fixed.Index (Line, "AppKit") /= 0);

   function Is_Comment (Line : String) return Boolean is
      Trimmed : constant String :=
        Ada.Strings.Fixed.Trim (Line, Ada.Strings.Left);
   begin
      return Trimmed'Length >= 2
        and then Trimmed (Trimmed'First .. Trimmed'First + 1) = "--";
   end Is_Comment;

   function File_Leak_Count (Path : String) return Natural is
      File : Ada.Text_IO.File_Type;
      Buffer : String (1 .. 1_000);
      Last : Natural;
      Count : Natural := 0;
      Resolved_Path : constant String :=
        (if Ada.Directories.Exists (Path) then Path
         else "../" & Path);
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Resolved_Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Ada.Text_IO.Get_Line (File, Buffer, Last);
         declare
            Line : constant String := Buffer (1 .. Last);
         begin
            if not Is_Comment (Line) and then Has_Token (Line) then
               Count := Count + 1;
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);
      return Count;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end File_Leak_Count;

   function Leak_Count return Natural is
      Count : Natural := 0;
   begin
      for Path of Spec_Paths loop
         Count := Count + File_Leak_Count (To_String (Path));
      end loop;
      return Count;
   end Leak_Count;

   function Complete return Boolean is (Leak_Count = 0);

   function Markdown return String is
     ("# a11y Public Surface Audit"
      & ASCII.LF
      & ASCII.LF
      & "| Checked specs | Forbidden tokens | Leak count | Complete |"
      & ASCII.LF
      & "| --- | --- | --- | --- |"
      & ASCII.LF
      & "| "
      & Image (Spec_Count)
      & " | "
      & Image (Forbidden_Token_Count)
      & " | "
      & Image (Leak_Count)
      & " | "
      & (if Complete then "true" else "false")
      & " |"
      & ASCII.LF);

   function JSON return String is
     ("{"
      & ASCII.LF
      & "  ""schema"": "
      & Q (Schema)
      & ","
      & ASCII.LF
      & "  ""spec_count"": "
      & Image (Spec_Count)
      & ","
      & ASCII.LF
      & "  ""forbidden_token_count"": "
      & Image (Forbidden_Token_Count)
      & ","
      & ASCII.LF
      & "  ""leak_count"": "
      & Image (Leak_Count)
      & ","
      & ASCII.LF
      & "  ""complete"": "
      & (if Complete then "true" else "false")
      & ASCII.LF
      & "}"
      & ASCII.LF);

end A11y_Public_Surface_Audit;
