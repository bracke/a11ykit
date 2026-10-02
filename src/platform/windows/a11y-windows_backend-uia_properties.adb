with A11y.Trees.Exposure_Views;

package body A11y.Windows_Backend.UIA_Properties is
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;
   use type A11y.Properties.Property_Status;
   use type A11y.Roles.Role;

   function String_Result
     (Value  : A11y.Properties.String_Property;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Property_Reply
   is
      Limit_Result : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
   begin
      if A11y.Results.Failed (Limit_Result) then
         return
           (Kind   => Error_Reply,
            Status => Limit_Result.Status);
      end if;

      case Value.Status is
         when A11y.Properties.Present =>
            if A11y.Resource_Limits.Exceeded
              (Limits,
               A11y.Resource_Limits.Native_String_Size,
               Ada.Strings.Unbounded.Length (Value.Value))
            then
               return
                 (Kind   => Error_Reply,
                  Status => A11y.Results.Resource_Limit);
            end if;
            return
              (Kind   => String_Reply,
               Status => A11y.Results.Success,
               Text   => Value.Value);
         when A11y.Properties.Empty =>
            return
              (Kind   => Empty_String_Reply,
               Status => A11y.Results.Success);
         when A11y.Properties.Unsupported =>
            return
              (Kind   => Not_Supported_Reply,
               Status => A11y.Results.Unsupported_Property);
         when A11y.Properties.Node_Unavailable =>
            return
              (Kind   => Error_Reply,
               Status => A11y.Results.Node_Unavailable);
         when A11y.Properties.Temporarily_Unavailable =>
            return
              (Kind   => Error_Reply,
               Status => A11y.Results.Busy);
         when A11y.Properties.Resource_Limited =>
            return
              (Kind   => Error_Reply,
               Status => A11y.Results.Resource_Limit);
         when A11y.Properties.Permission_Denied =>
            return
              (Kind   => Error_Reply,
               Status => A11y.Results.Permission_Denied);
         when A11y.Properties.Error =>
            return
              (Kind   => Error_Reply,
               Status => A11y.Results.Internal_Error);
      end case;
   end String_Result;

   function Integer_Result
     (Value      : A11y.Properties.Integer_Property;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config;
      Limit_Kind : A11y.Resource_Limits.Limit_Kind)
      return Property_Reply
   is
      Limit_Result : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
   begin
      if A11y.Results.Failed (Limit_Result) then
         return
           (Kind   => Error_Reply,
            Status => Limit_Result.Status);
      end if;

      case Value.Status is
         when A11y.Properties.Present =>
            if Value.Value < 0 then
               return
                 (Kind   => Error_Reply,
                  Status => A11y.Results.Invalid_Range);
            elsif A11y.Resource_Limits.Exceeded
              (Limits, Limit_Kind, Natural (Value.Value))
            then
               return
                 (Kind   => Error_Reply,
                  Status => A11y.Results.Resource_Limit);
            end if;

            return
              (Kind         => Integer_Reply,
               Status       => A11y.Results.Success,
               Integer_Item => Value.Value);
         when A11y.Properties.Unsupported =>
            return
              (Kind   => Not_Supported_Reply,
               Status => A11y.Results.Unsupported_Property);
         when A11y.Properties.Node_Unavailable =>
            return
              (Kind   => Error_Reply,
               Status => A11y.Results.Node_Unavailable);
         when A11y.Properties.Temporarily_Unavailable =>
            return
              (Kind   => Error_Reply,
               Status => A11y.Results.Busy);
         when A11y.Properties.Resource_Limited =>
            return
              (Kind   => Error_Reply,
               Status => A11y.Results.Resource_Limit);
         when A11y.Properties.Permission_Denied =>
            return
              (Kind   => Error_Reply,
               Status => A11y.Results.Permission_Denied);
         when A11y.Properties.Empty =>
            return
              (Kind   => Not_Supported_Reply,
               Status => A11y.Results.Unsupported_Property);
         when A11y.Properties.Error =>
            return
              (Kind   => Error_Reply,
               Status => A11y.Results.Internal_Error);
      end case;
   end Integer_Result;

   function Exposure_Of
     (Snapshot : Property_Snapshot;
      Node     : A11y.Node_Ids.Node_Id)
      return A11y.Nodes.Exposure_Policy
   is
      Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
   begin
      if Slot not in Snapshot.Exposure'Range then
         return A11y.Nodes.Hide_Node_And_Subtree;
      end if;

      return Snapshot.Exposure (Slot);
   end Exposure_Of;

   function Is_Externally_Exposed
     (Snapshot : Property_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Boolean
   is
      function Policy_For
        (Current : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy is
        (Exposure_Of (Snapshot, Current));

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Policy_For);

      Parent : A11y.Node_Ids.Node_Id;
      Result : A11y.Results.Result;
   begin
      if not Snapshot.Use_Tree_Projection then
         return True;
      elsif not A11y.Node_Ids.Is_Valid (Snapshot.Root)
        or else not A11y.Node_Ids.Is_Valid (Snapshot.Id)
      then
         return False;
      elsif Snapshot.Id = Snapshot.Root then
         return Exposure_Of (Snapshot, Snapshot.Id) = A11y.Nodes.Expose_Node;
      end if;

      Parent := Exposure_View.Exposed_Parent_Of
        (Snapshot.Tree, Snapshot.Id, Limits, Result);
      return A11y.Results.Succeeded (Result)
        and then A11y.Node_Ids.Is_Valid (Parent);
   exception
      when others =>
         return False;
   end Is_Externally_Exposed;

   function Metadata_Available
     (Snapshot : Property_Snapshot)
      return Boolean is
     (not Snapshot.Use_Node_Metadata
      or else A11y.Semantic_Snapshots.Has_Node
        (Snapshot.Nodes, Snapshot.Id));

   function Metadata_View
     (Snapshot : Property_Snapshot)
      return A11y.Semantic_Snapshots.Node_Metadata is
     (if Snapshot.Use_Node_Metadata
      then A11y.Semantic_Snapshots.Metadata (Snapshot.Nodes, Snapshot.Id)
      else (Present      => True,
            Role         => Snapshot.Role,
            Name         => Snapshot.Name,
            Description  => Snapshot.Description,
            Help_Text    => Snapshot.Help_Text,
            Placeholder  => Snapshot.Placeholder,
            Value_Text   => Snapshot.Value_Text,
            Protected_Value_Text => Snapshot.Protected_Value_Text,
            Bounds       => A11y.Properties.Present (Snapshot.Bounds),
            Semantic_Identifier => Snapshot.Automation_Id,
            Visible_Title => Snapshot.Visible_Title,
            Keyboard_Shortcut => Snapshot.Keyboard_Shortcut,
            Locale       => Snapshot.Locale,
            Orientation  => Snapshot.Orientation,
            Landmark     => Snapshot.Landmark,
            States       => Snapshot.States,
            Capabilities => Snapshot.Capabilities,
            Exposure     => A11y.Nodes.Expose_Node));

   function Neutral_Property (Property : Core_Property)
      return A11y.Properties.Property_Id is
     (case Property is
        when Name => A11y.Properties.Accessible_Name,
        when Visible_Title => A11y.Properties.Visible_Title,
        when Automation_Id => A11y.Properties.Semantic_Identifier,
        when Description => A11y.Properties.Description,
        when Value_Text => A11y.Properties.Value_Text,
        when Help_Text => A11y.Properties.Help_Text,
        when Placeholder => A11y.Properties.Placeholder,
        when Keyboard_Shortcut => A11y.Properties.Keyboard_Shortcut,
        when Locale => A11y.Properties.Locale,
        when Orientation => A11y.Properties.Orientation,
        when Position_In_Set => A11y.Properties.Set_Position,
        when Size_Of_Set => A11y.Properties.Set_Size,
        when Hierarchical_Level => A11y.Properties.Hierarchical_Level,
        when Heading_Level => A11y.Properties.Heading_Level,
        when Landmark => A11y.Properties.Landmark,
        when Control_Type => A11y.Properties.Role_Property,
        when Bounding_Rectangle => A11y.Properties.Bounds,
        when Is_Enabled |
             Has_Keyboard_Focus |
             Is_Keyboard_Focusable |
             Is_Offscreen |
             Is_Password |
             Is_Required_For_Form => A11y.Properties.State_Property);

   function Query_Property
     (Snapshot : Property_Snapshot;
      Property : Core_Property)
      return Property_Reply is
     (Query_Property (Snapshot, Property, Snapshot.Limits));

   function Query_Property
     (Snapshot : Property_Snapshot;
      Property : Core_Property;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Property_Reply
   is
      Validation : A11y.Results.Result;
   begin
      Validation := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Validation) then
         return
           (Kind   => Error_Reply,
            Status => Validation.Status);
      end if;

      if not A11y.Node_Ids.Is_Valid (Snapshot.Id) or else Snapshot.Defunct
        or else not Metadata_Available (Snapshot)
        or else not Is_Externally_Exposed (Snapshot, Limits)
      then
         return
           (Kind   => Error_Reply,
            Status => A11y.Results.Node_Unavailable);
      end if;

      declare
         Node_View : constant A11y.Semantic_Snapshots.Node_Metadata :=
           Metadata_View (Snapshot);
         Effective_Role : constant A11y.Roles.Role :=
           Node_View.Role;
         Effective_States : constant A11y.States.State_Set :=
           A11y.States.Derive
             (Node_View.States, Effective_Role, Node_View.Capabilities);
         Mapped_States : constant
           A11y.Windows_Backend.UIA_Mappings.UIA_Property_Set :=
             A11y.Windows_Backend.UIA_Mappings.Map_States
               (Effective_States);
         Effective_Bounds : constant A11y.Geometry.Rectangle :=
           (if Node_View.Bounds.Status = A11y.Properties.Present
            then Node_View.Bounds.Value
            else Snapshot.Bounds);
         function State_Boolean_Result
           (Property : A11y.Windows_Backend.UIA_Mappings.UIA_Property)
            return Property_Reply
         is
         begin
            Validation := A11y.States.Validate (Effective_States);
            if A11y.Results.Failed (Validation) then
               return
                 (Kind   => Error_Reply,
                  Status => Validation.Status);
            end if;

            return
              (Kind         => Boolean_Reply,
               Status       => A11y.Results.Success,
               Boolean_Item => Mapped_States (Property));
         end State_Boolean_Result;
      begin
      if Snapshot.Use_Node_Metadata
        and then Node_View.Exposure /= A11y.Nodes.Expose_Node
      then
         return
           (Kind   => Error_Reply,
            Status => A11y.Results.Node_Unavailable);
      end if;

      case Property is
         when Name =>
            return String_Result (Node_View.Name, Limits);
         when Visible_Title =>
            return String_Result
              ((if Node_View.Visible_Title.Status = A11y.Properties.Present
                then Node_View.Visible_Title
                else Snapshot.Visible_Title),
               Limits);
         when Automation_Id =>
            return String_Result
              ((if Node_View.Semantic_Identifier.Status =
                   A11y.Properties.Present
                then Node_View.Semantic_Identifier
                else Snapshot.Automation_Id),
               Limits);
         when Description =>
            return String_Result (Node_View.Description, Limits);
         when Value_Text =>
            if A11y.Nodes.Protected_Value_Query_Status
              (Effective_Role,
               A11y.Properties.Present,
               Node_View.Protected_Value_Text) =
                 A11y.Properties.Permission_Denied
            then
               return
                 (Kind   => Error_Reply,
                  Status => A11y.Results.Permission_Denied);
            end if;
            return String_Result (Node_View.Value_Text, Limits);
         when Help_Text =>
            return String_Result (Node_View.Help_Text, Limits);
         when Placeholder =>
            return String_Result (Node_View.Placeholder, Limits);
         when Keyboard_Shortcut =>
            return String_Result
              ((if Node_View.Keyboard_Shortcut.Status =
                   A11y.Properties.Present
                then Node_View.Keyboard_Shortcut
                else Snapshot.Keyboard_Shortcut),
               Limits);
         when Locale =>
            return String_Result
              ((if Node_View.Locale.Status = A11y.Properties.Present
                then Node_View.Locale
                else Snapshot.Locale),
               Limits);
         when Orientation =>
            return String_Result
              ((if Node_View.Orientation.Status = A11y.Properties.Present
                then Node_View.Orientation
                else Snapshot.Orientation),
               Limits);
         when Position_In_Set =>
            return Integer_Result
              (Snapshot.Position_In_Set,
               Limits,
               A11y.Resource_Limits.Native_Array_Size);
         when Size_Of_Set =>
            return Integer_Result
              (Snapshot.Size_Of_Set,
               Limits,
               A11y.Resource_Limits.Native_Array_Size);
         when Hierarchical_Level =>
            return Integer_Result
              (Snapshot.Hierarchical_Level,
               Limits,
               A11y.Resource_Limits.Traversal_Depth);
         when Heading_Level =>
            return Integer_Result
              (Snapshot.Heading_Level,
               Limits,
               A11y.Resource_Limits.Traversal_Depth);
         when Landmark =>
            return String_Result
              ((if Node_View.Landmark.Status = A11y.Properties.Present
                then Node_View.Landmark
                else Snapshot.Landmark),
               Limits);
         when Control_Type =>
            return
              (Kind         => Control_Type_Reply,
               Status       => A11y.Results.Success,
               Control_Type =>
                 A11y.Windows_Backend.UIA_Mappings.Map_Role
                   (Effective_Role));
         when Is_Enabled =>
            return State_Boolean_Result
              (A11y.Windows_Backend.UIA_Mappings.Is_Enabled);
         when Has_Keyboard_Focus =>
            return State_Boolean_Result
              (A11y.Windows_Backend.UIA_Mappings.Has_Keyboard_Focus);
         when Is_Keyboard_Focusable =>
            return State_Boolean_Result
              (A11y.Windows_Backend.UIA_Mappings.Is_Keyboard_Focusable);
         when Bounding_Rectangle =>
            return
              (Kind   => Rectangle_Reply,
               Status => A11y.Results.Success,
               Bounds => Effective_Bounds);
         when Is_Offscreen =>
            return State_Boolean_Result
              (A11y.Windows_Backend.UIA_Mappings.Is_Offscreen);
         when Is_Password =>
            return
              (Kind         => Boolean_Reply,
               Status       => A11y.Results.Success,
               Boolean_Item => Effective_Role = A11y.Roles.Password_Field);
         when Is_Required_For_Form =>
            return State_Boolean_Result
              (A11y.Windows_Backend.UIA_Mappings.Is_Required_For_Form);
      end case;
      end;
   exception
      when others =>
         return
           (Kind   => Error_Reply,
            Status => A11y.Results.Internal_Error);
   end Query_Property;

end A11y.Windows_Backend.UIA_Properties;
