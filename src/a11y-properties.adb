package body A11y.Properties is
   pragma SPARK_Mode (On);

   use Ada.Strings.Unbounded;

   Present_Name : aliased constant String := "present";
   Empty_Name : aliased constant String := "empty";
   Unsupported_Name : aliased constant String := "unsupported";
   Temporarily_Unavailable_Name : aliased constant String :=
     "temporarily-unavailable";
   Node_Unavailable_Name : aliased constant String := "node-unavailable";
   Resource_Limited_Name : aliased constant String := "resource-limited";
   Permission_Denied_Name : aliased constant String := "permission-denied";
   Error_Name : aliased constant String := "error";

   String_Value_Name : aliased constant String := "string";
   Integer_Value_Name : aliased constant String := "integer";
   Boolean_Value_Name : aliased constant String := "boolean";
   Rectangle_Value_Name : aliased constant String := "rectangle";
   Role_Value_Name : aliased constant String := "role";
   State_Set_Value_Name : aliased constant String := "state-set";

   Accessible_Name_Name : aliased constant String := "accessible-name";
   Visible_Title_Name : aliased constant String := "visible-title";
   Description_Name : aliased constant String := "description";
   Help_Text_Name : aliased constant String := "help-text";
   Placeholder_Name : aliased constant String := "placeholder";
   Value_Text_Name : aliased constant String := "value-text";
   Keyboard_Shortcut_Name : aliased constant String := "keyboard-shortcut";
   Semantic_Identifier_Name : aliased constant String := "semantic-identifier";
   Locale_Name : aliased constant String := "locale";
   Bounds_Name : aliased constant String := "bounds";
   Orientation_Name : aliased constant String := "orientation";
   Set_Position_Name : aliased constant String := "set-position";
   Set_Size_Name : aliased constant String := "set-size";
   Hierarchical_Level_Name : aliased constant String := "hierarchical-level";
   Heading_Level_Name : aliased constant String := "heading-level";
   Landmark_Name : aliased constant String := "landmark";
   Role_Property_Name : aliased constant String := "role";
   State_Property_Name : aliased constant String := "state-set";

   function Metadata
     (Status : Property_Status)
      return Property_Status_Metadata is
     (case Status is
        when Present =>
          (Stable_Name      => Present_Name'Access,
           Available        => True,
           Expected_Failure => False),
        when Empty =>
          (Stable_Name      => Empty_Name'Access,
           Available        => True,
           Expected_Failure => False),
        when Unsupported =>
          (Stable_Name      => Unsupported_Name'Access,
           Available        => False,
           Expected_Failure => True),
        when Temporarily_Unavailable =>
          (Stable_Name      => Temporarily_Unavailable_Name'Access,
           Available        => False,
           Expected_Failure => True),
        when Node_Unavailable =>
          (Stable_Name      => Node_Unavailable_Name'Access,
           Available        => False,
           Expected_Failure => True),
        when Resource_Limited =>
          (Stable_Name      => Resource_Limited_Name'Access,
           Available        => False,
           Expected_Failure => True),
        when Permission_Denied =>
          (Stable_Name      => Permission_Denied_Name'Access,
           Available        => False,
           Expected_Failure => True),
        when Error =>
          (Stable_Name      => Error_Name'Access,
           Available        => False,
           Expected_Failure => False));

   function Stable_Name (Status : Property_Status) return String is
     (Metadata (Status).Stable_Name.all);

   function Status_From_Result
     (Status : A11y.Results.Status_Code)
      return Property_Status is
     (case Status is
        when A11y.Results.Success =>
          Present,
        when A11y.Results.Node_Unavailable =>
          Node_Unavailable,
        when A11y.Results.Timed_Out |
             A11y.Results.Cancelled |
             A11y.Results.Busy |
             A11y.Results.Shutting_Down =>
          Temporarily_Unavailable,
        when A11y.Results.Unsupported_Property |
             A11y.Results.Unsupported_Capability =>
          Unsupported,
        when A11y.Results.Resource_Limit |
             A11y.Results.Out_Of_Resources =>
          Resource_Limited,
        when A11y.Results.Permission_Denied =>
          Permission_Denied,
        when others =>
          Error);

   function Metadata
     (Kind : Property_Value_Kind)
      return Property_Value_Kind_Metadata is
     (case Kind is
        when String_Value =>
          (Stable_Name => String_Value_Name'Access),
        when Integer_Value =>
          (Stable_Name => Integer_Value_Name'Access),
        when Boolean_Value =>
          (Stable_Name => Boolean_Value_Name'Access),
        when Rectangle_Value =>
          (Stable_Name => Rectangle_Value_Name'Access),
        when Role_Value =>
          (Stable_Name => Role_Value_Name'Access),
        when State_Set_Value =>
          (Stable_Name => State_Set_Value_Name'Access));

   function Stable_Name (Kind : Property_Value_Kind) return String is
     (Metadata (Kind).Stable_Name.all);

   function Metadata (Id : Property_Id) return Property_Metadata is
     (case Id is
        when Accessible_Name =>
          (Stable_Name => Accessible_Name_Name'Access,
           Value_Kind => String_Value),
        when Visible_Title =>
          (Stable_Name => Visible_Title_Name'Access,
           Value_Kind => String_Value),
        when Description =>
          (Stable_Name => Description_Name'Access,
           Value_Kind => String_Value),
        when Help_Text =>
          (Stable_Name => Help_Text_Name'Access,
           Value_Kind => String_Value),
        when Placeholder =>
          (Stable_Name => Placeholder_Name'Access,
           Value_Kind => String_Value),
        when Value_Text =>
          (Stable_Name => Value_Text_Name'Access,
           Value_Kind => String_Value),
        when Keyboard_Shortcut =>
          (Stable_Name => Keyboard_Shortcut_Name'Access,
           Value_Kind => String_Value),
        when Semantic_Identifier =>
          (Stable_Name => Semantic_Identifier_Name'Access,
           Value_Kind => String_Value),
        when Locale =>
          (Stable_Name => Locale_Name'Access,
           Value_Kind => String_Value),
        when Bounds =>
          (Stable_Name => Bounds_Name'Access,
           Value_Kind => Rectangle_Value),
        when Orientation =>
          (Stable_Name => Orientation_Name'Access,
           Value_Kind => String_Value),
        when Set_Position =>
          (Stable_Name => Set_Position_Name'Access,
           Value_Kind => Integer_Value),
        when Set_Size =>
          (Stable_Name => Set_Size_Name'Access,
           Value_Kind => Integer_Value),
        when Hierarchical_Level =>
          (Stable_Name => Hierarchical_Level_Name'Access,
           Value_Kind => Integer_Value),
        when Heading_Level =>
          (Stable_Name => Heading_Level_Name'Access,
           Value_Kind => Integer_Value),
        when Landmark =>
          (Stable_Name => Landmark_Name'Access,
           Value_Kind => String_Value),
        when Role_Property =>
          (Stable_Name => Role_Property_Name'Access,
           Value_Kind => Role_Value),
        when State_Property =>
          (Stable_Name => State_Property_Name'Access,
           Value_Kind => State_Set_Value));

   function Stable_Name (Id : Property_Id) return String is
     (Metadata (Id).Stable_Name.all);

   function Textual_Property_Safely
     (Self   : Textual_Property_Provider'Class;
      Id     : Property_Id;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return String_Property
   with SPARK_Mode => Off
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Result : String_Property;
   begin
      if A11y.Results.Failed (Validation) then
         return
           (Status => Status_From_Result (Validation.Status),
            Value  => Null_Unbounded_String);
      end if;

      case Id is
         when Visible_Title =>
            Result := Visible_Title (Self);
         when Help_Text =>
            Result := Help_Text (Self);
         when Placeholder =>
            Result := Placeholder (Self);
         when Value_Text =>
            Result := Value_Text (Self);
         when Keyboard_Shortcut =>
            Result := Keyboard_Shortcut (Self);
         when Semantic_Identifier =>
            Result := Semantic_Identifier (Self);
         when Locale =>
            Result := Locale (Self);
         when Orientation =>
            Result := Orientation (Self);
         when Landmark =>
            Result := Landmark (Self);
         when others =>
            return (Status => Unsupported, Value => Null_Unbounded_String);
      end case;

      if Result.Status in Present | Empty
        and then
          A11y.Resource_Limits.Exceeded
            (Limits,
             A11y.Resource_Limits.Native_String_Size,
             Length (Result.Value))
      then
         return
           (Status => Resource_Limited,
            Value  => Null_Unbounded_String);
      elsif Result.Status = Present and then Length (Result.Value) = 0 then
         return
           (Status => Empty,
            Value  => Null_Unbounded_String);
      elsif Result.Status /= Present then
         return
           (Status => Result.Status,
            Value  => Null_Unbounded_String);
      end if;

      return Result;
   exception
      when others =>
         return (Status => Error, Value => Null_Unbounded_String);
   end Textual_Property_Safely;

   function Textual_Property_Safely
     (Self : Textual_Property_Provider'Class;
      Id   : Property_Id)
      return String_Property is
     (Textual_Property_Safely
        (Self, Id, A11y.Resource_Limits.Default_Config))
   with SPARK_Mode => Off;

   function Limit_For_Structural_Property
     (Id : Property_Id)
      return A11y.Resource_Limits.Limit_Kind is
     (case Id is
        when Set_Position | Set_Size =>
          A11y.Resource_Limits.Native_Array_Size,
        when Hierarchical_Level | Heading_Level =>
          A11y.Resource_Limits.Traversal_Depth,
        when others =>
          A11y.Resource_Limits.Native_Array_Size);

   function Structural_Property_Safely
     (Self : Structural_Property_Provider'Class;
      Id     : Property_Id;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Integer_Property
   with SPARK_Mode => Off
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Result : Integer_Property;
   begin
      if A11y.Results.Failed (Validation) then
         return (Status => Status_From_Result (Validation.Status), Value => 0);
      end if;

      case Id is
         when Set_Position =>
            Result := Set_Position (Self);
         when Set_Size =>
            Result := Set_Size (Self);
         when Hierarchical_Level =>
            Result := Hierarchical_Level (Self);
         when Heading_Level =>
            Result := Heading_Level (Self);
         when others =>
            return (Status => Unsupported, Value => 0);
      end case;

      if Result.Status /= Present then
         return (Status => Result.Status, Value => 0);
      elsif Result.Value < 0 then
         return (Status => Error, Value => 0);
      elsif A11y.Resource_Limits.Exceeded
        (Limits,
         Limit_For_Structural_Property (Id),
         Natural (Result.Value))
      then
         return (Status => Resource_Limited, Value => 0);
      end if;

      return Result;
   exception
      when others =>
         return (Status => Error, Value => 0);
   end Structural_Property_Safely;

   function Structural_Property_Safely
     (Self : Structural_Property_Provider'Class;
      Id   : Property_Id)
      return Integer_Property is
     (Structural_Property_Safely
        (Self, Id, A11y.Resource_Limits.Default_Config))
   with SPARK_Mode => Off;

   function Present (Value : String) return String_Property is
     (Status => Properties.Present, Value => To_Unbounded_String (Value))
   with SPARK_Mode => Off;

   function Present (Value : Integer) return Integer_Property is
     (Status => Properties.Present, Value => Value);

   function Present (Value : Boolean) return Boolean_Property is
     (Status => Properties.Present, Value => Value);

   function Present
     (Value : A11y.Geometry.Rectangle)
      return Rectangle_Property is
     (Status => Properties.Present, Value => Value);

   function Present (Value : A11y.Roles.Role) return Role_Value_Property is
     (Status => Properties.Present, Value => Value);

   function Present
     (Value : A11y.States.State_Set)
      return State_Set_Value_Property is
     (Status => Properties.Present, Value => Value);

   function Empty return String_Property is
     (Status => Properties.Empty, Value => Null_Unbounded_String)
   with SPARK_Mode => Off;

end A11y.Properties;
