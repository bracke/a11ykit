with Ada.Strings.Fixed;

with A11y.Capabilities;
with A11y.Linux.ATSPi_Objects;
with A11y.Resource_Limits;
with A11y.Roles;

package body A11y.Linux.ATSPi_DBus_Boundary is
   use Ada.Strings.Unbounded;
   use type A11y.Linux.ATSPi_Method_Router.Routed_Reply_Kind;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Roles.Role;

   DBus_Introspectable_Interface : constant String :=
     "org.freedesktop.DBus.Introspectable";
   DBus_Introspect_Method : constant String := "Introspect";
   DBus_Peer_Interface : constant String := "org.freedesktop.DBus.Peer";
   DBus_Ping_Method : constant String := "Ping";
   DBus_Get_Machine_Id_Method : constant String := "GetMachineId";
   DBus_Properties_Interface : constant String :=
     "org.freedesktop.DBus.Properties";
   DBus_Get_Method : constant String := "Get";
   DBus_Get_All_Method : constant String := "GetAll";

   function Error (Status : A11y.Results.Status_Code) return DBus_Method_Reply is
     (Kind       => Error_Reply,
      Status     => Status,
      Error_Name => To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Error_Name (Status)));

   function Method
     (Routed : A11y.Linux.ATSPi_Method_Router.Routed_Reply)
      return DBus_Method_Reply is
     (Kind        => Method_Reply,
      Status      => Routed.Status,
      Routed_Kind => Routed.Kind,
      Text        => Routed.Text,
      UInt32      => Routed.UInt32,
      Int32       => Routed.Int32,
      Boolean_Item => Routed.Boolean_Item,
      Float_Item  => Routed.Float_Item,
      Node        => Routed.Node,
      Nodes       => Routed.Nodes,
      Strings     => Routed.Strings,
      Bounds      => Routed.Bounds,
      Size        => Routed.Size,
      State_Set   => Routed.State_Set,
      Attributes  => Routed.Attributes,
      Relations   => Routed.Relations,
      Requested_Action => Routed.Requested_Action,
      Requested_Value => Routed.Requested_Value,
      Selection_Request => Routed.Selection_Request,
      Requested_Edit => Routed.Requested_Edit);

   procedure Record_Final_Reply
     (Report : in out Registered_Call_Boundary_Report;
      Reply  : DBus_Method_Reply) is
   begin
      Report.Reply_Status := Reply.Status;
      Report.Final_Status := Reply.Status;
   end Record_Final_Reply;

   procedure Record_Final_Status
     (Report : in out Registered_Call_Boundary_Report;
      Status : A11y.Results.Status_Code) is
   begin
      Report.Final_Status := Status;
   end Record_Final_Status;

   function Interface_From_Name
     (Name   : String;
      Result : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Objects.ATSPI_Interface
   is
   begin
      for Interface_Item in A11y.Linux.ATSPi_Objects.ATSPI_Interface loop
         if Name = A11y.Linux.ATSPi_Objects.Interface_Name
           (Interface_Item)
         then
            Result := A11y.Results.Ok;
            return Interface_Item;
         end if;
      end loop;

      Result := (Status => A11y.Results.Unsupported_Capability);
      return A11y.Linux.ATSPi_Objects.Accessible;
   end Interface_From_Name;

   function Introspection_XML
     (Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result)
      return Unbounded_String
   is
      Text : Unbounded_String := To_Unbounded_String
        ("<!DOCTYPE node PUBLIC ""-//freedesktop//DTD D-BUS Object " &
         "Introspection 1.0//EN"" " &
         """http://www.freedesktop.org/standards/dbus/1.0/" &
         "introspect.dtd"">" & ASCII.LF & "<node>" & ASCII.LF);
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;

      procedure Append_Interface (Name : String) is
      begin
         Append (Text, "  <interface name=""" & Name & """/>" & ASCII.LF);
      end Append_Interface;

      procedure Append_ATSPI_Interface
        (Item : A11y.Linux.ATSPi_Objects.ATSPI_Interface)
      is
      begin
         Append_Interface (A11y.Linux.ATSPi_Objects.Interface_Name (Item));
      end Append_ATSPI_Interface;

      procedure Append_Capability_Interface
        (Capability     : A11y.Capabilities.Capability;
         Interface_Item : A11y.Linux.ATSPi_Objects.ATSPI_Interface)
      is
      begin
         if Snapshots.Accessible.Capabilities (Capability) then
            Append_ATSPI_Interface (Interface_Item);
         end if;
      end Append_Capability_Interface;
   begin
      Result := A11y.Resource_Limits.Validate (Snapshots.Limits);
      if A11y.Results.Failed (Result) then
         return Null_Unbounded_String;
      end if;

      Append_Interface (DBus_Introspectable_Interface);
      Append_Interface (DBus_Peer_Interface);
      Append_Interface (DBus_Properties_Interface);
      Append_ATSPI_Interface (A11y.Linux.ATSPi_Objects.Accessible);

      if Snapshots.Accessible.Role = A11y.Roles.Application then
         Append_ATSPI_Interface (A11y.Linux.ATSPi_Objects.Application);
      end if;

      Append_ATSPI_Interface (A11y.Linux.ATSPi_Objects.Component);
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

      if Snapshots.Accessible.Capabilities (A11y.Capabilities.Table) then
         Append_ATSPI_Interface (A11y.Linux.ATSPi_Objects.Table);
         Append_ATSPI_Interface (A11y.Linux.ATSPi_Objects.Table_Cell);
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

      Append (Text, "</node>" & ASCII.LF);
      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Text), Snapshots.Limits, Result);
      if A11y.Results.Failed (Result) then
         return Null_Unbounded_String;
      end if;

      return Ignored.Text_Item;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Null_Unbounded_String;
   end Introspection_XML;

   function Dispatch_Introspectable_Call
     (Call      : DBus_Method_Call;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return DBus_Method_Reply
   is
      Result : A11y.Results.Result;
      Text : Unbounded_String;
   begin
      if To_String (Call.Method_Name) /= DBus_Introspect_Method then
         return Error (A11y.Results.Unsupported_Action);
      elsif Length (Call.Attribute) /= 0
        or else Call.Index /= 0
        or else Call.Count /= 0
      then
         return Error (A11y.Results.Invalid_Argument);
      end if;

      Text := Introspection_XML (Snapshots, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return Method
        ((Kind   => A11y.Linux.ATSPi_Method_Router.Accessible_String,
          Status => A11y.Results.Success,
          Text   => Text,
          others => <>));
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Dispatch_Introspectable_Call;

   function Dispatch_Peer_Call
     (Call : DBus_Method_Call)
      return DBus_Method_Reply
   is
      function Session_Machine_Id
        (Session : A11y.Native_Identity.Backend_Session_Id)
         return String
      is
         Hex_Digits : constant String := "0123456789abcdef";
         Text   : String (1 .. 32) := (others => '0');
         Value  : Natural := A11y.Native_Identity.To_Natural (Session);
      begin
         for Index in reverse Text'Range loop
            Text (Index) := Hex_Digits ((Value mod 16) + 1);
            Value := Value / 16;
            exit when Value = 0;
         end loop;

         return Text;
      end Session_Machine_Id;
   begin
      if To_String (Call.Method_Name) /= DBus_Ping_Method then
         if To_String (Call.Method_Name) /= DBus_Get_Machine_Id_Method then
            return Error (A11y.Results.Unsupported_Action);
         end if;
      elsif Length (Call.Attribute) /= 0
        or else Call.Index /= 0
        or else Call.Count /= 0
      then
         return Error (A11y.Results.Invalid_Argument);
      end if;

      if Length (Call.Attribute) /= 0
        or else Call.Index /= 0
        or else Call.Count /= 0
      then
         return Error (A11y.Results.Invalid_Argument);
      elsif To_String (Call.Method_Name) = DBus_Ping_Method then
         return Method
           ((Kind   => A11y.Linux.ATSPi_Method_Router.Empty_Method_Return,
             Status => A11y.Results.Success,
             others => <>));
      else
         return Method
           ((Kind   => A11y.Linux.ATSPi_Method_Router.Accessible_String,
             Status => A11y.Results.Success,
             Text   => To_Unbounded_String
               (Session_Machine_Id (Call.Session)),
             others => <>));
      end if;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Dispatch_Peer_Call;

   function Dispatch_Properties_Call
     (Call      : DBus_Method_Call;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return DBus_Method_Reply
   is
      Requested_Interface : constant String := To_String (Call.Attribute);
      Property_Name       : constant String := To_String (Call.Attribute_2);
      Accessible_Interface : constant String :=
        A11y.Linux.ATSPi_Objects.Interface_Name
          (A11y.Linux.ATSPi_Objects.Accessible);
      Application_Interface : constant String :=
        A11y.Linux.ATSPi_Objects.Interface_Name
          (A11y.Linux.ATSPi_Objects.Application);

      function Variant_String
        (Text : Unbounded_String)
         return DBus_Method_Reply is
        (Method
           ((Kind   => A11y.Linux.ATSPi_Method_Router.DBus_Variant_String,
             Status => A11y.Results.Success,
             Text   => Text,
             others => <>)));

      function Variant_UInt32
        (Value : Natural)
         return DBus_Method_Reply is
        (Method
           ((Kind   => A11y.Linux.ATSPi_Method_Router.DBus_Variant_UInt32,
             Status => A11y.Results.Success,
             UInt32 => Value,
             others => <>)));

      function UInt32_Text (Value : Natural) return String is
        (Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Left));

      procedure Add_Property_String
        (Items : in out A11y.Linux.DBus_Codec.String_Vectors.Vector;
         Name  : String;
         Value : Unbounded_String) is
      begin
         Items.Append (To_Unbounded_String (Name));
         Items.Append (To_Unbounded_String ("s"));
         Items.Append (Value);
      end Add_Property_String;

      procedure Add_Property_UInt32
        (Items : in out A11y.Linux.DBus_Codec.String_Vectors.Vector;
         Name  : String;
         Value : Natural) is
      begin
         Items.Append (To_Unbounded_String (Name));
         Items.Append (To_Unbounded_String ("u"));
         Items.Append (To_Unbounded_String (UInt32_Text (Value)));
      end Add_Property_UInt32;

      function Property_Map
        (Items : A11y.Linux.DBus_Codec.String_Vectors.Vector)
         return DBus_Method_Reply is
        (Method
           ((Kind    => A11y.Linux.ATSPi_Method_Router.DBus_Property_Map,
             Status  => A11y.Results.Success,
             Strings => Items,
             others  => <>)));
   begin
      if To_String (Call.Method_Name) /= DBus_Get_Method
        and then To_String (Call.Method_Name) /= DBus_Get_All_Method
      then
         return Error (A11y.Results.Unsupported_Action);
      elsif Requested_Interface'Length = 0
        or else Call.Index /= 0
        or else Call.Count /= 0
      then
         return Error (A11y.Results.Invalid_Argument);
      elsif To_String (Call.Method_Name) = DBus_Get_Method
        and then Property_Name'Length = 0
      then
         return Error (A11y.Results.Invalid_Argument);
      elsif To_String (Call.Method_Name) = DBus_Get_All_Method
        and then Property_Name'Length /= 0
      then
         return Error (A11y.Results.Invalid_Argument);
      end if;

      if Requested_Interface = Accessible_Interface then
         if To_String (Call.Method_Name) = DBus_Get_All_Method then
            declare
               Items : A11y.Linux.DBus_Codec.String_Vectors.Vector;
            begin
               Add_Property_String (Items, "Name", Snapshots.Accessible.Name);
               Add_Property_String
                 (Items, "Description", Snapshots.Accessible.Description);
               Add_Property_UInt32
                 (Items,
                  "Role",
                  A11y.Linux.ATSPi_Mappings.ATSPI_Role'Pos
                    (A11y.Linux.ATSPi_Mappings.Map_Role
                       (Snapshots.Accessible.Role)));
               Add_Property_UInt32
                 (Items, "ChildCount", Snapshots.Accessible.Child_Count);
               return Property_Map (Items);
            end;
         elsif Property_Name = "Name" then
            return Variant_String (Snapshots.Accessible.Name);
         elsif Property_Name = "Description" then
            return Variant_String (Snapshots.Accessible.Description);
         elsif Property_Name = "Role" then
            return Variant_UInt32
              (A11y.Linux.ATSPi_Mappings.ATSPI_Role'Pos
                 (A11y.Linux.ATSPi_Mappings.Map_Role
                    (Snapshots.Accessible.Role)));
         elsif Property_Name = "ChildCount" then
            return Variant_UInt32 (Snapshots.Accessible.Child_Count);
         else
            return Error (A11y.Results.Unsupported_Property);
         end if;
      elsif Requested_Interface = Application_Interface then
         if Snapshots.Accessible.Role /= A11y.Roles.Application then
            return Error (A11y.Results.Unsupported_Capability);
         elsif To_String (Call.Method_Name) = DBus_Get_All_Method then
            declare
               Items : A11y.Linux.DBus_Codec.String_Vectors.Vector;
            begin
               Add_Property_UInt32
                 (Items, "Id", Snapshots.Application.Application_Id);
               Add_Property_String
                 (Items, "ToolkitName", Snapshots.Application.Toolkit_Name);
               Add_Property_String
                 (Items, "Version", Snapshots.Application.Version);
               Add_Property_String
                 (Items, "Locale", Snapshots.Application.Locale);
               return Property_Map (Items);
            end;
         elsif Property_Name = "Id" then
            return Variant_UInt32 (Snapshots.Application.Application_Id);
         elsif Property_Name = "ToolkitName" then
            return Variant_String (Snapshots.Application.Toolkit_Name);
         elsif Property_Name = "Version" then
            return Variant_String (Snapshots.Application.Version);
         elsif Property_Name = "Locale" then
            return Variant_String (Snapshots.Application.Locale);
         else
            return Error (A11y.Results.Unsupported_Property);
         end if;
      else
         return Error (A11y.Results.Unsupported_Capability);
      end if;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Dispatch_Properties_Call;

   function Dispatch_Call
     (Call      : DBus_Method_Call;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return DBus_Method_Reply
   is
      Result : A11y.Results.Result;
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;
      Ignored_Node : A11y.Node_Ids.Node_Id;
      Interface_Item : A11y.Linux.ATSPi_Objects.ATSPI_Interface;
      Request : A11y.Linux.ATSPi_Method_Router.Method_Request;
      Routed : A11y.Linux.ATSPi_Method_Router.Routed_Reply;
   begin
      Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
        (To_String (Call.Object_Path), Snapshots.Limits, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Ignored_Node := A11y.Linux.ATSPi_Objects.Node_From_Object_Path
        (Call.Session, To_String (Call.Object_Path), Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Call.Interface_Name), Snapshots.Limits, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Call.Method_Name), Snapshots.Limits, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Call.Attribute), Snapshots.Limits, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Call.Attribute_2), Snapshots.Limits, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      if To_String (Call.Interface_Name) = DBus_Introspectable_Interface then
         return Dispatch_Introspectable_Call (Call, Snapshots);
      elsif To_String (Call.Interface_Name) = DBus_Peer_Interface then
         return Dispatch_Peer_Call (Call);
      elsif To_String (Call.Interface_Name) = DBus_Properties_Interface then
         return Dispatch_Properties_Call (Call, Snapshots);
      end if;

      Interface_Item := Interface_From_Name
        (To_String (Call.Interface_Name), Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Request.Session := Call.Session;
      Request.Path := Call.Object_Path;
      Request.Requested_Interface := Interface_Item;
      Request.Method := Call.Method_Name;
      Request.Index := Call.Index;
      Request.Count := Call.Count;
      Request.Point := Call.Point;
      Request.Row := Call.Row;
      Request.Column := Call.Column;
      Request.Attribute := Call.Attribute;
      Request.Requested_Value := Call.Requested_Value;

      Routed := A11y.Linux.ATSPi_Method_Router.Dispatch
        (Request, Snapshots);
      if Routed.Kind = A11y.Linux.ATSPi_Method_Router.Routed_Error then
         return Error (Routed.Status);
      end if;

      return Method (Routed);
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Dispatch_Call;

   function Admit_Registered_Call_Metadata
     (Call      : DBus_Method_Call;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Resolved  : A11y.Linux.ATSPi_Object_Registry.Object_Record_Snapshot)
      return A11y.Results.Result
   is
      Result : A11y.Results.Result;
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;
      Resolved_Node : A11y.Node_Ids.Node_Id;
      Ignored_Interface : A11y.Linux.ATSPi_Objects.ATSPI_Interface;
      Interface_Name : constant String := To_String (Call.Interface_Name);
      Method_Name : constant String := To_String (Call.Method_Name);
   begin
      Result := A11y.Resource_Limits.Validate (Snapshots.Limits);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
        (To_String (Call.Object_Path), Snapshots.Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Resolved_Node := A11y.Linux.ATSPi_Objects.Node_From_Object_Path
        (Call.Session, To_String (Call.Object_Path), Result);
      if A11y.Results.Failed (Result) then
         return Result;
      elsif Resolved_Node /= Resolved.Node then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (Interface_Name, Snapshots.Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (Method_Name, Snapshots.Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Call.Attribute), Snapshots.Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Call.Attribute_2), Snapshots.Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      if Interface_Name = DBus_Introspectable_Interface then
         if Method_Name = DBus_Introspect_Method then
            return A11y.Results.Ok;
         end if;
         return (Status => A11y.Results.Unsupported_Action);
      elsif Interface_Name = DBus_Peer_Interface then
         if Method_Name = DBus_Ping_Method
           or else Method_Name = DBus_Get_Machine_Id_Method
         then
            return A11y.Results.Ok;
         end if;
         return (Status => A11y.Results.Unsupported_Action);
      elsif Interface_Name = DBus_Properties_Interface then
         if Method_Name = DBus_Get_Method
           or else Method_Name = DBus_Get_All_Method
         then
            return A11y.Results.Ok;
         end if;
         return (Status => A11y.Results.Unsupported_Action);
      end if;

      Ignored_Interface := Interface_From_Name (Interface_Name, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      return A11y.Results.Ok;
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Admit_Registered_Call_Metadata;

   function Dispatch_Registered_Call
     (Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Call      : DBus_Method_Call;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return DBus_Method_Reply
   is
      Report : Registered_Call_Boundary_Report;
   begin
      return Dispatch_Registered_Call_With_Report
        (Registry, Call, Snapshots, Report);
   end Dispatch_Registered_Call;

   function Dispatch_Registered_Call_With_Report
     (Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Call      : DBus_Method_Call;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Registered_Call_Boundary_Report)
      return DBus_Method_Reply
   is
      Result : A11y.Results.Result;
      Resolved : A11y.Linux.ATSPi_Object_Registry.Object_Record_Snapshot;
      Context : A11y.Linux.ATSPi_Object_Registry.Object_Call_Context;
      Begin_Report :
        A11y.Linux.ATSPi_Object_Registry.Native_Call_Mutation_Report;
      End_Report :
        A11y.Linux.ATSPi_Object_Registry.Native_Call_Mutation_Report;
      Reply : DBus_Method_Reply;
      End_Result : A11y.Results.Result;
      Call_Admitted : Boolean := False;
   begin
      Report := (others => <>);
      A11y.Linux.ATSPi_Object_Registry.Resolve_Path
        (Registry, Call.Session, To_String (Call.Object_Path), Resolved,
         Result);
      if A11y.Results.Failed (Result) then
         Record_Final_Status (Report, Result.Status);
         return Error (Result.Status);
      end if;
      Report.Resolved := True;
      Report.Resolved_Object := Resolved;

      Result := Admit_Registered_Call_Metadata (Call, Snapshots, Resolved);
      if A11y.Results.Failed (Result) then
         Record_Final_Reply (Report, Error (Result.Status));
         return Error (Result.Status);
      end if;

      A11y.Linux.ATSPi_Object_Registry.Begin_Native_Call_With_Report
        (Registry, Call.Session, Resolved.Object, Context, Begin_Report,
         Result);
      Report.Begin_Report := Begin_Report;
      if A11y.Results.Failed (Result) then
         Record_Final_Status (Report, Result.Status);
         return Error (Result.Status);
      end if;
      Call_Admitted := True;
      Report.Native_Admitted := True;

      Reply := Dispatch_Call (Call, Snapshots);
      Report.Reply_Status := Reply.Status;

      A11y.Linux.ATSPi_Object_Registry.End_Native_Call_With_Report
        (Registry, Call.Session, Resolved.Object, Context, End_Report,
         End_Result);
      Report.End_Report := End_Report;
      Call_Admitted := False;
      if A11y.Results.Failed (End_Result) then
         Record_Final_Status (Report, End_Result.Status);
         return Error (End_Result.Status);
      end if;
      Report.Native_Completed := True;
      Record_Final_Status (Report, Reply.Status);

      return Reply;
   exception
      when others =>
         if Call_Admitted then
            A11y.Linux.ATSPi_Object_Registry.End_Native_Call_With_Report
              (Registry, Call.Session, Resolved.Object, Context, End_Report,
               End_Result);
            Report.End_Report := End_Report;
            Report.Native_Completed := A11y.Results.Succeeded (End_Result);
         end if;
         Record_Final_Status (Report, A11y.Results.Internal_Error);
         return Error (A11y.Results.Internal_Error);
   end Dispatch_Registered_Call_With_Report;

end A11y.Linux.ATSPi_DBus_Boundary;
