with Ada.Strings.Unbounded;
with Ada.Strings.Wide_Wide_Unbounded;

package body A11y.Linux.ATSPi_Method_Router is
   use Ada.Strings.Unbounded;
   use Ada.Strings.Wide_Wide_Unbounded;
   use type A11y.Linux.ATSPi_Objects.ATSPI_Interface;

   function Error (Status : A11y.Results.Status_Code) return Routed_Reply is
     (Kind   => Routed_Error,
      Status => Status,
      others => <>);

   function Widen (Text : String) return Wide_Wide_String is
      Result : Wide_Wide_String (Text'Range);
   begin
      for Index in Text'Range loop
         Result (Index) := Wide_Wide_Character'Val
           (Character'Pos (Text (Index)));
      end loop;
      return Result;
   end Widen;

   procedure Append_UTF8
     (Output : in out Unbounded_String;
      Code   : Natural)
   is
      procedure Byte (Value : Natural) is
      begin
         Append (Output, Character'Val (Value));
      end Byte;
   begin
      if Code <= 16#7F# then
         Byte (Code);
      elsif Code <= 16#7FF# then
         Byte (16#C0# + (Code / 2 ** 6));
         Byte (16#80# + (Code mod 2 ** 6));
      elsif Code <= 16#FFFF# then
         Byte (16#E0# + (Code / 2 ** 12));
         Byte (16#80# + ((Code / 2 ** 6) mod 2 ** 6));
         Byte (16#80# + (Code mod 2 ** 6));
      else
         Byte (16#F0# + (Code / 2 ** 18));
         Byte (16#80# + ((Code / 2 ** 12) mod 2 ** 6));
         Byte (16#80# + ((Code / 2 ** 6) mod 2 ** 6));
         Byte (16#80# + (Code mod 2 ** 6));
      end if;
   end Append_UTF8;

   function Encode_UTF8
     (Text   : Wide_Wide_String;
      Result : out A11y.Results.Result)
      return Unbounded_String
   is
      Encoded : Unbounded_String;
      Code    : Natural;
   begin
      for Character_Item of Text loop
         Code := Wide_Wide_Character'Pos (Character_Item);
         if Code in 16#D800# .. 16#DFFF# or else Code > 16#10FFFF# then
            Result := (Status => A11y.Results.Invalid_Argument);
            return Null_Unbounded_String;
         end if;

         Append_UTF8 (Encoded, Code);
      end loop;

      Result := A11y.Results.Ok;
      return Encoded;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Null_Unbounded_String;
   end Encode_UTF8;

   function Dispatch
     (Request   : Method_Request;
      Snapshots : Snapshot_Bundle)
      return Routed_Reply
   is
      Path   : constant String := To_String (Request.Path);
      Method : constant String := To_String (Request.Method);
   begin
      case Request.Requested_Interface is
         when A11y.Linux.ATSPi_Objects.Application =>
            declare
               Reply : constant
                 A11y.Linux.ATSPi_Application.Application_Reply :=
                   A11y.Linux.ATSPi_Application.Handle_Method
                     (Request.Session,
                      Path,
                      Method,
                      Snapshots.Application,
                      Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Linux.ATSPi_Application.String_Reply =>
                     return (Kind => Application_String,
                             Status => Reply.Status,
                             Text => Reply.Text,
                             others => <>);
                  when A11y.Linux.ATSPi_Application.UInt32_Reply =>
                     return (Kind => Application_UInt32,
                             Status => Reply.Status,
                             UInt32 => Reply.UInt32,
                             others => <>);
                  when A11y.Linux.ATSPi_Application.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when A11y.Linux.ATSPi_Objects.Accessible =>
            declare
               Reply : constant
                 A11y.Linux.ATSPi_Accessible.Accessible_Reply :=
                   A11y.Linux.ATSPi_Accessible.Handle_Method
                     (Request.Session,
                      Path,
                      Method,
                      Request.Index,
                      Snapshots.Accessible,
                      Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Linux.ATSPi_Accessible.Role_Reply =>
                     return (Kind => Accessible_Role,
                             Status => Reply.Status,
                             UInt32 => A11y.Linux.ATSPi_Mappings.ATSPI_Role'Pos
                               (Reply.Role),
                             others => <>);
                  when A11y.Linux.ATSPi_Accessible.State_Set_Reply =>
                     return (Kind => Accessible_State_Set,
                             Status => Reply.Status,
                             State_Set => Reply.States,
                             others => <>);
                  when A11y.Linux.ATSPi_Accessible.String_Reply =>
                     return (Kind => Accessible_String,
                             Status => Reply.Status,
                             Text => Reply.Text,
                             others => <>);
                  when A11y.Linux.ATSPi_Accessible.UInt32_Reply =>
                     return (Kind => Accessible_UInt32,
                             Status => Reply.Status,
                             UInt32 => Reply.UInt32,
                             others => <>);
                  when A11y.Linux.ATSPi_Accessible.Int32_Reply =>
                     return (Kind => Accessible_Int32,
                             Status => Reply.Status,
                             Int32 => Reply.Int32,
                             others => <>);
                  when A11y.Linux.ATSPi_Accessible.Node_Reply =>
                     return (Kind => Accessible_Node,
                             Status => Reply.Status,
                             Node => Reply.Node,
                             others => <>);
                  when A11y.Linux.ATSPi_Accessible.Node_Array_Reply =>
                     return (Kind => Accessible_Node_Array,
                             Status => Reply.Status,
                             Nodes => Reply.Nodes,
                             others => <>);
                  when A11y.Linux.ATSPi_Accessible.String_Array_Reply =>
                     return (Kind => Accessible_String_Array,
                             Status => Reply.Status,
                             Strings => Reply.Strings,
                             others => <>);
                  when A11y.Linux.ATSPi_Accessible.Attribute_Set_Reply =>
                     return (Kind => Accessible_Attribute_Set,
                             Status => Reply.Status,
                             Attributes => Reply.Attributes,
                             others => <>);
                  when A11y.Linux.ATSPi_Accessible.Relation_Set_Reply =>
                     return (Kind => Accessible_Relation_Set,
                             Status => Reply.Status,
                             Relations => Reply.Relations,
                             others => <>);
                  when A11y.Linux.ATSPi_Accessible.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when A11y.Linux.ATSPi_Objects.Component =>
            declare
               Reply : constant A11y.Linux.ATSPi_Component.Component_Reply :=
                 A11y.Linux.ATSPi_Component.Handle_Method
                   (Request.Session,
                    Path,
                    Method,
                    Request.Point,
                    Snapshots.Component,
                    Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Linux.ATSPi_Component.Rectangle_Reply =>
                     return (Kind => Component_Rectangle,
                             Status => Reply.Status,
                             Bounds => Reply.Bounds,
                             others => <>);
                  when A11y.Linux.ATSPi_Component.Boolean_Reply =>
                     return (Kind => Component_Boolean,
                             Status => Reply.Status,
                             Boolean_Item => Reply.Boolean_Item,
                             others => <>);
                  when A11y.Linux.ATSPi_Component.Node_Reply =>
                     return (Kind => Component_Node,
                             Status => Reply.Status,
                             Node => Reply.Node,
                             others => <>);
                  when A11y.Linux.ATSPi_Component.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when A11y.Linux.ATSPi_Objects.Action =>
            declare
               Reply : constant A11y.Linux.ATSPi_Action.Action_Reply :=
                 A11y.Linux.ATSPi_Action.Handle_Method
                   (Request.Session,
                    Path,
                    Method,
                    Request.Index,
                    Snapshots.Action,
                    Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Linux.ATSPi_Action.UInt32_Reply =>
                     return (Kind => Action_UInt32,
                             Status => Reply.Status,
                             UInt32 => Reply.UInt32,
                             others => <>);
                  when A11y.Linux.ATSPi_Action.String_Reply =>
                     return (Kind => Action_String,
                             Status => Reply.Status,
                             Text => Reply.Text,
                             others => <>);
                  when A11y.Linux.ATSPi_Action.Invocation_Reply =>
                     return (Kind => Action_Invocation,
                             Status => Reply.Status,
                             Boolean_Item => A11y.Results.Succeeded
                               ((Status => Reply.Status)),
                             Requested_Action => Reply.Action,
                             others => <>);
                  when A11y.Linux.ATSPi_Action.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when A11y.Linux.ATSPi_Objects.Value =>
            declare
               Reply : constant A11y.Linux.ATSPi_Value.Value_Reply :=
                 A11y.Linux.ATSPi_Value.Handle_Method
                   (Request.Session,
                    Path,
                    Method,
                    Request.Requested_Value,
                    Snapshots.Value,
                    Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Linux.ATSPi_Value.Float_Reply =>
                     return (Kind => Value_Float,
                             Status => Reply.Status,
                             Float_Item => Reply.Float_Item,
                             others => <>);
                  when A11y.Linux.ATSPi_Value.Set_Request_Reply =>
                     return (Kind => Value_Set_Request,
                             Status => Reply.Status,
                             Boolean_Item => A11y.Results.Succeeded
                               ((Status => Reply.Status)),
                             Requested_Value => Reply.Requested_Value,
                             others => <>);
                  when A11y.Linux.ATSPi_Value.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when A11y.Linux.ATSPi_Objects.Selection =>
            declare
               Reply : constant A11y.Linux.ATSPi_Selection.Selection_Reply :=
                 A11y.Linux.ATSPi_Selection.Handle_Method
                   (Request.Session,
                    Path,
                    Method,
                    Request.Index,
                    Snapshots.Selection,
                    Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Linux.ATSPi_Selection.UInt32_Reply =>
                     return (Kind => Selection_UInt32,
                             Status => Reply.Status,
                             UInt32 => Reply.UInt32,
                             others => <>);
                  when A11y.Linux.ATSPi_Selection.Boolean_Reply =>
                     return (Kind => Selection_Boolean,
                             Status => Reply.Status,
                             Boolean_Item => Reply.Boolean_Item,
                             others => <>);
                  when A11y.Linux.ATSPi_Selection.Node_Reply =>
                     return (Kind => Selection_Node,
                             Status => Reply.Status,
                             Node => Reply.Node,
                             others => <>);
                  when A11y.Linux.ATSPi_Selection.Selection_Request_Reply =>
                     return (Kind => Selection_Request,
                             Status => Reply.Status,
                             Boolean_Item => A11y.Results.Succeeded
                               ((Status => Reply.Status)),
                             Node => Reply.Node,
                             Selection_Request => Reply.Request,
                             others => <>);
                  when A11y.Linux.ATSPi_Selection.Direction_Reply =>
                     return Error (A11y.Results.Internal_Error);
                  when A11y.Linux.ATSPi_Selection.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when A11y.Linux.ATSPi_Objects.Text
            | A11y.Linux.ATSPi_Objects.Editable_Text =>
            declare
               Reply : A11y.Linux.ATSPi_Text.Text_Reply;
            begin
               if Request.Requested_Interface =
                 A11y.Linux.ATSPi_Objects.Editable_Text
                 and then
                   (Method = "InsertText"
                    or else Method = "DeleteText"
                    or else Method = "ReplaceText"
                    or else Method = "SetTextContents")
               then
                  Reply := A11y.Linux.ATSPi_Text.Handle_Edit_Method
                    (Request.Session,
                     Path,
                     Method,
                     Request.Index,
                     Request.Count,
                     Widen (To_String (Request.Attribute)),
                     Snapshots.Text,
                     Snapshots.Limits);
               else
                  Reply := A11y.Linux.ATSPi_Text.Handle_Method
                    (Request.Session,
                     Path,
                     Method,
                     Request.Index,
                     Request.Count,
                     Snapshots.Text,
                     Snapshots.Limits);
               end if;

               case Reply.Kind is
                  when A11y.Linux.ATSPi_Text.UInt32_Reply =>
                     return (Kind => Text_UInt32,
                             Status => Reply.Status,
                             UInt32 => Reply.UInt32,
                             others => <>);
                  when A11y.Linux.ATSPi_Text.Wide_Text_Reply =>
                     declare
                        Reply_Status : A11y.Results.Result;
                        Encoded : constant Unbounded_String :=
                          Encode_UTF8
                            (To_Wide_Wide_String (Reply.Wide_Text),
                             Reply_Status);
                     begin
                        if A11y.Results.Failed (Reply_Status) then
                           return Error (Reply_Status.Status);
                        end if;

                        return (Kind => Text_Wide_Text,
                                Status => Reply.Status,
                                Text => Encoded,
                                others => <>);
                     end;
                  when A11y.Linux.ATSPi_Text.Edit_Request_Reply =>
                     return (Kind => Text_Edit_Request,
                             Status => Reply.Status,
                             Boolean_Item => A11y.Results.Succeeded
                               ((Status => Reply.Status)),
                             Requested_Edit => Reply.Requested_Edit,
                             others => <>);
                  when A11y.Linux.ATSPi_Text.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when A11y.Linux.ATSPi_Objects.Table
            | A11y.Linux.ATSPi_Objects.Table_Cell =>
            declare
               Reply : constant A11y.Linux.ATSPi_Table.Table_Reply :=
                 A11y.Linux.ATSPi_Table.Handle_Method
                   (Request.Session,
                    Path,
                    Method,
                    Request.Row,
                    Request.Column,
                    Snapshots.Table,
                    Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Linux.ATSPi_Table.UInt32_Reply =>
                     return (Kind => Table_UInt32,
                             Status => Reply.Status,
                             UInt32 => Reply.UInt32,
                             others => <>);
                  when A11y.Linux.ATSPi_Table.Node_Reply =>
                     return (Kind => Table_Node,
                             Status => Reply.Status,
                             Node => Reply.Node,
                             others => <>);
                  when A11y.Linux.ATSPi_Table.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when A11y.Linux.ATSPi_Objects.Image =>
            declare
               Reply : constant A11y.Linux.ATSPi_Image.Image_Reply :=
                 A11y.Linux.ATSPi_Image.Handle_Method
                   (Request.Session,
                    Path,
                    Method,
                    Snapshots.Image,
                    Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Linux.ATSPi_Image.String_Reply =>
                     return (Kind => Image_String,
                             Status => Reply.Status,
                             Text => Reply.Text,
                             others => <>);
                  when A11y.Linux.ATSPi_Image.Size_Reply =>
                     return (Kind => Image_Size,
                             Status => Reply.Status,
                             Size => Reply.Size,
                             others => <>);
                  when A11y.Linux.ATSPi_Image.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when A11y.Linux.ATSPi_Objects.Document =>
            declare
               Reply : constant A11y.Linux.ATSPi_Document.Document_Reply :=
                 A11y.Linux.ATSPi_Document.Handle_Method
                   (Request.Session,
                    Path,
                    Method,
                    To_String (Request.Attribute),
                    Snapshots.Document,
                    Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Linux.ATSPi_Document.String_Reply =>
                     return (Kind => Document_String,
                             Status => Reply.Status,
                             Text => Reply.Text,
                             others => <>);
                  when A11y.Linux.ATSPi_Document.UInt32_Reply =>
                     return (Kind => Document_UInt32,
                             Status => Reply.Status,
                             UInt32 => Reply.UInt32,
                             others => <>);
                  when A11y.Linux.ATSPi_Document.Boolean_Reply =>
                     return (Kind => Document_Boolean,
                             Status => Reply.Status,
                             Boolean_Item => Reply.Boolean_Item,
                             others => <>);
                  when A11y.Linux.ATSPi_Document.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when A11y.Linux.ATSPi_Objects.Live_Region =>
            declare
               Reply : constant
                 A11y.Linux.ATSPi_Live_Regions.Live_Reply :=
                   A11y.Linux.ATSPi_Live_Regions.Handle_Method
                     (Request.Session,
                      Path,
                      Method,
                      Snapshots.Live_Region,
                      Snapshots.Limits);
            begin
               case Reply.Kind is
                  when A11y.Linux.ATSPi_Live_Regions.String_Reply =>
                     return (Kind => Live_String,
                             Status => Reply.Status,
                             Text => Reply.Text,
                             others => <>);
                  when A11y.Linux.ATSPi_Live_Regions.Boolean_Reply =>
                     return (Kind => Live_Boolean,
                             Status => Reply.Status,
                             Boolean_Item => Reply.Boolean_Item,
                             others => <>);
                  when A11y.Linux.ATSPi_Live_Regions.Error_Reply =>
                     return Error (Reply.Status);
               end case;
            end;

         when A11y.Linux.ATSPi_Objects.Surface =>
            declare
               Query : A11y.Linux.ATSPi_Surfaces.Surface_Query;
            begin
               if Method = "GetSurfaceKind" then
                  Query := A11y.Linux.ATSPi_Surfaces.Kind_Name;
               elsif Method = "GetSurfaceRole" then
                  Query := A11y.Linux.ATSPi_Surfaces.Surface_Role;
               elsif Method = "GetSurfaceStates" then
                  Query := A11y.Linux.ATSPi_Surfaces.Surface_States;
               elsif Method = "IsTopLevel" then
                  Query := A11y.Linux.ATSPi_Surfaces.Is_Top_Level;
               elsif Method = "IsModal" then
                  Query := A11y.Linux.ATSPi_Surfaces.Is_Modal;
               elsif Method = "IsVisible" then
                  Query := A11y.Linux.ATSPi_Surfaces.Is_Visible;
               elsif Method = "IsActive" then
                  Query := A11y.Linux.ATSPi_Surfaces.Is_Active;
               elsif Method = "IsMinimized" then
                  Query := A11y.Linux.ATSPi_Surfaces.Is_Minimized;
               elsif Method = "IsMaximized" then
                  Query := A11y.Linux.ATSPi_Surfaces.Is_Maximized;
               elsif Method = "IsFullscreen" then
                  Query := A11y.Linux.ATSPi_Surfaces.Is_Fullscreen;
               elsif Method = "CanClose" then
                  Query := A11y.Linux.ATSPi_Surfaces.Can_Close;
               elsif Method = "CanResize" then
                  Query := A11y.Linux.ATSPi_Surfaces.Can_Resize;
               elsif Method = "CanMove" then
                  Query := A11y.Linux.ATSPi_Surfaces.Can_Move;
               else
                  return Error (A11y.Results.Unsupported_Capability);
               end if;

               declare
                  Reply : constant A11y.Linux.ATSPi_Surfaces.Surface_Reply :=
                    A11y.Linux.ATSPi_Surfaces.Query_Surface
                      (Snapshots.Surface, Query, Snapshots.Limits);
               begin
                  case Reply.Kind is
                     when A11y.Linux.ATSPi_Surfaces.String_Reply =>
                        return (Kind => Surface_String,
                                Status => Reply.Status,
                                Text => Reply.Text,
                                others => <>);
                     when A11y.Linux.ATSPi_Surfaces.Role_Reply =>
                        return (Kind => Surface_Role,
                                Status => Reply.Status,
                                UInt32 => A11y.Linux.ATSPi_Mappings.ATSPI_Role'Pos
                                  (Reply.Role),
                                others => <>);
                     when A11y.Linux.ATSPi_Surfaces.State_Set_Reply =>
                        return (Kind => Surface_State_Set,
                                Status => Reply.Status,
                                State_Set => Reply.States,
                                others => <>);
                     when A11y.Linux.ATSPi_Surfaces.Boolean_Reply =>
                        return (Kind => Surface_Boolean,
                                Status => Reply.Status,
                                Boolean_Item => Reply.Boolean_Item,
                                others => <>);
                     when A11y.Linux.ATSPi_Surfaces.Error_Reply =>
                        return Error (Reply.Status);
                  end case;
               end;
            end;

      end case;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Dispatch;

end A11y.Linux.ATSPi_Method_Router;
