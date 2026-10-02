with Ada.Strings.Unbounded;

with A11y.Nodes;
with A11y.Properties;

package body A11ykit.Compatibility is
   use Ada.Strings.Unbounded;

   function To_Semantic_Role
     (Role : A11ykit.Role)
      return A11y.Roles.Role is
     (case Role is
        when A11ykit.Role_Window     => A11y.Roles.Window,
        when A11ykit.Role_Dialog     => A11y.Roles.Dialog,
        when A11ykit.Role_Pane       => A11y.Roles.Group,
        when A11ykit.Role_Toolbar    => A11y.Roles.Tool_Bar,
        when A11ykit.Role_Button     => A11y.Roles.Button,
        when A11ykit.Role_Text_Input => A11y.Roles.Text_Field,
        when A11ykit.Role_List       => A11y.Roles.List,
        when A11ykit.Role_List_Item  => A11y.Roles.List_Item,
        when A11ykit.Role_Table      => A11y.Roles.Table,
        when A11ykit.Role_Table_Row  => A11y.Roles.Row,
        when A11ykit.Role_Heading    => A11y.Roles.Heading,
        when A11ykit.Role_Status     => A11y.Roles.Status,
        when A11ykit.Role_Unknown    => A11y.Roles.Custom);

   function To_Semantic_Bounds
     (Bounds : A11ykit.Rectangle)
      return A11y.Geometry.Rectangle is
     ((Origin =>
         (X => A11y.Geometry.Coordinate (Bounds.X),
          Y => A11y.Geometry.Coordinate (Bounds.Y)),
       Extent =>
         (Width  => A11y.Geometry.Length (Bounds.Width),
          Height => A11y.Geometry.Length (Bounds.Height))));

   function To_Semantic_States
     (State : A11ykit.State;
      Role  : A11ykit.Role)
      return A11y.States.State_Set
   is
      Result : A11y.States.State_Set := A11y.States.Empty_State_Set;
   begin
      if State.Enabled then
         Result (A11y.States.Enabled) := True;
         Result (A11y.States.Sensitive) := True;
      end if;

      Result (A11y.States.Visible) := True;
      Result (A11y.States.Showing) := True;

      if State.Selected then
         case Role is
            when A11ykit.Role_List_Item | A11ykit.Role_Table_Row =>
               Result (A11y.States.Selected) := True;
            when A11ykit.Role_Button =>
               --  Legacy draw lists use Selected for the active member of a
               --  toolbar button group. A semantic Button is not a selectable
               --  collection item; its corresponding state is Pressed.
               Result (A11y.States.Pressed) := True;
            when others =>
               null;
         end case;
      end if;

      if State.Focused then
         Result (A11y.States.Focused) := True;
      end if;

      case Role is
         when A11ykit.Role_Button | A11ykit.Role_Text_Input |
              A11ykit.Role_List_Item | A11ykit.Role_Table_Row =>
            Result (A11y.States.Focusable) := True;
         when others =>
            null;
      end case;

      if Role in A11ykit.Role_List_Item | A11ykit.Role_Table_Row then
         Result (A11y.States.Selectable) := True;
      end if;

      return Result;
   end To_Semantic_States;

   function To_Semantic_Capabilities
     (Role : A11ykit.Role)
      return A11y.Capabilities.Capability_Set
   is
      Result : A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.Empty_Capability_Set;
   begin
      case Role is
         when A11ykit.Role_Window | A11ykit.Role_Dialog =>
            Result (A11y.Capabilities.Surface) := True;
         when A11ykit.Role_Button =>
            Result (A11y.Capabilities.Action) := True;
         when A11ykit.Role_Text_Input =>
            Result (A11y.Capabilities.Text) := True;
            Result (A11y.Capabilities.Editable_Text) := True;
         when A11ykit.Role_List =>
            Result (A11y.Capabilities.Selection) := True;
         when A11ykit.Role_Table =>
            Result (A11y.Capabilities.Table) := True;
            Result (A11y.Capabilities.Selection) := True;
         when others =>
            null;
      end case;

      return Result;
   end To_Semantic_Capabilities;

   function Node_Id_For_Index
     (Tree  : A11ykit.Tree.Accessibility_Tree;
      Index : Natural)
      return A11y.Node_Ids.Node_Id is
   begin
      if Index = 0
        or else Tree.Nodes.Is_Empty
        or else Index < Tree.Nodes.First_Index
        or else Index > Tree.Nodes.Last_Index
      then
         return A11y.Node_Ids.No_Node;
      end if;

      return A11y.Node_Ids.From_Natural (Index);
   end Node_Id_For_Index;

   function Parent_Id
     (Tree  : A11ykit.Tree.Accessibility_Tree;
      Index : Natural)
      return A11y.Node_Ids.Node_Id
   is
      Node : constant A11y.Node_Ids.Node_Id :=
        Node_Id_For_Index (Tree, Index);
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         return A11y.Node_Ids.No_Node;
      end if;

      return Node_Id_For_Index (Tree, Tree.Nodes (Index).Parent);
   end Parent_Id;

   function Focused_Node
     (Tree : A11ykit.Tree.Accessibility_Tree)
      return A11y.Node_Ids.Node_Id is
     (Node_Id_For_Index (Tree, Tree.Focused));

   function Validate_Tree
     (Tree : A11ykit.Tree.Accessibility_Tree)
      return A11y.Results.Result
   is
      Root_Count : Natural := 0;
      Count : Natural := 0;

      function In_Range (Index : Natural) return Boolean is
        (Index /= 0
         and then not Tree.Nodes.Is_Empty
         and then Index >= Tree.Nodes.First_Index
         and then Index <= Tree.Nodes.Last_Index);
   begin
      if Tree.Nodes.Is_Empty then
         return (Status => A11y.Results.Invalid_State);
      end if;

      Count := Natural (Tree.Nodes.Length);

      if Tree.Focused /= 0 and then not In_Range (Tree.Focused) then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      for Index in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
         declare
            Parent : constant Natural := Tree.Nodes (Index).Parent;
         begin
            if Parent = 0 then
               Root_Count := Root_Count + 1;
            elsif Parent = Index then
               return (Status => A11y.Results.Invalid_State);
            elsif not In_Range (Parent) then
               return (Status => A11y.Results.Node_Unavailable);
            end if;

            declare
               Current : Natural := Parent;
               Depth   : Natural := 0;
            begin
               while Current /= 0 loop
                  Depth := Depth + 1;
                  if Depth > Count then
                     return (Status => A11y.Results.Invalid_State);
                  elsif not In_Range (Current) then
                     return (Status => A11y.Results.Node_Unavailable);
                  end if;
                  Current := Tree.Nodes (Current).Parent;
               end loop;
            end;
         end;
      end loop;

      if Root_Count /= 1 then
         return (Status => A11y.Results.Invalid_State);
      end if;

      return A11y.Results.Ok;
   end Validate_Tree;

   function To_Semantic_Snapshot
     (Tree   : A11ykit.Tree.Accessibility_Tree;
      Result : out A11y.Results.Result)
      return A11y.Semantic_Snapshots.Semantic_Snapshot
   is
      Snapshot : A11y.Semantic_Snapshots.Semantic_Snapshot;
      Check_Result : A11y.Results.Result := Validate_Tree (Tree);
   begin
      if A11y.Results.Failed (Check_Result) then
         Result := Check_Result;
         return Snapshot;
      end if;

      for Index in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
         declare
            Item : constant A11ykit.Tree.Node := Tree.Nodes (Index);
            Node : constant A11y.Node_Ids.Node_Id :=
              Node_Id_For_Index (Tree, Index);
         begin
            A11y.Semantic_Snapshots.Set_Node
              (Snapshot     => Snapshot,
               Node         => Node,
               Role         => To_Semantic_Role (Item.Node_Role),
              Name         => To_String (Item.Name),
              Description  => To_String (Item.Description),
              Help_Text    =>
                (Status => A11y.Properties.Unsupported,
                 Value  => Null_Unbounded_String),
              Placeholder  =>
                (Status => A11y.Properties.Unsupported,
                 Value  => Null_Unbounded_String),
              Value_Text   =>
                (Status => A11y.Properties.Unsupported,
                 Value  => Null_Unbounded_String),
              Protected_Value_Text => False,
              Bounds       =>
                A11y.Properties.Present (To_Semantic_Bounds (Item.Bounds)),
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
              States       =>
                To_Semantic_States (Item.Node_State, Item.Node_Role),
              Capabilities => To_Semantic_Capabilities (Item.Node_Role),
               Exposure     => A11y.Nodes.Expose_Node,
               Result       => Check_Result);
            if A11y.Results.Failed (Check_Result) then
               Result := Check_Result;
               return Snapshot;
            end if;
         end;
      end loop;

      Result := A11y.Results.Ok;
      return Snapshot;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Snapshot;
   end To_Semantic_Snapshot;

   procedure Populate_Session
     (Tree    : A11ykit.Tree.Accessibility_Tree;
      Session : in out A11y.Sessions.Semantic_Session;
      Result  : out A11y.Results.Result)
   is
      Snapshot : A11y.Semantic_Snapshots.Semantic_Snapshot;
      Check_Result : A11y.Results.Result;
      Needed_Events : Natural := 0;
   begin
      Snapshot := To_Semantic_Snapshot (Tree, Check_Result);
      if A11y.Results.Failed (Check_Result) then
         Result := Check_Result;
         return;
      end if;

      Needed_Events := Natural (Tree.Nodes.Length);
      Needed_Events := Needed_Events + 1;
      if Natural (Tree.Nodes.Length) > 1 then
         Needed_Events :=
           Needed_Events + ((Natural (Tree.Nodes.Length) - 1) * 2);
      end if;
      if Tree.Focused /= 0 then
         Needed_Events := Needed_Events + 1;
      end if;

      if Needed_Events >
        A11y.Sessions.Event_Capacity (Session) -
        A11y.Sessions.Pending_Event_Count (Session)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      declare
         type Node_Id_Map is array
           (Tree.Nodes.First_Index .. Tree.Nodes.Last_Index)
            of A11y.Node_Ids.Node_Id;
         type Attachment_Map is array
           (Tree.Nodes.First_Index .. Tree.Nodes.Last_Index) of Boolean;
         type Index_Path is array (Positive range <>) of Positive;
         Created : Node_Id_Map := [others => A11y.Node_Ids.No_Node];
         Attached : Attachment_Map := [others => False];
         Path : Index_Path (1 .. Natural (Tree.Nodes.Length));
         Root : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
         Root_Index : Natural := 0;
      begin
         for Index in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
            declare
               Legacy_Id : constant A11y.Node_Ids.Node_Id :=
                 Node_Id_For_Index (Tree, Index);
               Metadata : constant A11y.Semantic_Snapshots.Node_Metadata :=
                 A11y.Semantic_Snapshots.Metadata (Snapshot, Legacy_Id);
            begin
               if not Metadata.Present then
                  Result := (Status => A11y.Results.Node_Unavailable);
                  return;
               end if;

               A11y.Sessions.Create_Node_With_Capabilities
                 (Self         => Session,
                  Provider     => null,
                  Capabilities => Metadata.Capabilities,
                  Id           => Created (Index),
                  Result       => Check_Result);
               if A11y.Results.Failed (Check_Result) then
                  Result := Check_Result;
                  return;
               end if;

               if Tree.Nodes (Index).Parent = 0 then
                  Root := Created (Index);
                  Root_Index := Index;
               end if;
            end;
         end loop;

         if not A11y.Node_Ids.Is_Valid (Root) then
            Result := (Status => A11y.Results.Invalid_State);
            return;
         end if;

         A11y.Sessions.Attach_Root (Session, Root, Check_Result);
         if A11y.Results.Failed (Check_Result) then
            Result := Check_Result;
            return;
         end if;
         Attached (Root_Index) := True;

         --  Build accepts a flat list in reading order, so a geometrically
         --  inferred parent may occur after its child in that list. Attach each
         --  pending node's ancestor chain from the top down instead of assuming
         --  vector order is already topological.
         for Index in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
            if not Attached (Index) then
               declare
                  Current : Natural := Index;
                  Depth   : Natural := 0;
               begin
                  while not Attached (Current) loop
                     Depth := Depth + 1;
                     if Depth > Path'Length then
                        Result := (Status => A11y.Results.Invalid_State);
                        return;
                     end if;

                     Path (Depth) := Current;
                     Current := Tree.Nodes (Current).Parent;
                     if Current = 0 then
                        Result := (Status => A11y.Results.Invalid_State);
                        return;
                     end if;
                  end loop;

                  for Position in reverse 1 .. Depth loop
                     declare
                        Child_Index : constant Positive := Path (Position);
                        Parent_Index : constant Positive :=
                          Tree.Nodes (Child_Index).Parent;
                     begin
                        A11y.Sessions.Attach
                          (Self   => Session,
                           Parent => Created (Parent_Index),
                           Child  => Created (Child_Index),
                           Result => Check_Result);
                        if A11y.Results.Failed (Check_Result) then
                           Result := Check_Result;
                           return;
                        end if;
                        Attached (Child_Index) := True;
                     end;
                  end loop;
               end;
            end if;
         end loop;

         if Tree.Focused /= 0 then
            A11y.Sessions.Set_Focus
              (Session, Created (Tree.Focused), Check_Result);
            if A11y.Results.Failed (Check_Result) then
               Result := Check_Result;
               return;
            end if;
         end if;
      end;

      Result := A11y.Sessions.Validate_Tree (Session);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Populate_Session;

end A11ykit.Compatibility;
