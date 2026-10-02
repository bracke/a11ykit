with A11y.Trees.Exposure_Views;

package body A11y.MacOS_Backend.NSAccessibility_Properties is
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;
   use type A11y.Properties.Property_Status;

   function Neutral_Property (Attribute : Core_Attribute)
      return A11y.Properties.Property_Id is
     (case Attribute is
        when Role => A11y.Properties.Role_Property,
        when Title => A11y.Properties.Visible_Title,
        when Label => A11y.Properties.Accessible_Name,
        when Description => A11y.Properties.Description,
        when Help => A11y.Properties.Help_Text,
        when Placeholder => A11y.Properties.Placeholder,
        when Value_Text => A11y.Properties.Value_Text,
        when Keyboard_Shortcut => A11y.Properties.Keyboard_Shortcut,
        when Locale => A11y.Properties.Locale,
        when Orientation => A11y.Properties.Orientation,
        when Position_In_Set => A11y.Properties.Set_Position,
        when Size_Of_Set => A11y.Properties.Set_Size,
        when Hierarchical_Level => A11y.Properties.Hierarchical_Level,
        when Heading_Level => A11y.Properties.Heading_Level,
        when Landmark => A11y.Properties.Landmark,
        when Identifier => A11y.Properties.Semantic_Identifier,
        when Frame => A11y.Properties.Bounds,
        when Enabled |
             Focused |
             Selected |
             Required |
             Modal => A11y.Properties.State_Property);

   function Integer_Result
     (Value      : A11y.Properties.Integer_Property;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config;
      Limit_Kind : A11y.Resource_Limits.Limit_Kind)
      return Attribute_Reply
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

   function String_Result
     (Value  : A11y.Properties.String_Property;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Attribute_Reply
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
            Name         => Snapshot.Label,
            Description  => Snapshot.Description,
            Help_Text    => Snapshot.Help,
            Placeholder  => Snapshot.Placeholder,
            Value_Text   => Snapshot.Value_Text,
            Protected_Value_Text => Snapshot.Protected_Value_Text,
            Bounds       => A11y.Properties.Present (Snapshot.Bounds),
            Semantic_Identifier => Snapshot.Identifier,
            Visible_Title => Snapshot.Title,
            Keyboard_Shortcut => Snapshot.Keyboard_Shortcut,
            Locale       => Snapshot.Locale,
            Orientation  => Snapshot.Orientation,
            Landmark     => Snapshot.Landmark,
            States       => Snapshot.States,
            Capabilities => Snapshot.Capabilities,
            Exposure     => A11y.Nodes.Expose_Node));

   function Query_Attribute
     (Snapshot  : Property_Snapshot;
      Attribute : Core_Attribute)
      return Attribute_Reply is
     (Query_Attribute (Snapshot, Attribute, Snapshot.Limits));

   function Query_Attribute_Names
     (Snapshot : Property_Snapshot)
      return Attribute_Reply is
     (Query_Attribute_Names (Snapshot, Snapshot.Limits));

   function Query_Attribute_Names
     (Snapshot : Property_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Attribute_Reply
   is
      Attributes : Core_Attribute_Set := [others => True];
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
         Effective_States : constant A11y.States.State_Set :=
           A11y.States.Derive
             (Node_View.States, Node_View.Role, Node_View.Capabilities);
         Validation : constant A11y.Results.Result :=
           A11y.States.Validate (Effective_States);
      begin
         if Snapshot.Use_Node_Metadata
           and then Node_View.Exposure /= A11y.Nodes.Expose_Node
         then
            return
              (Kind   => Error_Reply,
               Status => A11y.Results.Node_Unavailable);
         elsif A11y.Results.Failed (Validation) then
            return
              (Kind   => Error_Reply,
               Status => Validation.Status);
         end if;
      end;

      declare
         Node_View : constant A11y.Semantic_Snapshots.Node_Metadata :=
           Metadata_View (Snapshot);
      begin
         if A11y.Nodes.Protected_Value_Query_Status
           (Node_View.Role,
            A11y.Properties.Present,
            Node_View.Protected_Value_Text) =
              A11y.Properties.Permission_Denied
         then
            Attributes (Value_Text) := False;
         end if;
      end;

      return
        (Kind       => Attribute_Set_Reply,
         Status     => A11y.Results.Success,
         Attributes => Attributes);
   exception
      when others =>
         return
           (Kind   => Error_Reply,
            Status => A11y.Results.Internal_Error);
   end Query_Attribute_Names;

   function Query_Attribute
     (Snapshot  : Property_Snapshot;
      Attribute : Core_Attribute;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config)
      return Attribute_Reply
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
         Effective_Role : constant A11y.Roles.Role := Node_View.Role;
         Effective_States : constant A11y.States.State_Set :=
           A11y.States.Derive
             (Node_View.States, Effective_Role, Node_View.Capabilities);
         Mapped_States : constant
           A11y.MacOS_Backend.NSAccessibility_Mappings.NSAX_State_Set :=
             A11y.MacOS_Backend.NSAccessibility_Mappings.Map_States
               (Effective_States);
         Effective_Bounds : constant A11y.Geometry.Rectangle :=
           (if Node_View.Bounds.Status = A11y.Properties.Present
            then Node_View.Bounds.Value
            else Snapshot.Bounds);
      begin
      if Snapshot.Use_Node_Metadata
        and then Node_View.Exposure /= A11y.Nodes.Expose_Node
      then
         return
           (Kind   => Error_Reply,
            Status => A11y.Results.Node_Unavailable);
      end if;

      Validation := A11y.States.Validate (Effective_States);
      if A11y.Results.Failed (Validation) then
         return
           (Kind   => Error_Reply,
            Status => Validation.Status);
      end if;

      case Attribute is
         when Role =>
            return
              (Kind   => Role_Reply,
               Status => A11y.Results.Success,
               Role   =>
                 A11y.MacOS_Backend.NSAccessibility_Mappings.Map_Role
                   (Effective_Role));
         when Title =>
            return String_Result
              ((if Node_View.Visible_Title.Status = A11y.Properties.Present
                then Node_View.Visible_Title
                else Snapshot.Title),
               Limits);
         when Label =>
            return String_Result (Node_View.Name, Limits);
         when Description =>
            return String_Result (Node_View.Description, Limits);
         when Help =>
            return String_Result (Node_View.Help_Text, Limits);
         when Placeholder =>
            return String_Result (Node_View.Placeholder, Limits);
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
         when Identifier =>
            return String_Result
              ((if Node_View.Semantic_Identifier.Status =
                   A11y.Properties.Present
                then Node_View.Semantic_Identifier
                else Snapshot.Identifier),
               Limits);
         when Frame =>
            return
              (Kind   => Rectangle_Reply,
               Status => A11y.Results.Success,
               Bounds => Effective_Bounds);
         when Enabled =>
            return
              (Kind         => Boolean_Reply,
               Status       => A11y.Results.Success,
               Boolean_Item => Mapped_States
                 (A11y.MacOS_Backend.NSAccessibility_Mappings.Enabled));
         when Focused =>
            return
              (Kind         => Boolean_Reply,
               Status       => A11y.Results.Success,
               Boolean_Item => Mapped_States
                 (A11y.MacOS_Backend.NSAccessibility_Mappings.Focused));
         when Selected =>
            return
              (Kind         => Boolean_Reply,
               Status       => A11y.Results.Success,
               Boolean_Item => Mapped_States
                 (A11y.MacOS_Backend.NSAccessibility_Mappings.Selected));
         when Required =>
            return
              (Kind         => Boolean_Reply,
               Status       => A11y.Results.Success,
               Boolean_Item => Mapped_States
                 (A11y.MacOS_Backend.NSAccessibility_Mappings.Required));
         when Modal =>
            return
              (Kind         => Boolean_Reply,
               Status       => A11y.Results.Success,
               Boolean_Item => Mapped_States
                 (A11y.MacOS_Backend.NSAccessibility_Mappings.Modal));
      end case;
      end;
   exception
      when others =>
         return
           (Kind   => Error_Reply,
            Status => A11y.Results.Internal_Error);
   end Query_Attribute;

end A11y.MacOS_Backend.NSAccessibility_Properties;
