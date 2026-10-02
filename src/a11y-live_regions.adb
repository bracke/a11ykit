package body A11y.Live_Regions is
   use Ada.Strings.Unbounded;

   Off_Name       : aliased constant String := "off";
   Polite_Name    : aliased constant String := "polite";
   Assertive_Name : aliased constant String := "assertive";

   Additions_Name : aliased constant String := "additions";
   Removals_Name  : aliased constant String := "removals";
   Text_Name      : aliased constant String := "text";

   function Metadata
     (Setting : Live_Setting)
      return Live_Setting_Metadata is
     (case Setting is
        when Off =>
          (Stable_Name => Off_Name'Access,
           Externally_Announced => False,
           Interruptive => False),
        when Polite =>
          (Stable_Name => Polite_Name'Access,
           Externally_Announced => True,
           Interruptive => False),
        when Assertive =>
          (Stable_Name => Assertive_Name'Access,
           Externally_Announced => True,
           Interruptive => True));

   function Stable_Name (Setting : Live_Setting) return String is
     (Metadata (Setting).Stable_Name.all);

   function Metadata
     (Change : Relevant_Change)
      return Relevant_Change_Metadata is
     (case Change is
        when Additions => (Stable_Name => Additions_Name'Access),
        when Removals => (Stable_Name => Removals_Name'Access),
        when Text => (Stable_Name => Text_Name'Access));

   function Stable_Name (Change : Relevant_Change) return String is
     (Metadata (Change).Stable_Name.all);

   function Is_Externally_Announced
     (Setting : Live_Setting)
      return Boolean is
     (Setting in Polite | Assertive)
   with SPARK_Mode => On;

   function Is_Interruptive
     (Setting : Live_Setting)
      return Boolean is
     (Setting = Assertive)
   with SPARK_Mode => On;

   function Has_Relevant_Changes
     (Set : Relevant_Change_Set)
      return Boolean is
     (Set (Additions) or else Set (Removals) or else Set (Text))
   with SPARK_Mode => On;

   function Relevant_Count
     (Set : Relevant_Change_Set)
      return Natural is
     (0
      + (if Set (Additions) then 1 else 0)
      + (if Set (Removals) then 1 else 0)
      + (if Set (Text) then 1 else 0))
   with SPARK_Mode => On;

   function Relevant_Names
     (Set : Relevant_Change_Set)
      return String
   is
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      for Change in Relevant_Change loop
         if Set (Change) then
            if Length (Result) > 0 then
               Append (Result, " ");
            end if;
            Append (Result, Stable_Name (Change));
         end if;
      end loop;

      return To_String (Result);
   end Relevant_Names;

   function With_Change
     (Set    : Relevant_Change_Set;
      Change : Relevant_Change)
      return Relevant_Change_Set
   with SPARK_Mode => On
   is
      Result : Relevant_Change_Set := Set;
   begin
      Result (Change) := True;
      return Result;
   end With_Change;

   function Validate
     (Item : Live_Region_Metadata)
      return A11y.Results.Result
   with SPARK_Mode => On
   is
      Has_Relevance : constant Boolean := Has_Relevant_Changes (Item.Relevant);
   begin
      if Item.Setting = Off then
         if Has_Relevance then
            return (Status => A11y.Results.Invalid_State);
         else
            return A11y.Results.Ok;
         end if;
      elsif not Has_Relevance then
         return (Status => A11y.Results.Invalid_State);
      end if;

      return A11y.Results.Ok;
   end Validate;

   function Metadata_Is_Coherent
     (Item : Live_Region_Metadata)
      return Boolean is
     ((Item.Setting = Off and then not Has_Relevant_Changes (Item.Relevant))
      or else
        (Item.Setting /= Off
         and then Has_Relevant_Changes (Item.Relevant)))
   with SPARK_Mode => On;

   function Current_Metadata_Safely
     (Self   : Live_Region_Provider'Class;
      Result : out A11y.Results.Result)
      return Live_Region_Metadata
   is
      Metadata : Live_Region_Metadata;
   begin
      Metadata := Current_Metadata (Self);
      Result := Validate (Metadata);
      if A11y.Results.Failed (Result) then
         return (Setting => Off,
                 Atomic => False,
                 Relevant => Empty_Relevant_Change_Set);
      end if;

      return Metadata;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return (Setting => Off,
                 Atomic => False,
                 Relevant => Empty_Relevant_Change_Set);
   end Current_Metadata_Safely;

   procedure Create_Announcement
     (Text       : String;
      Is_Protected : Boolean;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config;
      Item       : out Announcement;
      Result     : out A11y.Results.Result)
   is
   begin
      Item := (Text => Null_Unbounded_String);
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      if Is_Protected then
         Result := (Status => A11y.Results.Permission_Denied);
         return;
      end if;

      if Text'Length = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      if A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Text_Returned, Text'Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      Item.Text := To_Unbounded_String (Text);
      Result := A11y.Results.Ok;
   end Create_Announcement;

end A11y.Live_Regions;
