with Ada.Strings.Unbounded;

with A11y.Geometry;
with A11y.Trees;

package body A11y.Semantic_Snapshots is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;

   function In_Range (Node : A11y.Node_Ids.Node_Id) return Boolean is
      Slot : constant Natural := Slot_Of (Node);
   begin
      return A11y.Node_Ids.Is_Valid (Node)
        and then Slot in 1 .. A11y.Trees.Max_Attached_Nodes;
   end In_Range;

   function Has_Node
     (Snapshot : Semantic_Snapshot;
      Node     : A11y.Node_Ids.Node_Id)
      return Boolean
   is
   begin
      if not In_Range (Node) then
         return False;
      end if;

      for Item of Snapshot.Nodes loop
         if Item.Node = Node and then Item.Metadata.Present then
            return True;
         end if;
      end loop;

      return False;
   end Has_Node;

   function Node_Count (Snapshot : Semantic_Snapshot) return Natural is
     (Natural (Snapshot.Nodes.Length));

   function Metadata
     (Snapshot : Semantic_Snapshot;
      Node     : A11y.Node_Ids.Node_Id)
      return Node_Metadata
   is
   begin
      if not In_Range (Node) then
         return (others => <>);
      end if;

      for Item of Snapshot.Nodes loop
         if Item.Node = Node then
            return Item.Metadata;
         end if;
      end loop;

      return (others => <>);
   end Metadata;

   procedure Set_Node
     (Snapshot     : in out Semantic_Snapshot;
      Node         : A11y.Node_Ids.Node_Id;
      Role         : A11y.Roles.Role;
      Name         : String;
      Description  : String;
      States       : A11y.States.State_Set;
      Capabilities : A11y.Capabilities.Capability_Set;
      Exposure     : A11y.Nodes.Exposure_Policy;
      Result       : out A11y.Results.Result)
   is
      Contract : A11y.Results.Result;
      Item : Node_Metadata;
   begin
      if not In_Range (Node) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      Contract :=
        A11y.Nodes.Validate_Contract
          (Role         => Role,
           States       => States,
           Capabilities => Capabilities,
           Exposure     => Exposure);
      if A11y.Results.Failed (Contract) then
         Result := Contract;
         return;
      end if;

      Item :=
        (Present      => True,
         Role         => Role,
         Name         =>
           (Status => A11y.Properties.Present,
            Value  => To_Unbounded_String (Name)),
         Visible_Title =>
           (Status => A11y.Properties.Unsupported,
            Value  => Null_Unbounded_String),
         Description  =>
           (Status => (if Description'Length = 0
                       then A11y.Properties.Empty
                       else A11y.Properties.Present),
            Value  => To_Unbounded_String (Description)),
         Help_Text    => (Status => A11y.Properties.Unsupported,
                          Value  => Null_Unbounded_String),
         Placeholder  => (Status => A11y.Properties.Unsupported,
                          Value  => Null_Unbounded_String),
         Value_Text   => (Status => A11y.Properties.Unsupported,
                          Value  => Null_Unbounded_String),
         Protected_Value_Text => False,
         Bounds       =>
           (Status => A11y.Properties.Unsupported,
            Value  => A11y.Geometry.Empty_Rectangle),
         Semantic_Identifier =>
           (Status => A11y.Properties.Unsupported,
            Value  => Null_Unbounded_String),
         Keyboard_Shortcut =>
           (Status => A11y.Properties.Unsupported,
            Value  => Null_Unbounded_String),
         Locale       =>
           (Status => A11y.Properties.Unsupported,
            Value  => Null_Unbounded_String),
         Orientation  =>
           (Status => A11y.Properties.Unsupported,
            Value  => Null_Unbounded_String),
         Landmark     =>
           (Status => A11y.Properties.Unsupported,
            Value  => Null_Unbounded_String),
         States       => States,
         Capabilities => Capabilities,
         Exposure     => Exposure);

      if not Snapshot.Nodes.Is_Empty then
         for Index in Snapshot.Nodes.First_Index .. Snapshot.Nodes.Last_Index loop
            if Snapshot.Nodes (Index).Node = Node then
               Snapshot.Nodes.Replace_Element
                 (Index,
                  (Node     => Node,
                   Metadata => Item));
               Result := A11y.Results.Ok;
               return;
            end if;
         end loop;
      end if;

      Snapshot.Nodes.Append
        (Node_Metadata_Entry'(Node => Node, Metadata => Item));
      Result := A11y.Results.Ok;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Set_Node;

   procedure Set_Node
     (Snapshot     : in out Semantic_Snapshot;
      Node         : A11y.Node_Ids.Node_Id;
      Role         : A11y.Roles.Role;
      Name         : String;
      States       : A11y.States.State_Set;
      Capabilities : A11y.Capabilities.Capability_Set;
      Exposure     : A11y.Nodes.Exposure_Policy;
      Result       : out A11y.Results.Result) is
   begin
      Set_Node
        (Snapshot     => Snapshot,
         Node         => Node,
         Role         => Role,
         Name         => Name,
         Description  => "",
         States       => States,
         Capabilities => Capabilities,
         Exposure     => Exposure,
         Result       => Result);
   end Set_Node;

   procedure Set_Node
     (Snapshot     : in out Semantic_Snapshot;
      Node         : A11y.Node_Ids.Node_Id;
      Role         : A11y.Roles.Role;
      Name         : String;
      Description  : String;
      Help_Text    : A11y.Properties.String_Property;
      Placeholder  : A11y.Properties.String_Property;
      Value_Text   : A11y.Properties.String_Property;
      Protected_Value_Text : Boolean;
      Bounds       : A11y.Properties.Rectangle_Property;
      Semantic_Identifier : A11y.Properties.String_Property;
      Visible_Title : A11y.Properties.String_Property;
      Keyboard_Shortcut : A11y.Properties.String_Property;
      Locale       : A11y.Properties.String_Property;
      Orientation  : A11y.Properties.String_Property;
      Landmark     : A11y.Properties.String_Property;
      States       : A11y.States.State_Set;
      Capabilities : A11y.Capabilities.Capability_Set;
      Exposure     : A11y.Nodes.Exposure_Policy;
      Result       : out A11y.Results.Result)
   is
      Item : Node_Metadata;
   begin
      Set_Node
        (Snapshot     => Snapshot,
         Node         => Node,
         Role         => Role,
         Name         => Name,
         Description  => Description,
         States       => States,
         Capabilities => Capabilities,
         Exposure     => Exposure,
         Result       => Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Item := Metadata (Snapshot, Node);
      Item.Help_Text := Help_Text;
      Item.Placeholder := Placeholder;
      Item.Value_Text := Value_Text;
      Item.Protected_Value_Text := Protected_Value_Text;
      Item.Bounds := Bounds;
      Item.Semantic_Identifier := Semantic_Identifier;
      Item.Visible_Title := Visible_Title;
      Item.Keyboard_Shortcut := Keyboard_Shortcut;
      Item.Locale := Locale;
      Item.Orientation := Orientation;
      Item.Landmark := Landmark;

      if not Snapshot.Nodes.Is_Empty then
         for Index in Snapshot.Nodes.First_Index .. Snapshot.Nodes.Last_Index loop
            if Snapshot.Nodes (Index).Node = Node then
               Snapshot.Nodes.Replace_Element
                 (Index,
                  (Node     => Node,
                   Metadata => Item));
               Result := A11y.Results.Ok;
               return;
            end if;
         end loop;
      end if;

      Result := (Status => A11y.Results.Internal_Error);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Set_Node;

   procedure Set_Node
     (Snapshot     : in out Semantic_Snapshot;
      Node         : A11y.Node_Ids.Node_Id;
      Role         : A11y.Roles.Role;
      Name         : String;
      Description  : String;
      Help_Text    : A11y.Properties.String_Property;
      Placeholder  : A11y.Properties.String_Property;
      Value_Text   : A11y.Properties.String_Property;
      Protected_Value_Text : Boolean;
      Bounds       : A11y.Properties.Rectangle_Property;
      States       : A11y.States.State_Set;
      Capabilities : A11y.Capabilities.Capability_Set;
      Exposure     : A11y.Nodes.Exposure_Policy;
      Result       : out A11y.Results.Result) is
   begin
      Set_Node
        (Snapshot     => Snapshot,
         Node         => Node,
         Role         => Role,
         Name         => Name,
         Description  => Description,
         Help_Text    => Help_Text,
         Placeholder  => Placeholder,
         Value_Text   => Value_Text,
         Protected_Value_Text => Protected_Value_Text,
         Bounds       => Bounds,
         Semantic_Identifier =>
           (Status => A11y.Properties.Unsupported,
            Value  => Null_Unbounded_String),
         Visible_Title =>
           (Status => A11y.Properties.Unsupported,
            Value  => Null_Unbounded_String),
         Keyboard_Shortcut =>
           (Status => A11y.Properties.Unsupported,
            Value  => Null_Unbounded_String),
         Locale       =>
           (Status => A11y.Properties.Unsupported,
            Value  => Null_Unbounded_String),
         Orientation  =>
           (Status => A11y.Properties.Unsupported,
            Value  => Null_Unbounded_String),
         Landmark     =>
           (Status => A11y.Properties.Unsupported,
            Value  => Null_Unbounded_String),
         States       => States,
         Capabilities => Capabilities,
         Exposure     => Exposure,
         Result       => Result);
   end Set_Node;

   procedure Set_Node
     (Snapshot     : in out Semantic_Snapshot;
      Node         : A11y.Node_Ids.Node_Id;
      Role         : A11y.Roles.Role;
      Name         : String;
      Description  : String;
      Help_Text    : A11y.Properties.String_Property;
      Placeholder  : A11y.Properties.String_Property;
      Value_Text   : A11y.Properties.String_Property;
      Protected_Value_Text : Boolean;
      States       : A11y.States.State_Set;
      Capabilities : A11y.Capabilities.Capability_Set;
      Exposure     : A11y.Nodes.Exposure_Policy;
      Result       : out A11y.Results.Result) is
   begin
      Set_Node
        (Snapshot     => Snapshot,
         Node         => Node,
         Role         => Role,
         Name         => Name,
         Description  => Description,
         Help_Text    => Help_Text,
         Placeholder  => Placeholder,
         Value_Text   => Value_Text,
         Protected_Value_Text => Protected_Value_Text,
         Bounds       =>
           (Status => A11y.Properties.Unsupported,
            Value  => A11y.Geometry.Empty_Rectangle),
         States       => States,
         Capabilities => Capabilities,
         Exposure     => Exposure,
         Result       => Result);
   end Set_Node;

   procedure Clear_Node
     (Snapshot : in out Semantic_Snapshot;
      Node     : A11y.Node_Ids.Node_Id;
      Result   : out A11y.Results.Result)
   is
   begin
      if not In_Range (Node) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      if not Snapshot.Nodes.Is_Empty then
         for Index in Snapshot.Nodes.First_Index .. Snapshot.Nodes.Last_Index loop
            if Snapshot.Nodes (Index).Node = Node then
               Snapshot.Nodes.Delete (Index);
               Result := A11y.Results.Ok;
               return;
            end if;
         end loop;
      end if;

      Result := A11y.Results.Ok;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Clear_Node;

   function Validate_Node
     (Snapshot : Semantic_Snapshot;
      Node     : A11y.Node_Ids.Node_Id)
      return A11y.Results.Result
   is
      Item : constant Node_Metadata := Metadata (Snapshot, Node);
   begin
      if not In_Range (Node) or else not Item.Present then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      return
        A11y.Nodes.Validate_Contract
          (Role         => Item.Role,
           States       => Item.States,
           Capabilities => Item.Capabilities,
           Exposure     => Item.Exposure);
   end Validate_Node;

end A11y.Semantic_Snapshots;
