with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;

with A11y.Conformance;

package body A11y_Tool_Reports is
   use Ada.Strings.Unbounded;
   use type A11y.Conformance.Support_Level;

   type Capability_Summary is record
      Declaration_Count : Natural := 0;
      Production_Claim_Count : Natural := 0;
      Internal_Only_Count : Natural := 0;
      Unsupported_Count : Natural := 0;
      Native_Production_Claim_Count : Natural := 0;
      Linux_ATSPI_Production_Claim_Count : Natural := 0;
      Windows_UIA_Production_Claim_Count : Natural := 0;
      MacOS_NSAccessibility_Production_Claim_Count : Natural := 0;
      Null_Internal_Only_Count : Natural := 0;
      Disabled_Unsupported_Count : Natural := 0;
   end record;

   function Count_Image (Value : Natural) return String is
     (Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both));

   function Summarize
     (Declarations : A11y.Conformance.Declaration_Vectors.Vector)
      return Capability_Summary
   is
      Summary : Capability_Summary;
   begin
      Summary.Declaration_Count := Natural (Declarations.Length);

      for Item of Declarations loop
         declare
            Backend : constant String := To_String (Item.Backend);
         begin
            if A11y.Conformance.Is_Production_Support (Item.Support) then
               Summary.Production_Claim_Count :=
                 Summary.Production_Claim_Count + 1;

               if A11y.Conformance.Is_Native_Backend (Backend) then
                  Summary.Native_Production_Claim_Count :=
                    Summary.Native_Production_Claim_Count + 1;
               end if;

               if Backend = "AT-SPI" then
                  Summary.Linux_ATSPI_Production_Claim_Count :=
                    Summary.Linux_ATSPI_Production_Claim_Count + 1;
               elsif Backend = "UIA" then
                  Summary.Windows_UIA_Production_Claim_Count :=
                    Summary.Windows_UIA_Production_Claim_Count + 1;
               elsif Backend = "NSAccessibility" then
                  Summary.MacOS_NSAccessibility_Production_Claim_Count :=
                    Summary.MacOS_NSAccessibility_Production_Claim_Count + 1;
               end if;
            elsif Item.Support = A11y.Conformance.Internal_Only then
               Summary.Internal_Only_Count := Summary.Internal_Only_Count + 1;

               if Backend = "Null" then
                  Summary.Null_Internal_Only_Count :=
                    Summary.Null_Internal_Only_Count + 1;
               end if;
            elsif Item.Support = A11y.Conformance.Unsupported then
               Summary.Unsupported_Count := Summary.Unsupported_Count + 1;

               if Backend = "Disabled" then
                  Summary.Disabled_Unsupported_Count :=
                    Summary.Disabled_Unsupported_Count + 1;
               end if;
            end if;
         end;
      end loop;

      return Summary;
   end Summarize;

   function Json_Escape (Value : String) return String is
      Result : Unbounded_String;
   begin
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
      return To_String (Result);
   end Json_Escape;

   function Json_String (Value : String) return String is
     ("""" & Json_Escape (Value) & """");

   function Capability_Matrix_Markdown return String is
      Result : Unbounded_String;
      Declarations : constant A11y.Conformance.Declaration_Vectors.Vector :=
        A11y.Conformance.All_Declarations;
      Summary : constant Capability_Summary := Summarize (Declarations);
   begin
      Append (Result, "# a11y Capability Matrix" & ASCII.LF & ASCII.LF);
      Append
        (Result,
         "Declarations: "
         & Count_Image (Summary.Declaration_Count)
         & "; production claims: "
         & Count_Image (Summary.Production_Claim_Count)
         & "; native production claims: "
         & Count_Image (Summary.Native_Production_Claim_Count)
         & "; internal-only rows: "
         & Count_Image (Summary.Internal_Only_Count)
         & "; unsupported rows: "
         & Count_Image (Summary.Unsupported_Count)
         & "."
         & ASCII.LF
         & ASCII.LF);
      Append
        (Result,
         "| Feature | Backend | Support | Native Mapping | Test |" & ASCII.LF);
      Append (Result, "| --- | --- | --- | --- | --- |" & ASCII.LF);

      for Item of Declarations loop
         Append
           (Result,
            "| "
            & A11y.Conformance.Dotted_Name (Item.Feature)
            & " | "
            & To_String (Item.Backend)
            & " | "
            & A11y.Conformance.Support_Level'Image (Item.Support)
            & " | "
            & To_String (Item.Native_Mapping)
            & " | "
            & To_String (Item.Test_Id)
            & " |"
            & ASCII.LF);
      end loop;

      return To_String (Result);
   end Capability_Matrix_Markdown;

   function Capability_Matrix_JSON return String is
      Result : Unbounded_String;
      First : Boolean := True;
      Declarations : constant A11y.Conformance.Declaration_Vectors.Vector :=
        A11y.Conformance.All_Declarations;
      Summary : constant Capability_Summary := Summarize (Declarations);
   begin
      Append (Result, "{" & ASCII.LF);
      Append (Result, "  ""schema"": ");
      Append (Result, Json_String (Capability_Matrix_Schema));
      Append (Result, "," & ASCII.LF);
      Append (Result, "  ""summary"": {" & ASCII.LF);
      Append
        (Result,
         "    ""declaration_count"": "
         & Count_Image (Summary.Declaration_Count)
         & "," & ASCII.LF);
      Append
        (Result,
         "    ""production_claim_count"": "
         & Count_Image (Summary.Production_Claim_Count)
         & "," & ASCII.LF);
      Append
        (Result,
         "    ""internal_only_count"": "
         & Count_Image (Summary.Internal_Only_Count)
         & "," & ASCII.LF);
      Append
        (Result,
         "    ""unsupported_count"": "
         & Count_Image (Summary.Unsupported_Count)
         & "," & ASCII.LF);
      Append
        (Result,
         "    ""native_production_claim_count"": "
         & Count_Image (Summary.Native_Production_Claim_Count)
         & "," & ASCII.LF);
      Append
        (Result,
         "    ""linux_atspi_production_claim_count"": "
         & Count_Image (Summary.Linux_ATSPI_Production_Claim_Count)
         & "," & ASCII.LF);
      Append
        (Result,
         "    ""windows_uia_production_claim_count"": "
         & Count_Image (Summary.Windows_UIA_Production_Claim_Count)
         & "," & ASCII.LF);
      Append
        (Result,
         "    ""macos_nsaccessibility_production_claim_count"": "
         & Count_Image (Summary.MacOS_NSAccessibility_Production_Claim_Count)
         & "," & ASCII.LF);
      Append
        (Result,
         "    ""null_internal_only_count"": "
         & Count_Image (Summary.Null_Internal_Only_Count)
         & "," & ASCII.LF);
      Append
        (Result,
         "    ""disabled_unsupported_count"": "
         & Count_Image (Summary.Disabled_Unsupported_Count)
         & ASCII.LF);
      Append (Result, "  }," & ASCII.LF);
      Append (Result, "  ""declarations"": [" & ASCII.LF);

      for Item of Declarations loop
         if First then
            First := False;
         else
            Append (Result, "," & ASCII.LF);
         end if;

         Append
           (Result,
            "    {"
            & """feature"": "
            & Json_String (A11y.Conformance.Dotted_Name (Item.Feature))
            & ", ""backend"": "
            & Json_String (To_String (Item.Backend))
            & ", ""support"": "
            & Json_String (A11y.Conformance.Support_Level'Image (Item.Support))
            & ", ""native_mapping"": "
            & Json_String (To_String (Item.Native_Mapping))
            & ", ""test_id"": "
            & Json_String (To_String (Item.Test_Id))
            & "}");
      end loop;

      Append (Result, ASCII.LF & "  ]" & ASCII.LF & "}" & ASCII.LF);
      return To_String (Result);
   end Capability_Matrix_JSON;

end A11y_Tool_Reports;
