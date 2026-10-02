with Ada.Strings;
with Ada.Strings.Fixed;

with A11y.Linux.ATSPi_Objects;
with A11y.Trees.Exposure_Views;

package body A11y.Linux.ATSPi_Accessible is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;
   use type A11y.Linux.DBus_Codec.Value_Kind;
   use type A11y.Properties.Property_Status;
   use type A11y.Results.Status_Code;
   use type A11y.Roles.Role;

   Help_Text_Key : constant String := "help-text";
   Visible_Title_Key : constant String := "visible-title";
   Placeholder_Key : constant String := "placeholder-text";
   Value_Text_Key : constant String := "accessible-value";
   Keyboard_Shortcut_Key : constant String := "keyboard-shortcut";
   Semantic_Identifier_Key : constant String := "semantic-identifier";
   Locale_Key : constant String := "locale";
   Orientation_Key : constant String := "orientation";
   Set_Position_Key : constant String := "set-position";
   Set_Size_Key : constant String := "set-size";
   Hierarchical_Level_Key : constant String := "hierarchical-level";
   Heading_Level_Key : constant String := "heading-level";
   Landmark_Key : constant String := "landmark";

   function Error (Status : A11y.Results.Status_Code) return Accessible_Reply is
     (Kind       => Error_Reply,
      Status     => Status,
      Error_Name => To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Error_Name (Status)));

   function Interface_Names
     (Role     : A11y.Roles.Role;
      Capabilities : A11y.Capabilities.Capability_Set;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return A11y.Linux.DBus_Codec.String_Vectors.Vector
   is
      Interfaces : A11y.Linux.DBus_Codec.String_Vectors.Vector;
      Encoded    : A11y.Linux.DBus_Codec.DBus_Value;

      procedure Append_Interface
        (Item : A11y.Linux.ATSPi_Objects.ATSPI_Interface)
      is
         Value : A11y.Linux.DBus_Codec.DBus_Value;
      begin
         if A11y.Results.Failed (Result) then
            return;
         end if;

         Value := A11y.Linux.DBus_Codec.Make_String
           (A11y.Linux.ATSPi_Objects.Interface_Name (Item),
            Limits,
            Result);
         if A11y.Results.Succeeded (Result) then
            Interfaces.Append (Value.Text_Item);
         end if;
      end Append_Interface;

      procedure Append_Capability_Interface
        (Capability     : A11y.Capabilities.Capability;
         Interface_Item : A11y.Linux.ATSPi_Objects.ATSPI_Interface)
      is
      begin
         if Capabilities (Capability) then
            Append_Interface (Interface_Item);
         end if;
      end Append_Capability_Interface;
   begin
      Result := A11y.Results.Ok;
      Append_Interface (A11y.Linux.ATSPi_Objects.Accessible);

      if Role = A11y.Roles.Application then
         Append_Interface (A11y.Linux.ATSPi_Objects.Application);
      end if;

      Append_Interface (A11y.Linux.ATSPi_Objects.Component);
      Append_Capability_Interface
        (A11y.Capabilities.Action, A11y.Linux.ATSPi_Objects.Action);
      Append_Capability_Interface
        (A11y.Capabilities.Selection, A11y.Linux.ATSPi_Objects.Selection);
      Append_Capability_Interface
        (A11y.Capabilities.Value, A11y.Linux.ATSPi_Objects.Value);
      Append_Capability_Interface
        (A11y.Capabilities.Text, A11y.Linux.ATSPi_Objects.Text);
      Append_Capability_Interface
        (A11y.Capabilities.Editable_Text,
         A11y.Linux.ATSPi_Objects.Editable_Text);

      if Capabilities (A11y.Capabilities.Table) then
         Append_Interface (A11y.Linux.ATSPi_Objects.Table);
         Append_Interface (A11y.Linux.ATSPi_Objects.Table_Cell);
      end if;

      Append_Capability_Interface
        (A11y.Capabilities.Document, A11y.Linux.ATSPi_Objects.Document);
      Append_Capability_Interface
        (A11y.Capabilities.Image, A11y.Linux.ATSPi_Objects.Image);
      Append_Capability_Interface
        (A11y.Capabilities.Live_Region,
         A11y.Linux.ATSPi_Objects.Live_Region);
      Append_Capability_Interface
        (A11y.Capabilities.Surface, A11y.Linux.ATSPi_Objects.Surface);

      if A11y.Results.Failed (Result) then
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      end if;

      Encoded := A11y.Linux.DBus_Codec.Make_String_Array
        (Interfaces, Limits, Result);
      if A11y.Results.Failed (Result) then
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      elsif Encoded.Kind /= A11y.Linux.DBus_Codec.String_Array_Value then
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      end if;

      Result := A11y.Results.Ok;
      return Interfaces;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
   end Interface_Names;

   function Exposure_Of
     (Snapshot : Accessible_Snapshot;
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
     (Snapshot : Accessible_Snapshot;
      Node     : A11y.Node_Ids.Node_Id)
      return Boolean
   is
      function Policy_For
        (Current : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy is
        (Exposure_Of (Snapshot, Current));

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Policy_For);

      Parent : A11y.Node_Ids.Node_Id;
      Query_Result : A11y.Results.Result;
   begin
      if not Snapshot.Use_Tree_Projection then
         return True;
      elsif not A11y.Node_Ids.Is_Valid (Snapshot.Root)
        or else not A11y.Node_Ids.Is_Valid (Node)
      then
         return False;
      elsif Node = Snapshot.Root then
         return Exposure_Of (Snapshot, Node) = A11y.Nodes.Expose_Node;
      end if;

      Parent := Exposure_View.Exposed_Parent_Of
        (Snapshot.Tree, Node, Snapshot.Limits, Query_Result);
      return A11y.Results.Succeeded (Query_Result)
        and then
          (A11y.Node_Ids.Is_Valid (Parent)
           or else Node = Snapshot.Root);
   exception
      when others =>
         return False;
   end Is_Externally_Exposed;

   function Projected_Child_Count
     (Snapshot : Accessible_Snapshot;
      Result   : out A11y.Results.Result)
      return Natural
   is
      Children : A11y.Trees.Child_Vectors.Vector;

      function Policy_For
        (Node : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy is
        (Exposure_Of (Snapshot, Node));

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Policy_For);
   begin
      if not Snapshot.Use_Tree_Projection then
         Result := A11y.Results.Ok;
         if Snapshot.Children.Is_Empty then
            return Snapshot.Child_Count;
         else
            return Natural (Snapshot.Children.Length);
         end if;
      elsif not A11y.Node_Ids.Is_Valid (Snapshot.Root)
        or else not Is_Externally_Exposed (Snapshot, Snapshot.Id)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return 0;
      end if;

      Exposure_View.Exposed_Children_Of
        (Snapshot.Tree, Snapshot.Id, Snapshot.Limits, Children, Result);
      if A11y.Results.Failed (Result) then
         return 0;
      end if;

      Result := A11y.Results.Ok;
      return Natural (Children.Length);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return 0;
   end Projected_Child_Count;

   function Projected_Child_At
     (Snapshot : Accessible_Snapshot;
      Index    : Natural;
      Result   : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id
   is
      Children : A11y.Trees.Child_Vectors.Vector;
      Target   : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;

      function Policy_For
        (Node : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy is
        (Exposure_Of (Snapshot, Node));

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Policy_For);
   begin
      if not Snapshot.Use_Tree_Projection then
         if Index >= Natural (Snapshot.Children.Length) then
            Result := (Status => A11y.Results.Invalid_Argument);
            return A11y.Node_Ids.No_Node;
         end if;

         Target := Snapshot.Children (Positive (Index + 1));
      elsif not A11y.Node_Ids.Is_Valid (Snapshot.Root)
        or else not Is_Externally_Exposed (Snapshot, Snapshot.Id)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      else
         Exposure_View.Exposed_Children_Of
           (Snapshot.Tree, Snapshot.Id, Snapshot.Limits, Children, Result);
         if A11y.Results.Failed (Result) then
            return A11y.Node_Ids.No_Node;
         elsif Index >= Natural (Children.Length) then
            Result := (Status => A11y.Results.Invalid_Argument);
            return A11y.Node_Ids.No_Node;
         end if;

         Target := Children (Positive (Index + 1));
      end if;

      if not A11y.Node_Ids.Is_Valid (Target) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      end if;

      Result := A11y.Results.Ok;
      return Target;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Node_Ids.No_Node;
   end Projected_Child_At;

   function Projected_Parent
     (Snapshot : Accessible_Snapshot;
      Result   : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id
   is
      Parent : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;

      function Policy_For
        (Node : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy is
        (Exposure_Of (Snapshot, Node));

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Policy_For);
   begin
      if not Snapshot.Use_Tree_Projection then
         Parent := Snapshot.Parent;
      elsif not A11y.Node_Ids.Is_Valid (Snapshot.Root)
        or else not Is_Externally_Exposed (Snapshot, Snapshot.Id)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      else
         Parent := Exposure_View.Exposed_Parent_Of
           (Snapshot.Tree, Snapshot.Id, Snapshot.Limits, Result);
         if A11y.Results.Failed (Result) then
            return A11y.Node_Ids.No_Node;
         end if;
      end if;

      if not A11y.Node_Ids.Is_Valid (Parent) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      end if;

      Result := A11y.Results.Ok;
      return Parent;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Node_Ids.No_Node;
   end Projected_Parent;

   function Projected_Index_In_Parent
     (Snapshot : Accessible_Snapshot;
      Result   : out A11y.Results.Result)
      return Integer
   is
      Parent : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Children : A11y.Trees.Child_Vectors.Vector;

      function Policy_For
        (Node : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy is
        (Exposure_Of (Snapshot, Node));

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Policy_For);
   begin
      if not Snapshot.Use_Tree_Projection then
         Result := A11y.Results.Ok;
         return Snapshot.Index_In_Parent;
      elsif not A11y.Node_Ids.Is_Valid (Snapshot.Root)
        or else not Is_Externally_Exposed (Snapshot, Snapshot.Id)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return -1;
      end if;

      Parent := Exposure_View.Exposed_Parent_Of
        (Snapshot.Tree, Snapshot.Id, Snapshot.Limits, Result);
      if A11y.Results.Failed (Result) then
         return -1;
      elsif not A11y.Node_Ids.Is_Valid (Parent) then
         Result := A11y.Results.Ok;
         return -1;
      end if;

      Exposure_View.Exposed_Children_Of
        (Snapshot.Tree, Parent, Snapshot.Limits, Children, Result);
      if A11y.Results.Failed (Result) then
         return -1;
      end if;

      for Index in Children.First_Index .. Children.Last_Index loop
         if Children (Index) = Snapshot.Id then
            Result := A11y.Results.Ok;
            return Integer (Index - 1);
         end if;
      end loop;

      Result := (Status => A11y.Results.Node_Unavailable);
      return -1;
   exception
      when Constraint_Error =>
         Result := (Status => A11y.Results.Resource_Limit);
         return -1;
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return -1;
   end Projected_Index_In_Parent;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Index    : Natural;
      Snapshot : Accessible_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Accessible_Reply
   is
      Result : A11y.Results.Result;
      Node : A11y.Node_Ids.Node_Id;
      Node_View : A11y.Semantic_Snapshots.Node_Metadata;
      Has_Node_View : Boolean := False;
      Encoded : A11y.Linux.DBus_Codec.DBus_Value;

      function Current_Role return A11y.Roles.Role is
        (if Has_Node_View then Node_View.Role else Snapshot.Role);

      function Current_Name return Ada.Strings.Unbounded.Unbounded_String is
        (if Has_Node_View then Node_View.Name.Value else Snapshot.Name);

      function Current_Description
        return Ada.Strings.Unbounded.Unbounded_String is
        (if Has_Node_View then Node_View.Description.Value
         else Snapshot.Description);

      function Current_Visible_Title return A11y.Properties.String_Property is
        (if Has_Node_View
           and then Node_View.Visible_Title.Status = A11y.Properties.Present
         then Node_View.Visible_Title
         else Snapshot.Visible_Title);

      function Current_Help_Text return A11y.Properties.String_Property is
        (if Has_Node_View then Node_View.Help_Text else Snapshot.Help_Text);

      function Current_Placeholder return A11y.Properties.String_Property is
        (if Has_Node_View then Node_View.Placeholder else Snapshot.Placeholder);

      function Current_Value_Text return A11y.Properties.String_Property is
        (if Has_Node_View then Node_View.Value_Text else Snapshot.Value_Text);

      function Current_Semantic_Identifier
        return A11y.Properties.String_Property is
        (if Has_Node_View
           and then Node_View.Semantic_Identifier.Status =
             A11y.Properties.Present
         then Node_View.Semantic_Identifier
         else Snapshot.Semantic_Identifier);

      function Current_Keyboard_Shortcut
        return A11y.Properties.String_Property is
        (if Has_Node_View
           and then Node_View.Keyboard_Shortcut.Status =
             A11y.Properties.Present
         then Node_View.Keyboard_Shortcut
         else Snapshot.Keyboard_Shortcut);

      function Current_Locale return A11y.Properties.String_Property is
        (if Has_Node_View
           and then Node_View.Locale.Status = A11y.Properties.Present
         then Node_View.Locale
         else Snapshot.Locale);

      function Current_Orientation return A11y.Properties.String_Property is
        (if Has_Node_View
           and then Node_View.Orientation.Status = A11y.Properties.Present
         then Node_View.Orientation
         else Snapshot.Orientation);

      function Current_Landmark return A11y.Properties.String_Property is
        (if Has_Node_View
           and then Node_View.Landmark.Status = A11y.Properties.Present
         then Node_View.Landmark
         else Snapshot.Landmark);

      function Current_Protected_Value_Text return Boolean is
        (if Has_Node_View then Node_View.Protected_Value_Text
         else Snapshot.Protected_Value_Text);

      function Current_States return A11y.States.State_Set is
        (if Has_Node_View then Node_View.States else Snapshot.States);

      function Current_Capabilities
        return A11y.Capabilities.Capability_Set is
        (if Has_Node_View then Node_View.Capabilities
         else Snapshot.Capabilities);
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Node := A11y.Linux.ATSPi_Objects.Node_From_Object_Path
        (Path, Session, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      if Snapshot.Use_Node_Metadata then
         Node_View := A11y.Semantic_Snapshots.Metadata
           (Snapshot.Nodes, Node);
         Has_Node_View := Node_View.Present;
      end if;

      if (Node /= Snapshot.Id and then not Has_Node_View)
        or else Snapshot.Defunct
      then
         return Error (A11y.Results.Node_Unavailable);
      elsif Snapshot.Use_Tree_Projection
        and then not Is_Externally_Exposed (Snapshot, Node)
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      if Method = "GetRole" then
         return
           (Kind   => Role_Reply,
            Status => A11y.Results.Success,
            Role   => A11y.Linux.ATSPi_Mappings.Map_Role (Current_Role));
      elsif Method = "GetInterfaces" then
         declare
            Interfaces : constant A11y.Linux.DBus_Codec.String_Vectors.Vector :=
              Interface_Names
                (Current_Role, Current_Capabilities, Limits, Result);
         begin
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            return
              (Kind    => String_Array_Reply,
               Status  => A11y.Results.Success,
               Strings => Interfaces);
         end;
      elsif Method = "GetApplication" then
         if not A11y.Node_Ids.Is_Valid (Snapshot.Root) then
            return Error (A11y.Results.Node_Unavailable);
         end if;

         return
           (Kind   => Node_Reply,
            Status => A11y.Results.Success,
            Node   => Snapshot.Root);
      elsif Method = "GetRoleName"
        or else Method = "GetLocalizedRoleName"
      then
         Encoded := A11y.Linux.DBus_Codec.Make_String
           (A11y.Roles.Stable_Name (Current_Role), Limits, Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;
         return
           (Kind   => String_Reply,
            Status => A11y.Results.Success,
            Text   => Encoded.Text_Item);
      elsif Method = "GetState" then
         declare
            Effective_States : constant A11y.States.State_Set :=
              A11y.States.Derive
                (Current_States, Current_Role, Current_Capabilities);
         begin
            Result := A11y.States.Validate (Effective_States);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            return
              (Kind   => State_Set_Reply,
               Status => A11y.Results.Success,
               States => A11y.Linux.ATSPi_Mappings.Map_States
                 (Effective_States));
         end;
      elsif Method = "GetName" then
         Encoded := A11y.Linux.DBus_Codec.Make_String
           (To_String (Current_Name), Limits, Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;
         return
           (Kind   => String_Reply,
            Status => A11y.Results.Success,
            Text   => Encoded.Text_Item);
      elsif Method = "GetDescription" then
         Encoded := A11y.Linux.DBus_Codec.Make_String
           (To_String (Current_Description), Limits, Result);
         if A11y.Results.Failed (Result) then
            return Error (Result.Status);
         end if;
         return
           (Kind   => String_Reply,
            Status => A11y.Results.Success,
            Text   => Encoded.Text_Item);
      elsif Method = "GetAttributes" then
         declare
            Items : Attribute_Entry_Vectors.Vector;

            procedure Append_Attribute
              (Key      : String;
               Property : A11y.Properties.String_Property) is
               Key_Value : A11y.Linux.DBus_Codec.DBus_Value;
               Text_Value : A11y.Linux.DBus_Codec.DBus_Value;
            begin
               case Property.Status is
                  when A11y.Properties.Present |
                       A11y.Properties.Empty =>
                     Key_Value := A11y.Linux.DBus_Codec.Make_String
                       (Key, Limits, Result);
                     if A11y.Results.Failed (Result) then
                        return;
                     end if;

                     Text_Value := A11y.Linux.DBus_Codec.Make_String
                       (To_String (Property.Value), Limits, Result);
                     if A11y.Results.Failed (Result) then
                        return;
                     end if;

                     Items.Append
                       (Attribute_Entry'
                          (Key   => Key_Value.Text_Item,
                           Value => Text_Value.Text_Item));
                  when A11y.Properties.Unsupported =>
                     null;
                  when A11y.Properties.Temporarily_Unavailable =>
                     Result := (Status => A11y.Results.Busy);
                  when A11y.Properties.Node_Unavailable =>
                     Result := (Status => A11y.Results.Node_Unavailable);
                  when A11y.Properties.Resource_Limited =>
                     Result := (Status => A11y.Results.Resource_Limit);
                  when A11y.Properties.Permission_Denied =>
                     Result := (Status => A11y.Results.Permission_Denied);
                  when A11y.Properties.Error =>
                     Result := (Status => A11y.Results.Internal_Error);
               end case;
            end Append_Attribute;

            procedure Append_Integer_Attribute
              (Key      : String;
               Property : A11y.Properties.Integer_Property) is
               Key_Value : A11y.Linux.DBus_Codec.DBus_Value;
               Text_Value : A11y.Linux.DBus_Codec.DBus_Value;
            begin
               case Property.Status is
                  when A11y.Properties.Present =>
                     if Property.Value < 0 then
                        Result := (Status => A11y.Results.Invalid_Range);
                        return;
                     end if;

                     Key_Value := A11y.Linux.DBus_Codec.Make_String
                       (Key, Limits, Result);
                     if A11y.Results.Failed (Result) then
                        return;
                     end if;

                     Text_Value := A11y.Linux.DBus_Codec.Make_String
                       (Ada.Strings.Fixed.Trim
                          (Integer'Image (Property.Value),
                           Ada.Strings.Left),
                        Limits,
                        Result);
                     if A11y.Results.Failed (Result) then
                        return;
                     end if;

                     Items.Append
                       (Attribute_Entry'
                          (Key   => Key_Value.Text_Item,
                           Value => Text_Value.Text_Item));
                  when A11y.Properties.Unsupported |
                       A11y.Properties.Empty =>
                     null;
                  when A11y.Properties.Temporarily_Unavailable =>
                     Result := (Status => A11y.Results.Busy);
                  when A11y.Properties.Node_Unavailable =>
                     Result := (Status => A11y.Results.Node_Unavailable);
                  when A11y.Properties.Resource_Limited =>
                     Result := (Status => A11y.Results.Resource_Limit);
                  when A11y.Properties.Permission_Denied =>
                     Result := (Status => A11y.Results.Permission_Denied);
                  when A11y.Properties.Error =>
                     Result := (Status => A11y.Results.Internal_Error);
               end case;
            end Append_Integer_Attribute;
         begin
            Result := A11y.Resource_Limits.Validate (Limits);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            Append_Attribute (Help_Text_Key, Current_Help_Text);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            Append_Attribute (Visible_Title_Key, Current_Visible_Title);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            Append_Attribute (Placeholder_Key, Current_Placeholder);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            if A11y.Nodes.Protected_Value_Query_Status
              (Current_Role,
               A11y.Properties.Present,
               Current_Protected_Value_Text) = A11y.Properties.Present
            then
               Append_Attribute (Value_Text_Key, Current_Value_Text);
               if A11y.Results.Failed (Result) then
                  return Error (Result.Status);
               end if;
            end if;
            Append_Attribute
              (Keyboard_Shortcut_Key, Current_Keyboard_Shortcut);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            Append_Attribute
              (Semantic_Identifier_Key, Current_Semantic_Identifier);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            Append_Attribute (Locale_Key, Current_Locale);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            Append_Attribute (Orientation_Key, Current_Orientation);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            Append_Integer_Attribute
              (Set_Position_Key, Snapshot.Set_Position);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            Append_Integer_Attribute (Set_Size_Key, Snapshot.Set_Size);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            Append_Integer_Attribute
              (Hierarchical_Level_Key, Snapshot.Hierarchical_Level);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            Append_Integer_Attribute
              (Heading_Level_Key, Snapshot.Heading_Level);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            Append_Attribute (Landmark_Key, Current_Landmark);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            return
              (Kind       => Attribute_Set_Reply,
               Status     => A11y.Results.Success,
               Attributes => Items);
         end;
      elsif Method = "GetChildCount" then
         declare
            Count : constant Natural :=
              Projected_Child_Count (Snapshot, Result);
         begin
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            Encoded := A11y.Linux.DBus_Codec.Make_UInt32
              (Count, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;
            return
              (Kind   => UInt32_Reply,
               Status => A11y.Results.Success,
               UInt32 => Encoded.UInt32_Item);
         end;
      elsif Method = "GetChildAtIndex" then
         declare
            Child : constant A11y.Node_Ids.Node_Id :=
              Projected_Child_At (Snapshot, Index, Result);
         begin
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            return
              (Kind   => Node_Reply,
               Status => A11y.Results.Success,
               Node   => Child);
         end;
      elsif Method = "GetChildren" then
         declare
            Children : A11y.Trees.Child_Vectors.Vector;
         begin
            if not Snapshot.Use_Tree_Projection then
               Children := Snapshot.Children;
               Result := A11y.Results.Ok;
            elsif not A11y.Node_Ids.Is_Valid (Snapshot.Root)
              or else not Is_Externally_Exposed (Snapshot, Snapshot.Id)
            then
               return Error (A11y.Results.Node_Unavailable);
            else
               declare
                  function Policy_For
                    (Node : A11y.Node_Ids.Node_Id)
                     return A11y.Nodes.Exposure_Policy is
                    (Exposure_Of (Snapshot, Node));

                  package Exposure_View is new A11y.Trees.Exposure_Views
                    (Exposure_Of => Policy_For);
               begin
                  Exposure_View.Exposed_Children_Of
                    (Snapshot.Tree,
                     Snapshot.Id,
                     Snapshot.Limits,
                     Children,
                     Result);
               end;
            end if;

            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            return
              (Kind   => Node_Array_Reply,
               Status => A11y.Results.Success,
               Nodes  => Children);
         end;
      elsif Method = "GetParent" then
         declare
            Parent : constant A11y.Node_Ids.Node_Id :=
              Projected_Parent (Snapshot, Result);
         begin
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            return
              (Kind   => Node_Reply,
               Status => A11y.Results.Success,
               Node   => Parent);
         end;
      elsif Method = "GetIndexInParent" then
         declare
            Parent_Index : constant Integer :=
              Projected_Index_In_Parent (Snapshot, Result);
         begin
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            Encoded := A11y.Linux.DBus_Codec.Make_Int32
              (Parent_Index, Result);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            end if;

            return
              (Kind   => Int32_Reply,
               Status => A11y.Results.Success,
               Int32  => Encoded.Int32_Item);
         end;
      elsif Method = "GetRelationSet" then
         declare
            Items : Relation_Entry_Vectors.Vector;
            Total : Natural := 0;
            Limit : Natural;
         begin
            Result := A11y.Resource_Limits.Validate (Limits);
            if A11y.Results.Failed (Result) then
               return Error (Result.Status);
            elsif Snapshot.Use_Tree_Projection
              and then
                (not A11y.Node_Ids.Is_Valid (Snapshot.Root)
                 or else not Is_Externally_Exposed
                   (Snapshot, Node))
            then
               return Error (A11y.Results.Node_Unavailable);
            end if;
            Limit := Natural
                 (A11y.Resource_Limits.Value
                 (Limits,
                  A11y.Resource_Limits.Relation_Targets_Returned));

            for Kind in A11y.Relations.Relation_Kind loop
               declare
                  Raw_Targets : constant A11y.Relations.Target_Vectors.Vector :=
                    A11y.Relations.Targets
                      (Snapshot.Relations, Node, Kind);
                  Targets : A11y.Relations.Target_Vectors.Vector;
                  Item : Relation_Entry;
               begin
                  for Target of Raw_Targets loop
                     if not Snapshot.Use_Tree_Projection
                       or else Is_Externally_Exposed (Snapshot, Target)
                     then
                        Targets.Append (Target);
                     end if;
                  end loop;

                  if not Targets.Is_Empty then
                     if Natural (Targets.Length) > Limit - Total then
                        return Error (A11y.Results.Resource_Limit);
                     end if;
                     Total := Total + Natural (Targets.Length);

                     Item.Kind := A11y.Linux.ATSPi_Mappings.Map_Relation
                       (Kind);
                     Item.Targets := Targets;
                     Items.Append (Item);
                  end if;
               end;
            end loop;

            return
              (Kind      => Relation_Set_Reply,
               Status    => A11y.Results.Success,
               Relations => Items);
         end;
      else
         return Error (A11y.Results.Unsupported_Capability);
      end if;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Handle_Method;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Index    : Natural;
      Snapshot : Accessible_Snapshot)
      return Accessible_Reply is
     (Handle_Method
        (Session, Path, Method, Index, Snapshot, Snapshot.Limits));

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Snapshot : Accessible_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Accessible_Reply is
     (Handle_Method (Session, Path, Method, 0, Snapshot, Limits));

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Snapshot : Accessible_Snapshot)
      return Accessible_Reply is
     (Handle_Method (Session, Path, Method, 0, Snapshot, Snapshot.Limits));

end A11y.Linux.ATSPi_Accessible;
