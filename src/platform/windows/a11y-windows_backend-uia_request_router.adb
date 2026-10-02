with A11y.Windows_Backend.UIA_Events;
with A11y.Trees.Exposure_Views;

package body A11y.Windows_Backend.UIA_Request_Router is
   use Ada.Strings.Wide_Wide_Unbounded;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;
   use type A11y.Results.Status_Code;
   use type A11y.Windows_Backend.UIA_Values.Reply_Kind;
   use type A11y.Windows_Backend.UIA_Mappings.UIA_Relation_Property;

   function Error (Status : A11y.Results.Status_Code) return Routed_Reply is
     (Kind   => Routed_Error,
      Status => Status);

   function Action_Exposure_Of
     (Snapshots : Snapshot_Bundle;
      Node      : A11y.Node_Ids.Node_Id)
      return A11y.Nodes.Exposure_Policy
   is
      Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
   begin
      if Slot not in Snapshots.Action_Exposure'Range then
         return A11y.Nodes.Hide_Node_And_Subtree;
      end if;

      return Snapshots.Action_Exposure (Slot);
   end Action_Exposure_Of;

   function Action_Node_Externally_Exposed
     (Snapshots : Snapshot_Bundle)
      return Boolean
   is
      function Policy_For
        (Current : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy is
        (Action_Exposure_Of (Snapshots, Current));

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Policy_For);

      Parent : A11y.Node_Ids.Node_Id;
      Result : A11y.Results.Result;
   begin
      if not Snapshots.Action_Use_Tree_Projection then
         return True;
      elsif not A11y.Node_Ids.Is_Valid (Snapshots.Action_Node)
        or else not A11y.Node_Ids.Is_Valid (Snapshots.Action_Root)
      then
         return False;
      elsif Snapshots.Action_Node = Snapshots.Action_Root then
         return Action_Exposure_Of (Snapshots, Snapshots.Action_Node)
           = A11y.Nodes.Expose_Node;
      end if;

      Parent := Exposure_View.Exposed_Parent_Of
        (Snapshots.Action_Tree,
         Snapshots.Action_Node,
         Snapshots.Limits,
         Result);
      return A11y.Results.Succeeded (Result)
        and then A11y.Node_Ids.Is_Valid (Parent);
   exception
      when others =>
         return False;
   end Action_Node_Externally_Exposed;

   function Relation_Exposure_Of
     (Snapshots : Snapshot_Bundle;
      Node      : A11y.Node_Ids.Node_Id)
      return A11y.Nodes.Exposure_Policy
   is
      Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
   begin
      if Slot not in Snapshots.Relation_Exposure'Range then
         return A11y.Nodes.Hide_Node_And_Subtree;
      end if;

      return Snapshots.Relation_Exposure (Slot);
   end Relation_Exposure_Of;

   function Relation_Node_Externally_Exposed
     (Snapshots : Snapshot_Bundle;
      Node      : A11y.Node_Ids.Node_Id)
      return Boolean
   is
      function Policy_For
        (Current : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy is
        (Relation_Exposure_Of (Snapshots, Current));

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Policy_For);
   begin
      if not Snapshots.Relation_Use_Tree_Projection then
         return True;
      elsif not A11y.Node_Ids.Is_Valid (Snapshots.Relation_Root)
        or else not A11y.Node_Ids.Is_Valid (Node)
      then
         return False;
      end if;

      return Exposure_View.Is_Externally_Exposed
        (Snapshots.Relation_Tree, Node, Snapshots.Limits);
   exception
      when others =>
         return False;
   end Relation_Node_Externally_Exposed;

   function Exposed_Relation_Target_Count
     (Snapshots : Snapshot_Bundle;
      Targets   : A11y.Relations.Target_Vectors.Vector)
      return Natural
   is
      Count : Natural := 0;
   begin
      for Target of Targets loop
         if Relation_Node_Externally_Exposed (Snapshots, Target) then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Exposed_Relation_Target_Count;

   function Event_Exposure_Of
     (Snapshots : Snapshot_Bundle;
      Node      : A11y.Node_Ids.Node_Id)
      return A11y.Nodes.Exposure_Policy
   is
      Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
   begin
      if Slot not in Snapshots.Event_Exposure'Range then
         return A11y.Nodes.Hide_Node_And_Subtree;
      end if;

      return Snapshots.Event_Exposure (Slot);
   end Event_Exposure_Of;

   function Event_Source_Externally_Exposed
     (Snapshots : Snapshot_Bundle;
      Source    : A11y.Node_Ids.Node_Id)
      return Boolean
   is
      function Policy_For
        (Current : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy is
        (Event_Exposure_Of (Snapshots, Current));

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Policy_For);
   begin
      if not Snapshots.Event_Use_Tree_Projection then
         return True;
      elsif not A11y.Node_Ids.Is_Valid (Snapshots.Event_Root)
        or else not A11y.Node_Ids.Is_Valid (Source)
      then
         return False;
      end if;

      return Exposure_View.Is_Externally_Exposed
        (Snapshots.Event_Tree, Source, Snapshots.Limits);
   exception
      when others =>
         return False;
   end Event_Source_Externally_Exposed;

   function Value_Patterns
     (Snapshots : Snapshot_Bundle)
      return A11y.Windows_Backend.UIA_Actions.UIA_Pattern_Set
   is
      Result : A11y.Windows_Backend.UIA_Actions.UIA_Pattern_Set :=
        A11y.Windows_Backend.UIA_Actions.Empty_UIA_Pattern_Set;
      Current : constant A11y.Windows_Backend.UIA_Values.Value_Reply :=
        A11y.Windows_Backend.UIA_Values.Query_Value
          (Snapshots.Value,
           A11y.Windows_Backend.UIA_Values.Current_Value,
           Snapshots.Limits);
      Minimum : A11y.Windows_Backend.UIA_Values.Value_Reply;
      Maximum : A11y.Windows_Backend.UIA_Values.Value_Reply;
   begin
      if Current.Kind /= A11y.Windows_Backend.UIA_Values.Float_Reply
        or else Current.Status /= A11y.Results.Success
      then
         return Result;
      end if;

      Result (A11y.Windows_Backend.UIA_Actions.Value) := True;

      Minimum :=
        A11y.Windows_Backend.UIA_Values.Query_Value
          (Snapshots.Value,
           A11y.Windows_Backend.UIA_Values.Minimum_Value,
           Snapshots.Limits);
      Maximum :=
        A11y.Windows_Backend.UIA_Values.Query_Value
          (Snapshots.Value,
           A11y.Windows_Backend.UIA_Values.Maximum_Value,
           Snapshots.Limits);

      if Minimum.Kind = A11y.Windows_Backend.UIA_Values.Float_Reply
        and then Minimum.Status = A11y.Results.Success
        and then Maximum.Kind = A11y.Windows_Backend.UIA_Values.Float_Reply
        and then Maximum.Status = A11y.Results.Success
      then
         Result (A11y.Windows_Backend.UIA_Actions.Range_Value) := True;
      end if;

      return Result;
   exception
      when others =>
         return A11y.Windows_Backend.UIA_Actions.Empty_UIA_Pattern_Set;
   end Value_Patterns;

   function Pattern_Set_For
     (Snapshots : Snapshot_Bundle)
      return A11y.Windows_Backend.UIA_Actions.UIA_Pattern_Set
   is
      Result : A11y.Windows_Backend.UIA_Actions.UIA_Pattern_Set :=
        A11y.Windows_Backend.UIA_Actions.Pattern_Set (Snapshots.Actions);
      Value_Result : constant A11y.Windows_Backend.UIA_Actions.UIA_Pattern_Set :=
        Value_Patterns (Snapshots);
   begin
      for Pattern in Result'Range loop
         Result (Pattern) := Result (Pattern) or else Value_Result (Pattern);
      end loop;

      return Result;
   exception
      when others =>
         return A11y.Windows_Backend.UIA_Actions.Empty_UIA_Pattern_Set;
   end Pattern_Set_For;

   function Dispatch
     (Item      : Request;
      Snapshots : Snapshot_Bundle)
      return Routed_Reply
   is
   begin
      case Item.Kind is
         when Provider_Options_Query =>
            return
              (Kind    => Provider_Options,
               Status  => A11y.Results.Success,
               Options => 1);

         when Host_Raw_Element_Provider_Query =>
            return
              (Kind   => Host_Raw_Element_Provider_Empty,
               Status => A11y.Results.Success);

         when Property_Query =>
            declare
               Reply : constant
                 A11y.Windows_Backend.UIA_Properties.Property_Reply :=
                   A11y.Windows_Backend.UIA_Properties.Query_Property
                     (Snapshots.Properties,
                      Item.Property,
                      Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Windows_Backend.UIA_Properties.String_Reply =>
                     return (Kind => Property_String,
                             Status => Reply.Status,
                             Text => Reply.Text);
                  when A11y.Windows_Backend.UIA_Properties.Empty_String_Reply =>
                     return (Kind => Property_Empty_String,
                             Status => Reply.Status);
                  when A11y.Windows_Backend.UIA_Properties.Integer_Reply =>
                     return (Kind => Property_Integer,
                             Status => Reply.Status,
                             Integer_Item => Reply.Integer_Item);
                  when A11y.Windows_Backend.UIA_Properties.Boolean_Reply =>
                     return (Kind => Property_Boolean,
                             Status => Reply.Status,
                             Boolean_Item => Reply.Boolean_Item);
                  when A11y.Windows_Backend.UIA_Properties.Rectangle_Reply =>
                     return (Kind => Property_Rectangle,
                             Status => Reply.Status,
                             Bounds => Reply.Bounds);
                  when A11y.Windows_Backend.UIA_Properties.Control_Type_Reply =>
                     return (Kind => Property_Control_Type,
                             Status => Reply.Status,
                             Control_Type => Reply.Control_Type);
                  when A11y.Windows_Backend.UIA_Properties.Not_Supported_Reply =>
                     return (Kind => Property_Not_Supported,
                             Status => Reply.Status);
                  when A11y.Windows_Backend.UIA_Properties.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Pattern_Query =>
            if not Action_Node_Externally_Exposed (Snapshots) then
               return Error (A11y.Results.Node_Unavailable);
            end if;

            declare
               Patterns : constant
                 A11y.Windows_Backend.UIA_Actions.UIA_Pattern_Set :=
                   Pattern_Set_For (Snapshots);
            begin
               return
                 (Kind   => Pattern_Set,
                  Status => A11y.Results.Success,
                  Patterns => Patterns);
            end;

         when Action_Map_Query =>
            if not Action_Node_Externally_Exposed (Snapshots) then
               return Error (A11y.Results.Node_Unavailable);
            end if;

            declare
               Mapping : constant
                 A11y.Windows_Backend.UIA_Actions.Action_Mapping :=
                   A11y.Windows_Backend.UIA_Actions.Map_Action
                     (Snapshots.Actions,
                      Item.Action,
                      Snapshots.Action_States);
            begin
               if Mapping.Supported then
                  return
                    (Kind   => Action_Mapping,
                     Status => Mapping.Status,
                     Mapping => Mapping);
               end if;

               return Error (Mapping.Status);
            end;

         when Action_Request_Query =>
            if not Action_Node_Externally_Exposed (Snapshots) then
               return Error (A11y.Results.Node_Unavailable);
            end if;

            declare
               Mapping : constant
                 A11y.Windows_Backend.UIA_Actions.Action_Mapping :=
                   A11y.Windows_Backend.UIA_Actions.Map_Action
                     (Snapshots.Actions,
                      Item.Action,
                      Snapshots.Action_States);
            begin
               if Mapping.Supported then
                  return
                    (Kind             => Action_Request,
                     Status           => Mapping.Status,
                     Requested_Action => Item.Action);
               end if;

               return Error (Mapping.Status);
            end;

         when Fragment_Navigation_Query =>
            declare
               Reply : constant
                 A11y.Windows_Backend.UIA_Fragments.Fragment_Reply :=
                   A11y.Windows_Backend.UIA_Fragments.Navigate
                     (Snapshots.Fragment, Item.Direction, Snapshots.Limits);
            begin
               if Reply.Found then
                  return
                    (Kind   => Fragment_Node,
                     Status => Reply.Status,
                     Node   => Reply.Node);
               elsif A11y.Results.Succeeded ((Status => Reply.Status)) then
                  return
                    (Kind   => Fragment_Empty,
                     Status => Reply.Status);
               end if;

               return Error (Reply.Status);
            end;

         when Embedded_Fragment_Roots_Query =>
            return
              (Kind   => Embedded_Fragment_Roots_Empty,
               Status => A11y.Results.Success);

         when Fragment_Root_Query =>
            declare
               Reply : constant
                 A11y.Windows_Backend.UIA_Fragments.Fragment_Reply :=
                   A11y.Windows_Backend.UIA_Fragments.Fragment_Root
                     (Snapshots.Fragment, Snapshots.Limits);
            begin
               if Reply.Found then
                  return
                    (Kind   => Fragment_Node,
                     Status => Reply.Status,
                     Node   => Reply.Node);
               elsif A11y.Results.Succeeded ((Status => Reply.Status)) then
                  return
                    (Kind   => Fragment_Empty,
                     Status => Reply.Status);
               end if;

               return Error (Reply.Status);
            end;

         when Fragment_Root_Focus_Query =>
            declare
               Reply : constant
                 A11y.Windows_Backend.UIA_Fragments.Fragment_Reply :=
                   A11y.Windows_Backend.UIA_Fragments.Focused_Node
                     (Snapshots.Fragment, Snapshots.Limits);
            begin
               if Reply.Found then
                  return
                    (Kind   => Fragment_Node,
                     Status => Reply.Status,
                     Node   => Reply.Node);
               elsif A11y.Results.Succeeded ((Status => Reply.Status)) then
                  return
                    (Kind   => Fragment_Empty,
                     Status => Reply.Status);
               end if;

               return Error (Reply.Status);
            end;

         when Fragment_Root_Point_Query =>
            declare
               Reply : constant
                 A11y.Windows_Backend.UIA_Fragments.Fragment_Reply :=
                   A11y.Windows_Backend.UIA_Fragments.Node_From_Point
                     (Snapshots.Fragment, Snapshots.Limits);
            begin
               if Reply.Found then
                  return
                    (Kind   => Fragment_Node,
                     Status => Reply.Status,
                     Node   => Reply.Node);
               elsif A11y.Results.Succeeded ((Status => Reply.Status)) then
                  return
                    (Kind   => Fragment_Empty,
                     Status => Reply.Status);
               end if;

               return Error (Reply.Status);
            end;

         when Runtime_Id_Query =>
            declare
               Reply : constant
                 A11y.Windows_Backend.UIA_Fragments.Runtime_Id_Reply :=
                   A11y.Windows_Backend.UIA_Fragments.Build_Runtime_Id
                     (Snapshots.Fragment, Snapshots.Limits);
            begin
               if Reply.Available then
                  return
                    (Kind   => Runtime_Id,
                     Status => Reply.Status,
                     Id     => Reply.Id);
               end if;

               return Error (Reply.Status);
            end;

         when Relation_Query =>
            declare
               Limit_Result : constant A11y.Results.Result :=
                 A11y.Resource_Limits.Validate (Snapshots.Limits);
            begin
               if A11y.Results.Failed (Limit_Result) then
                  return Error (Limit_Result.Status);
               end if;
            end;

            if not Relation_Node_Externally_Exposed
              (Snapshots, Snapshots.Relation_Source)
            then
               return Error (A11y.Results.Node_Unavailable);
            end if;

            declare
               Native_Relation : constant
                 A11y.Windows_Backend.UIA_Mappings.UIA_Relation_Property :=
                   A11y.Windows_Backend.UIA_Mappings.Map_Relation
                     (Item.Relation);
            begin
               if Native_Relation =
                 A11y.Windows_Backend.UIA_Mappings.Unsupported_Relation
               then
                  return
                    (Kind   => Relation_Not_Supported,
                     Status => A11y.Results.Unsupported_Capability);
               end if;

               declare
                  Targets : constant A11y.Relations.Target_Vectors.Vector :=
                    A11y.Relations.Targets
                      (Snapshots.Relations,
                       Snapshots.Relation_Source,
                       Item.Relation);
                  Exposed_Count : constant Natural :=
                    Exposed_Relation_Target_Count (Snapshots, Targets);
               begin
                  if A11y.Resource_Limits.Exceeded
                    (Snapshots.Limits,
                     A11y.Resource_Limits.Relation_Targets_Returned,
                     Exposed_Count)
                  then
                     return Error (A11y.Results.Resource_Limit);
                  elsif Exposed_Count = 0 then
                     return
                       (Kind   => Relation_Empty,
                        Status => A11y.Results.Success);
                  end if;

                  return
                    (Kind              => Relation_Targets,
                     Status            => A11y.Results.Success,
                     Relation_Property => Native_Relation);
               end;
            end;

         when Value_Query =>
            declare
               Reply : constant A11y.Windows_Backend.UIA_Values.Value_Reply :=
                 A11y.Windows_Backend.UIA_Values.Query_Value
                   (Snapshots.Value, Item.Value, Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Windows_Backend.UIA_Values.Float_Reply =>
                     return
                       (Kind       => Value_Float,
                        Status     => Reply.Status,
                        Float_Item => Reply.Float_Item);
                  when A11y.Windows_Backend.UIA_Values.Boolean_Reply =>
                     return
                       (Kind         => Value_Boolean,
                        Status       => Reply.Status,
                        Boolean_Item => Reply.Boolean_Item);
                  when A11y.Windows_Backend.UIA_Values.Set_Request_Reply =>
                     return
                       (Kind            => Value_Set_Request,
                        Status          => Reply.Status,
                        Requested_Value => Reply.Requested_Value);
                  when A11y.Windows_Backend.UIA_Values.Not_Supported_Reply =>
                     return
                       (Kind   => Value_Not_Supported,
                        Status => Reply.Status);
                  when A11y.Windows_Backend.UIA_Values.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Value_Set_Query =>
            declare
               Reply : constant A11y.Windows_Backend.UIA_Values.Value_Reply :=
                 A11y.Windows_Backend.UIA_Values.Request_Value_Set
                   (Snapshots.Value, Item.Requested_Value, Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Windows_Backend.UIA_Values.Set_Request_Reply =>
                     return
                       (Kind            => Value_Set_Request,
                        Status          => Reply.Status,
                        Requested_Value => Reply.Requested_Value);
                  when A11y.Windows_Backend.UIA_Values.Float_Reply
                     | A11y.Windows_Backend.UIA_Values.Boolean_Reply
                     | A11y.Windows_Backend.UIA_Values.Not_Supported_Reply =>
                     return Error (A11y.Results.Internal_Error);
                  when A11y.Windows_Backend.UIA_Values.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Selection_Query =>
            declare
               Reply : constant
                 A11y.Windows_Backend.UIA_Selection.Selection_Reply :=
                   A11y.Windows_Backend.UIA_Selection.Query_Selection
                     (Snapshots.Selection,
                      Item.Selection,
                      Snapshots.Limits,
                      Item.Index);
            begin
               case Reply.Kind is
                  when A11y.Windows_Backend.UIA_Selection.UInt32_Reply =>
                     return
                       (Kind   => Selection_UInt32,
                        Status => Reply.Status,
                        UInt32 => Reply.UInt32);
                  when A11y.Windows_Backend.UIA_Selection.Boolean_Reply =>
                     return
                       (Kind         => Selection_Boolean,
                        Status       => Reply.Status,
                        Boolean_Item => Reply.Boolean_Item);
                 when A11y.Windows_Backend.UIA_Selection.Node_Reply =>
                     return
                       (Kind   => Selection_Node,
                        Status => Reply.Status,
                        Node   => Reply.Node);
                  when A11y.Windows_Backend.UIA_Selection.Direction_Reply =>
                     return
                       (Kind      => Selection_Direction,
                        Status    => Reply.Status,
                        Direction => Reply.Direction);
                  when A11y.Windows_Backend.UIA_Selection.Selection_Request_Reply =>
                     return Error (A11y.Results.Internal_Error);
                  when A11y.Windows_Backend.UIA_Selection.Empty_Reply =>
                     return
                       (Kind   => Selection_Empty,
                        Status => Reply.Status);
                  when A11y.Windows_Backend.UIA_Selection.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Selection_Request_Query =>
            declare
               Reply : constant
                 A11y.Windows_Backend.UIA_Selection.Selection_Reply :=
                   A11y.Windows_Backend.UIA_Selection.Request_Selection
                     (Snapshots.Selection,
                      Item.Selection_Request,
                      Item.Selection_Target,
                      Snapshots.Limits);
            begin
               case Reply.Kind is
                 when A11y.Windows_Backend.UIA_Selection.Selection_Request_Reply =>
                     return
                       (Kind   => Selection_Request_Reply,
                        Status => Reply.Status,
                        Selection_Target => Reply.Node,
                        Selection_Request => Reply.Request);
                  when A11y.Windows_Backend.UIA_Selection.UInt32_Reply
                     | A11y.Windows_Backend.UIA_Selection.Boolean_Reply
                     | A11y.Windows_Backend.UIA_Selection.Node_Reply
                     | A11y.Windows_Backend.UIA_Selection.Direction_Reply
                     | A11y.Windows_Backend.UIA_Selection.Empty_Reply =>
                     return Error (A11y.Results.Internal_Error);
                  when A11y.Windows_Backend.UIA_Selection.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Text_Query =>
            declare
               Reply : constant A11y.Windows_Backend.UIA_Text.Text_Reply :=
                 A11y.Windows_Backend.UIA_Text.Query_Text
                   (Snapshots.Text,
                    Item.Text,
                    Snapshots.Limits,
                    Start => Item.Index - 1,
                    Count => Item.Count);
            begin
               case Reply.Kind is
                  when A11y.Windows_Backend.UIA_Text.UInt32_Reply =>
                     return (Kind   => Text_UInt32,
                             Status => Reply.Status,
                             UInt32 => Reply.UInt32);
                  when A11y.Windows_Backend.UIA_Text.Wide_Text_Reply =>
                     return (Kind      => Text_Wide_Text,
                             Status    => Reply.Status,
                             Wide_Text => Reply.Wide_Text);
                  when A11y.Windows_Backend.UIA_Text.Edit_Request_Reply =>
                     return Error (A11y.Results.Internal_Error);
                  when A11y.Windows_Backend.UIA_Text.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Text_Edit_Query =>
            declare
               Reply : constant A11y.Windows_Backend.UIA_Text.Text_Reply :=
                 A11y.Windows_Backend.UIA_Text.Request_Text_Edit
                   (Snapshots.Text,
                    Item.Text_Edit,
                    Snapshots.Limits,
                    Start => Item.Index - 1,
                    Count => Item.Count,
                    Replacement => To_Wide_Wide_String (Item.Replacement));
            begin
               case Reply.Kind is
                  when A11y.Windows_Backend.UIA_Text.Edit_Request_Reply =>
                     return
                       (Kind           => Text_Edit_Request,
                        Status         => Reply.Status,
                        Requested_Edit => Reply.Requested_Edit);
                  when A11y.Windows_Backend.UIA_Text.Error_Reply =>
                     return Error (Reply.Status);
                  when others =>
                     return Error (A11y.Results.Internal_Error);
               end case;
            end;

         when Table_Query =>
            declare
               Reply : constant A11y.Windows_Backend.UIA_Table.Table_Reply :=
                 A11y.Windows_Backend.UIA_Table.Query_Table
                   (Snapshots.Table,
                    Item.Table,
                    Snapshots.Limits,
                    Item.Row,
                    Item.Column);
            begin
               case Reply.Kind is
                  when A11y.Windows_Backend.UIA_Table.UInt32_Reply =>
                     return (Kind   => Table_UInt32,
                             Status => Reply.Status,
                             UInt32 => Reply.UInt32);
                  when A11y.Windows_Backend.UIA_Table.Node_Reply =>
                     return (Kind   => Table_Node,
                             Status => Reply.Status,
                             Node   => Reply.Node);
                  when A11y.Windows_Backend.UIA_Table.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Image_Query =>
            declare
               Reply : constant A11y.Windows_Backend.UIA_Image.Image_Reply :=
                 A11y.Windows_Backend.UIA_Image.Query_Image
                   (Snapshots.Image, Item.Image, Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Windows_Backend.UIA_Image.String_Reply =>
                     return (Kind   => Image_String,
                             Status => Reply.Status,
                             Text   => Reply.Text);
                  when A11y.Windows_Backend.UIA_Image.Size_Reply =>
                     return (Kind   => Image_Size,
                             Status => Reply.Status,
                             Size   => Reply.Size);
                  when A11y.Windows_Backend.UIA_Image.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Document_Query =>
            declare
               Reply : constant
                 A11y.Windows_Backend.UIA_Document.Document_Reply :=
                   A11y.Windows_Backend.UIA_Document.Query_Document
                     (Snapshots.Document, Item.Document, Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Windows_Backend.UIA_Document.String_Reply =>
                     return (Kind   => Document_String,
                             Status => Reply.Status,
                             Text   => Reply.Text);
                  when A11y.Windows_Backend.UIA_Document.UInt32_Reply =>
                     return (Kind   => Document_UInt32,
                             Status => Reply.Status,
                             UInt32 => Reply.UInt32);
                  when A11y.Windows_Backend.UIA_Document.Boolean_Reply =>
                     return (Kind         => Document_Boolean,
                             Status       => Reply.Status,
                             Boolean_Item => Reply.Boolean_Item);
                  when A11y.Windows_Backend.UIA_Document.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Live_Region_Query =>
            declare
               Reply : constant
                 A11y.Windows_Backend.UIA_Live_Regions.Live_Reply :=
                   A11y.Windows_Backend.UIA_Live_Regions.Query_Live_Region
                     (Snapshots.Live_Region,
                      Item.Live_Region,
                      Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Windows_Backend.UIA_Live_Regions.String_Reply =>
                     return (Kind   => Live_String,
                             Status => Reply.Status,
                             Text   => Reply.Text);
                  when A11y.Windows_Backend.UIA_Live_Regions.Boolean_Reply =>
                     return (Kind         => Live_Boolean,
                             Status       => Reply.Status,
                             Boolean_Item => Reply.Boolean_Item);
                  when A11y.Windows_Backend.UIA_Live_Regions.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Surface_Query =>
            declare
               Reply : constant
                 A11y.Windows_Backend.UIA_Surfaces.Surface_Reply :=
                   A11y.Windows_Backend.UIA_Surfaces.Query_Surface
                     (Snapshots.Surface, Item.Surface, Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Windows_Backend.UIA_Surfaces.String_Reply =>
                     return (Kind   => Surface_String,
                             Status => Reply.Status,
                             Text   => Reply.Text);
                  when A11y.Windows_Backend.UIA_Surfaces.Boolean_Reply =>
                     return (Kind         => Surface_Boolean,
                             Status       => Reply.Status,
                             Boolean_Item => Reply.Boolean_Item);
                  when A11y.Windows_Backend.UIA_Surfaces.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Event_Advise_Query | Event_Unadvise_Query =>
            return
              (Kind   => Event_Subscription_Acknowledged,
               Status => A11y.Results.Success);

         when Event_Emission_Query =>
            if not Event_Source_Externally_Exposed
              (Snapshots,
               (if Item.Use_Prepared_Event then
                  Item.Prepared_Event.Event.Source
                else
                  Item.Event.Source))
            then
               return Error (A11y.Results.Node_Unavailable);
            end if;

            declare
               Reply : constant
                 A11y.Windows_Backend.UIA_Events.UIA_Event_Emission :=
                   (if Item.Use_Prepared_Event then
                      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event
                        (Item.Prepared_Event)
                    else
                      A11y.Windows_Backend.UIA_Events.Build_Event
                        (Item.Event));
               Posting_Result : A11y.Results.Result;
            begin
               if Item.Use_Prepared_Event then
                  Posting_Result :=
                    A11y.Windows_Backend.UIA_Events.Validate_For_Posting
                      (Reply);
                  if A11y.Results.Failed (Posting_Result) then
                     return Error (Posting_Result.Status);
                  end if;
               end if;

               if Reply.Publishable then
                  return
                    (Kind   => Event_Emission,
                     Status => Reply.Status,
                     Native_Object => Reply.Native_Object);
               end if;

               return Error (Reply.Status);
            end;
      end case;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Dispatch;

end A11y.Windows_Backend.UIA_Request_Router;
