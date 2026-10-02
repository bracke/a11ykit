with A11y.MacOS_Backend.NSAccessibility_Events;
with A11y.Trees.Exposure_Views;

package body A11y.MacOS_Backend.NSAccessibility_Request_Router is
   use Ada.Strings.Wide_Wide_Unbounded;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;
   use type
     A11y.MacOS_Backend.NSAccessibility_Mappings.NSAX_Relation_Attribute;

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

   function Exposed_Relation_Targets
     (Snapshots : Snapshot_Bundle;
      Targets   : A11y.Relations.Target_Vectors.Vector)
      return A11y.Relations.Target_Vectors.Vector
   is
      Result : A11y.Relations.Target_Vectors.Vector;
   begin
      for Target of Targets loop
         if Relation_Node_Externally_Exposed (Snapshots, Target) then
            Result.Append (Target);
         end if;
      end loop;

      return Result;
   exception
      when others =>
         return A11y.Relations.Target_Vectors.Empty_Vector;
   end Exposed_Relation_Targets;

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

   function Dispatch
     (Item      : Request;
      Snapshots : Snapshot_Bundle)
      return Routed_Reply
   is
   begin
      case Item.Kind is
         when Attribute_Names_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Properties
                     .Query_Attribute_Names
                       (Snapshots.Properties, Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.MacOS_Backend.NSAccessibility_Properties
                    .Attribute_Set_Reply =>
                     return
                       (Kind       => Attribute_Set,
                        Status     => Reply.Status,
                        Attributes => Reply.Attributes);
                  when A11y.MacOS_Backend.NSAccessibility_Properties
                    .Error_Reply =>
                     return Error (Reply.Status);
                  when others =>
                     return Error (A11y.Results.Internal_Error);
               end case;
            end;

         when Attribute_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
                     (Snapshots.Properties,
                      Item.Attribute,
                      Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.MacOS_Backend.NSAccessibility_Properties
                    .Attribute_Set_Reply =>
                     return Error (A11y.Results.Internal_Error);
                  when A11y.MacOS_Backend.NSAccessibility_Properties.String_Reply =>
                     return (Kind => Attribute_String,
                             Status => Reply.Status,
                             Text => Reply.Text);
                  when A11y.MacOS_Backend.NSAccessibility_Properties.Empty_String_Reply =>
                     return (Kind => Attribute_Empty_String,
                             Status => Reply.Status);
                  when A11y.MacOS_Backend.NSAccessibility_Properties.Integer_Reply =>
                     return (Kind => Attribute_Integer,
                             Status => Reply.Status,
                             Integer_Item => Reply.Integer_Item);
                  when A11y.MacOS_Backend.NSAccessibility_Properties.Boolean_Reply =>
                     return (Kind => Attribute_Boolean,
                             Status => Reply.Status,
                             Boolean_Item => Reply.Boolean_Item);
                  when A11y.MacOS_Backend.NSAccessibility_Properties.Rectangle_Reply =>
                     return (Kind => Attribute_Rectangle,
                             Status => Reply.Status,
                             Bounds => Reply.Bounds);
                  when A11y.MacOS_Backend.NSAccessibility_Properties.Role_Reply =>
                     return (Kind => Attribute_Role,
                             Status => Reply.Status,
                             Role => Reply.Role);
                  when A11y.MacOS_Backend.NSAccessibility_Properties.Not_Supported_Reply =>
                     return (Kind => Attribute_Not_Supported,
                             Status => Reply.Status);
                  when A11y.MacOS_Backend.NSAccessibility_Properties.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Attribute_Settable_Query =>
            return
              (Kind         => Attribute_Boolean,
               Status       => A11y.Results.Success,
               Boolean_Item => False);

         when Action_Set_Query =>
            if not Action_Node_Externally_Exposed (Snapshots) then
               return Error (A11y.Results.Node_Unavailable);
            end if;

            declare
               Actions : constant
                 A11y.MacOS_Backend.NSAccessibility_Actions.NSAX_Action_Set :=
                   A11y.MacOS_Backend.NSAccessibility_Actions.Action_Set
                     (Snapshots.Actions);
            begin
               return
                 (Kind => Action_Set,
                  Status => A11y.Results.Success,
                  Actions => Actions);
            end;

         when Action_Map_Query =>
            if not Action_Node_Externally_Exposed (Snapshots) then
               return Error (A11y.Results.Node_Unavailable);
            end if;

            declare
               Mapping : constant
                 A11y.MacOS_Backend.NSAccessibility_Actions.Action_Mapping :=
                   A11y.MacOS_Backend.NSAccessibility_Actions.Map_Action
                     (Snapshots.Actions,
                      Item.Action,
                      Snapshots.Action_States);
            begin
               if Mapping.Supported then
                  return
                    (Kind => Action_Mapping,
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
                 A11y.MacOS_Backend.NSAccessibility_Actions.Action_Mapping :=
                   A11y.MacOS_Backend.NSAccessibility_Actions.Map_Action
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

         when Parent_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Hierarchy.Node_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Hierarchy.Parent
                     (Snapshots.Hierarchy, Snapshots.Limits);
            begin
               if Reply.Found then
                  return
                    (Kind   => Hierarchy_Node,
                     Status => Reply.Status,
                     Node   => Reply.Node);
               elsif A11y.Results.Succeeded ((Status => Reply.Status)) then
                  return (Kind => Hierarchy_Empty, Status => Reply.Status);
               end if;

               return Error (Reply.Status);
            end;

         when Children_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Hierarchy.Children_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Hierarchy.Children
                     (Snapshots.Hierarchy, Snapshots.Limits);
            begin
               if Reply.Available then
                  return
                    (Kind     => Hierarchy_Children,
                     Status   => Reply.Status,
                     Children => Reply.Children);
               end if;

               return Error (Reply.Status);
            end;

         when Child_At_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Hierarchy.Node_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Hierarchy.Child_At
                     (Snapshots.Hierarchy,
                      Item.Child_Index,
                      Snapshots.Limits);
            begin
               if Reply.Found then
                  return
                    (Kind   => Hierarchy_Node,
                     Status => Reply.Status,
                     Node   => Reply.Node);
               end if;

               return Error (Reply.Status);
            end;

         when Element_Id_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Hierarchy.Element_Id_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Hierarchy.Build_Element_Id
                     (Snapshots.Hierarchy, Snapshots.Limits);
            begin
               if Reply.Available then
                  return
                    (Kind   => Element_Id,
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
                 A11y.MacOS_Backend.NSAccessibility_Mappings
                   .NSAX_Relation_Attribute :=
                     A11y.MacOS_Backend.NSAccessibility_Mappings
                       .Map_Relation (Item.Relation);
            begin
               if Native_Relation =
                 A11y.MacOS_Backend.NSAccessibility_Mappings
                   .Unsupported_Relation
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
                  Exposed_Targets : constant
                    A11y.Relations.Target_Vectors.Vector :=
                      Exposed_Relation_Targets (Snapshots, Targets);
                  Exposed_Count : constant Natural :=
                    Natural (Exposed_Targets.Length);
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
                    (Kind               => Relation_Targets,
                     Status             => A11y.Results.Success,
                     Relation_Attribute => Native_Relation,
                     Relation_Target_Nodes => Exposed_Targets);
               end;
            end;

         when Value_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Values.Value_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Values.Query_Value
                     (Snapshots.Value, Item.Value, Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.MacOS_Backend.NSAccessibility_Values.Float_Reply =>
                     return (Kind       => Value_Float,
                             Status     => Reply.Status,
                             Float_Item => Reply.Float_Item);
                  when A11y.MacOS_Backend.NSAccessibility_Values.Boolean_Reply =>
                     return (Kind         => Value_Boolean,
                             Status       => Reply.Status,
                             Boolean_Item => Reply.Boolean_Item);
                  when A11y.MacOS_Backend.NSAccessibility_Values.Set_Request_Reply =>
                     return
                       (Kind            => Value_Set_Request,
                        Status          => Reply.Status,
                        Requested_Value => Reply.Requested_Value);
                  when A11y.MacOS_Backend.NSAccessibility_Values.Not_Applicable_Reply =>
                     return
                       (Kind   => Value_Not_Applicable,
                        Status => Reply.Status);
                  when A11y.MacOS_Backend.NSAccessibility_Values.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Value_Set_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Values.Value_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Values.Request_Value_Set
                     (Snapshots.Value,
                      Item.Requested_Value,
                      Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.MacOS_Backend.NSAccessibility_Values.Set_Request_Reply =>
                     return
                       (Kind            => Value_Set_Request,
                        Status          => Reply.Status,
                        Requested_Value => Reply.Requested_Value);
                  when A11y.MacOS_Backend.NSAccessibility_Values.Float_Reply
                     | A11y.MacOS_Backend.NSAccessibility_Values.Boolean_Reply
                     | A11y.MacOS_Backend.NSAccessibility_Values.Not_Applicable_Reply =>
                     return Error (A11y.Results.Internal_Error);
                  when A11y.MacOS_Backend.NSAccessibility_Values.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Selection_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Selection.Selection_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Selection.Query_Selection
                     (Snapshots.Selection,
                      Item.Selection,
                      Snapshots.Limits,
                      Item.Index);
            begin
               case Reply.Kind is
                  when A11y.MacOS_Backend.NSAccessibility_Selection.UInt32_Reply =>
                     return (Kind   => Selection_UInt32,
                             Status => Reply.Status,
                             UInt32 => Reply.UInt32);
                  when A11y.MacOS_Backend.NSAccessibility_Selection.Boolean_Reply =>
                     return (Kind         => Selection_Boolean,
                             Status       => Reply.Status,
                             Boolean_Item => Reply.Boolean_Item);
                 when A11y.MacOS_Backend.NSAccessibility_Selection.Node_Reply =>
                     return (Kind   => Selection_Node,
                             Status => Reply.Status,
                             Node   => Reply.Node);
                  when A11y.MacOS_Backend.NSAccessibility_Selection.Direction_Reply =>
                     return
                       (Kind      => Selection_Direction,
                        Status    => Reply.Status,
                        Direction => Reply.Direction);
                  when A11y.MacOS_Backend.NSAccessibility_Selection.Selection_Request_Reply =>
                     return Error (A11y.Results.Internal_Error);
                  when A11y.MacOS_Backend.NSAccessibility_Selection.Nil_Reply =>
                     return (Kind => Selection_Nil, Status => Reply.Status);
                  when A11y.MacOS_Backend.NSAccessibility_Selection.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Selection_Request_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Selection.Selection_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Selection.Request_Selection
                     (Snapshots.Selection,
                      Item.Selection_Request,
                      Item.Selection_Target,
                      Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.MacOS_Backend.NSAccessibility_Selection.Selection_Request_Reply =>
                     return
                       (Kind   => Selection_Request_Reply,
                        Status => Reply.Status,
                        Selection_Target => Reply.Node,
                        Selection_Request => Reply.Request);
                  when A11y.MacOS_Backend.NSAccessibility_Selection.UInt32_Reply
                     | A11y.MacOS_Backend.NSAccessibility_Selection.Boolean_Reply
                     | A11y.MacOS_Backend.NSAccessibility_Selection.Node_Reply
                     | A11y.MacOS_Backend.NSAccessibility_Selection.Direction_Reply
                     | A11y.MacOS_Backend.NSAccessibility_Selection.Nil_Reply =>
                     return Error (A11y.Results.Internal_Error);
                  when A11y.MacOS_Backend.NSAccessibility_Selection.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Text_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Text.Text_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Text.Query_Text
                     (Snapshots.Text,
                      Item.Text,
                      Snapshots.Limits,
                      Start => Item.Index - 1,
                      Count => Item.Count);
            begin
               case Reply.Kind is
                  when A11y.MacOS_Backend.NSAccessibility_Text.UInt32_Reply =>
                     return (Kind   => Text_UInt32,
                             Status => Reply.Status,
                             UInt32 => Reply.UInt32);
                  when A11y.MacOS_Backend.NSAccessibility_Text.Wide_Text_Reply =>
                     return (Kind      => Text_Wide_Text,
                             Status    => Reply.Status,
                             Wide_Text => Reply.Wide_Text);
                  when A11y.MacOS_Backend.NSAccessibility_Text.Edit_Request_Reply =>
                     return Error (A11y.Results.Internal_Error);
                  when A11y.MacOS_Backend.NSAccessibility_Text.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Text_Edit_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Text.Text_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Text.Request_Text_Edit
                     (Snapshots.Text,
                      Item.Text_Edit,
                      Snapshots.Limits,
                      Start => Item.Index - 1,
                      Count => Item.Count,
                      Replacement => To_Wide_Wide_String (Item.Replacement));
            begin
               case Reply.Kind is
                  when A11y.MacOS_Backend.NSAccessibility_Text.Edit_Request_Reply =>
                     return
                       (Kind           => Text_Edit_Request,
                        Status         => Reply.Status,
                        Requested_Edit => Reply.Requested_Edit);
                  when A11y.MacOS_Backend.NSAccessibility_Text.Error_Reply =>
                     return Error (Reply.Status);
                  when others =>
                     return Error (A11y.Results.Internal_Error);
               end case;
            end;

         when Table_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Table.Table_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Table.Query_Table
                     (Snapshots.Table,
                      Item.Table,
                      Snapshots.Limits,
                      Item.Row,
                      Item.Column);
            begin
               case Reply.Kind is
                  when A11y.MacOS_Backend.NSAccessibility_Table.UInt32_Reply =>
                     return (Kind   => Table_UInt32,
                             Status => Reply.Status,
                             UInt32 => Reply.UInt32);
                  when A11y.MacOS_Backend.NSAccessibility_Table.Node_Reply =>
                     return (Kind   => Table_Node,
                             Status => Reply.Status,
                             Node   => Reply.Node);
                  when A11y.MacOS_Backend.NSAccessibility_Table.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Image_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Image.Image_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Image.Query_Image
                     (Snapshots.Image, Item.Image, Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.MacOS_Backend.NSAccessibility_Image.String_Reply =>
                     return (Kind   => Image_String,
                             Status => Reply.Status,
                             Text   => Reply.Text);
                  when A11y.MacOS_Backend.NSAccessibility_Image.Size_Reply =>
                     return (Kind   => Image_Size,
                             Status => Reply.Status,
                             Size   => Reply.Size);
                  when A11y.MacOS_Backend.NSAccessibility_Image.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Document_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Document.Document_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Document.Query_Document
                     (Snapshots.Document, Item.Document, Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.MacOS_Backend.NSAccessibility_Document.String_Reply =>
                     return (Kind   => Document_String,
                             Status => Reply.Status,
                             Text   => Reply.Text);
                  when A11y.MacOS_Backend.NSAccessibility_Document.UInt32_Reply =>
                     return (Kind   => Document_UInt32,
                             Status => Reply.Status,
                             UInt32 => Reply.UInt32);
                  when A11y.MacOS_Backend.NSAccessibility_Document.Boolean_Reply =>
                     return
                       (Kind         => Document_Boolean,
                        Status       => Reply.Status,
                        Boolean_Item => Reply.Boolean_Item);
                  when A11y.MacOS_Backend.NSAccessibility_Document.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Live_Region_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Live_Regions.Live_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Live_Regions
                     .Query_Live_Region
                       (Snapshots.Live_Region,
                        Item.Live_Region,
                        Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.MacOS_Backend.NSAccessibility_Live_Regions.String_Reply =>
                     return (Kind   => Live_String,
                             Status => Reply.Status,
                             Text   => Reply.Text);
                  when A11y.MacOS_Backend.NSAccessibility_Live_Regions.Boolean_Reply =>
                     return (Kind         => Live_Boolean,
                             Status       => Reply.Status,
                             Boolean_Item => Reply.Boolean_Item);
                  when A11y.MacOS_Backend.NSAccessibility_Live_Regions.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Surface_Query =>
            declare
               Reply : constant
                 A11y.MacOS_Backend.NSAccessibility_Surfaces.Surface_Reply :=
                   A11y.MacOS_Backend.NSAccessibility_Surfaces.Query_Surface
                     (Snapshots.Surface, Item.Surface, Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.MacOS_Backend.NSAccessibility_Surfaces.String_Reply =>
                     return (Kind   => Surface_String,
                             Status => Reply.Status,
                             Text   => Reply.Text);
                  when A11y.MacOS_Backend.NSAccessibility_Surfaces.Boolean_Reply =>
                     return (Kind         => Surface_Boolean,
                             Status       => Reply.Status,
                             Boolean_Item => Reply.Boolean_Item);
                  when A11y.MacOS_Backend.NSAccessibility_Surfaces.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when Notification_Query =>
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
                 A11y.MacOS_Backend.NSAccessibility_Events.NSAX_Event_Emission :=
                   (if Item.Use_Prepared_Event then
                      A11y.MacOS_Backend.NSAccessibility_Events
                        .Build_Prepared_Event (Item.Prepared_Event)
                    else
                      A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
                        (Item.Event));
               Posting_Result : A11y.Results.Result;
            begin
               if Item.Use_Prepared_Event then
                  Posting_Result :=
                    A11y.MacOS_Backend.NSAccessibility_Events
                      .Validate_For_Posting (Reply);
                  if A11y.Results.Failed (Posting_Result) then
                     return Error (Posting_Result.Status);
                  end if;
               end if;

               if Reply.Publishable then
                  return
                    (Kind          => Notification,
                     Status        => Reply.Status,
                     Native_Object => Reply.Native_Object);
               end if;

               return Error (Reply.Status);
            end;
      end case;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Dispatch;

end A11y.MacOS_Backend.NSAccessibility_Request_Router;
