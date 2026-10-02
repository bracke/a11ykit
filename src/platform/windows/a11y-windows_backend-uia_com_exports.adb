with A11y.Native_Object_Caches;
with A11y.Actions;
with A11y.Windows_Backend.UIA_Properties;
with A11y.Windows_Backend.UIA_Selection;

package body A11y.Windows_Backend.UIA_COM_Exports is

   use type Interfaces.Unsigned_64;
   use type A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;

   package ABI renames A11y.Windows_Backend.UIA_ABI_Surface;
   package Bridge renames A11y.Windows_Backend.UIA_Bridge_Audit;
   package Boundary renames A11y.Windows_Backend.UIA_Provider_Boundary;
   package Registry_API renames A11y.Windows_Backend.UIA_Provider_Registry;

   function Error_Reply
     (Status : A11y.Results.Status_Code)
      return Boundary.Boundary_Reply
   is
      HResult : constant Boundary.HRESULT_Status := Boundary.HResult_For (Status);
      Kind : constant Boundary.Boundary_Reply_Kind :=
        (if Status in
           A11y.Results.Unsupported_Property |
           A11y.Results.Unsupported_Capability |
           A11y.Results.Unsupported_Action
         then Boundary.Provider_Not_Supported
         else Boundary.Provider_Error);
   begin
      return
        (Kind          => Kind,
         HResult       => HResult,
         Status        => Status,
         Routed        =>
           A11y.Windows_Backend.UIA_Request_Router.Routed_Error,
         Payload       =>
           (Kind   => A11y.Windows_Backend.UIA_Request_Router.Routed_Error,
            Status => Status),
         Native_Object => A11y.Native_Object_Caches.No_Object);
   end Error_Reply;

   function Required_Bridge_Operation
     (Slot : Callback_Slot)
      return Bridge.Bridge_Operation is
     (case Slot is
        when Query_Interface_Slot => Bridge.Query_Interface_Callback,
        when Add_Ref_Slot => Bridge.Add_Ref_Callback,
        when Release_Slot => Bridge.Release_Callback,
        when Provider_Method_Slot => Bridge.Provider_Method_Callback);

   function Callback_Name (Slot : Callback_Slot) return String is
     (Bridge.Operation_Name (Required_Bridge_Operation (Slot)));

   function Bridge_Entry (Slot : Callback_Slot) return Native_Bridge_Entry is
      Operation : constant Bridge.Bridge_Operation :=
        Required_Bridge_Operation (Slot);
   begin
      return
        (Slot       => Slot,
         Operation  => Operation,
         ABI_Only   => Bridge.Is_ABI_Only (Operation),
         Symbol     => Operation,
         Dispatches_Provider_Method => Slot = Provider_Method_Slot);
   end Bridge_Entry;

   function Build_Export_Table
     (Provider :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Export   :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Export_Descriptor)
      return COM_Export_Table
   is
      Table : COM_Export_Table;
   begin
      Table.Provider := Provider;
      Table.Status := Export.Status;
      Table.Session := Export.Session;
      Table.Root := Export.Root;
      Table.Node := Export.Node;
      Table.Native_Node_Component := Export.Native_Node_Component;
      Table.Host_Window_Bound := Export.Host_Window_Bound;
      Table.Host_Window_Component := Export.Host_Window_Component;
      Table.Defunct := Export.Defunct;

      if not Registry_API.Is_Valid (Provider) then
         Table.Status := A11y.Results.Node_Unavailable;
         return Table;
      elsif not Export.Exportable or else Export.Defunct then
         return Table;
      end if;

      for Slot in Callback_Slot loop
         Table.Callbacks (Slot) :=
           Bridge.Is_ABI_Only (Required_Bridge_Operation (Slot));
      end loop;

      for Method in ABI.UIA_ABI_Method loop
         Table.Methods (Method) := ABI.Can_Dispatch (Export, Method);
         if Table.Methods (Method) then
            Table.Dispatchable_Methods := Table.Dispatchable_Methods + 1;
         end if;
      end loop;

      Table.Exportable :=
        Table.Callbacks (Query_Interface_Slot)
        and then Table.Callbacks (Add_Ref_Slot)
        and then Table.Callbacks (Release_Slot)
        and then Table.Callbacks (Provider_Method_Slot)
        and then Table.Dispatchable_Methods > 0;

      if Table.Exportable then
         Table.Status := A11y.Results.Success;
      end if;

      return Table;
   exception
      when others =>
         return
           (Exportable            => False,
            Status                => A11y.Results.Internal_Error,
            Provider              => Registry_API.No_Provider,
            Session               => A11y.Native_Identity.No_Session,
            Root                  => A11y.Node_Ids.No_Node,
            Node                  => A11y.Node_Ids.No_Node,
            Native_Node_Component => 0,
            Callbacks             => [others => False],
            Methods               => [others => False],
            Dispatchable_Methods  => 0,
            Host_Window_Bound     => False,
            Host_Window_Component => 0,
            Defunct               => True);
   end Build_Export_Table;

   function Can_Invoke_Callback
     (Table : COM_Export_Table;
      Slot  : Callback_Slot)
      return Boolean is
     (Table.Exportable and then Table.Callbacks (Slot));

   function Can_Dispatch_Method
     (Table  : COM_Export_Table;
      Method : ABI.UIA_ABI_Method)
      return Boolean is
     (Table.Exportable and then Table.Methods (Method));

   function HRESULT_Code
     (Status : Boundary.HRESULT_Status)
      return Interfaces.Unsigned_32 is
     (case Status is
        when Boundary.S_OK => 16#0000_0000#,
        when Boundary.S_FALSE => 16#0000_0001#,
        when Boundary.UIA_E_ELEMENTNOTAVAILABLE => 16#8004_0201#,
        when Boundary.UIA_E_ELEMENTNOTENABLED => 16#8004_0200#,
        when Boundary.UIA_E_INVALIDOPERATION => 16#8013_1509#,
        when Boundary.E_INVALIDARG => 16#8007_0057#,
        when Boundary.E_ACCESSDENIED => 16#8007_0005#,
        when Boundary.E_OUTOFMEMORY => 16#8007_000E#,
        when Boundary.E_FAIL => 16#8000_4005#);

   function Method_Code
     (Method : ABI.UIA_ABI_Method)
      return Interfaces.Unsigned_32 is
     (ABI.Method_Code (Method));

   function Method_From_Code
     (Code   : Interfaces.Unsigned_32;
      Result : out A11y.Results.Result)
      return ABI.UIA_ABI_Method
   is
   begin
      return ABI.Method_From_Code (Code, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return ABI.IUnknown_Query_Interface;
   end Method_From_Code;

   function Build_Callback_Frame
     (Table  : COM_Export_Table;
      Method : ABI.UIA_ABI_Method)
      return ABI_Callback_Frame is
     (Session_Code  =>
        Interfaces.Unsigned_64
          (A11y.Native_Identity.To_Natural (Table.Session)),
      Provider_Code =>
        Interfaces.Unsigned_64 (Registry_API.To_Natural (Table.Provider)),
      Method_Code   => Method_Code (Method));

   function Invoke_Provider_Method
     (Table     : COM_Export_Table;
      Method    : ABI.UIA_ABI_Method;
      Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : out Method_Invoke_Report;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return Boundary.Boundary_Reply
   is
      Snapshot_Copy :
        aliased A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle :=
          Snapshots;
   begin
      return Invoke_Provider_Method_Access
        (Table, Method, Registry, Snapshot_Copy'Access, Report, Direction,
         Point);
   end Invoke_Provider_Method;

   function Invoke_Provider_Method_Access
     (Table     : COM_Export_Table;
      Method    : ABI.UIA_ABI_Method;
      Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : in out Method_Invoke_Report;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return Boundary.Boundary_Reply
   is
      Report_Copy : aliased Method_Invoke_Report := Report;
      Reply : Boundary.Boundary_Reply;
   begin
      Reply := Invoke_Provider_Method_Report_Access
        (Table,
         Method,
         Registry,
         Snapshots,
         Report_Copy'Unchecked_Access,
         Direction,
         Point);
      Report := Report_Copy;
      return Reply;
   end Invoke_Provider_Method_Access;

   function Invoke_Provider_Method_Report_Access
     (Table     : COM_Export_Table;
      Method    : ABI.UIA_ABI_Method;
      Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : not null Method_Invoke_Report_Access;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return Boundary.Boundary_Reply
   is
      Info : constant ABI.ABI_Method_Descriptor := ABI.Descriptor (Method);
      Request : aliased Boundary.Boundary_Request;
      Reply : aliased Boundary.Boundary_Reply;
      Request_Access : Boundary.Boundary_Request_Access;
      Report_Access : Boundary.Registered_Native_Request_Report_Access;
      Reply_Access : Boundary.Boundary_Reply_Access;
   begin
      Report.all := (others => <>);
      Report.all.Requested_Interface := Info.Provider_Interface_Kind;
      Report.all.Request_Kind := Info.Request_Kind;
      Report.all.Dispatch_Stage := 10;
      Report.all.Callback_Allowed :=
        Can_Invoke_Callback (Table, Provider_Method_Slot);
      Report.all.Dispatch_Stage := 20;

      if not Report.all.Callback_Allowed then
         Report.all.Dispatch_Stage := 21;
         Reply := Error_Reply (A11y.Results.Node_Unavailable);
      elsif Info.Is_Lifetime_Method then
         Report.all.Dispatch_Stage := 22;
         Reply := Error_Reply (A11y.Results.Unsupported_Capability);
      elsif not Can_Dispatch_Method (Table, Method) then
         Report.all.Dispatch_Stage := 23;
         Reply := Error_Reply (A11y.Results.Unsupported_Capability);
      else
         Report.all.Dispatch_Stage := 30;
         Report.all.Method_Dispatchable := True;
         Request.Kind := Info.Request_Kind;
         if Method = ABI.Fragment_Navigate then
            Request.Direction := Direction;
         elsif Method = ABI.Fragment_Root_Element_Provider_From_Point then
            Request.Hit_Test_Point := Point;
         elsif Method = ABI.Fragment_Get_Bounding_Rectangle then
            Request.Property :=
              A11y.Windows_Backend.UIA_Properties.Bounding_Rectangle;
         elsif Method = ABI.Fragment_Set_Focus then
            Request.Action := A11y.Actions.Set_Focus;
         elsif Method = ABI.Invoke_Provider_Invoke then
            Request.Action := A11y.Actions.Activate;
         elsif Method = ABI.Toggle_Provider_Toggle then
            Request.Action := A11y.Actions.Toggle;
         elsif Method = ABI.Expand_Collapse_Provider_Expand then
            Request.Action := A11y.Actions.Expand;
         elsif Method = ABI.Expand_Collapse_Provider_Collapse then
            Request.Action := A11y.Actions.Collapse;
         elsif Method = ABI.Selection_Item_Provider_Select then
            Request.Selection_Request :=
              A11y.Windows_Backend.UIA_Selection.Select_Item;
            Request.Selection_Target := Table.Node;
         elsif Method = ABI.Selection_Item_Provider_Add_To_Selection then
            Request.Selection_Request :=
              A11y.Windows_Backend.UIA_Selection.Add_Item_To_Selection;
            Request.Selection_Target := Table.Node;
         elsif Method = ABI.Selection_Item_Provider_Remove_From_Selection then
            Request.Selection_Request :=
              A11y.Windows_Backend.UIA_Selection.Deselect_Item;
            Request.Selection_Target := Table.Node;
         elsif Method = ABI.Selection_Item_Provider_Get_Is_Selected then
            Request.Selection :=
              A11y.Windows_Backend.UIA_Selection.Is_Item_Selected;
         elsif Method = ABI.Selection_Item_Provider_Get_Selection_Container then
            Request.Selection :=
              A11y.Windows_Backend.UIA_Selection.Selection_Root;
         elsif Method = ABI.Scroll_Item_Provider_Scroll_Into_View then
            Request.Action := A11y.Actions.Scroll_Into_View;
         elsif Method = ABI.Window_Provider_Close then
            Request.Action := A11y.Actions.Close;
         end if;
         Request.Has_Native_Identity := Info.Requires_Native_Identity;
         if Info.Requires_Native_Identity then
            Request.Native_Node_Component := Table.Native_Node_Component;
         end if;

         Report.all.Request_Prepared := True;
         Report.all.Request_Kind := Request.Kind;
         Report.all.Dispatch_Stage := 40;
         Report.all.Registered_Call_Attempted := True;
         Report.all.Dispatch_Stage := 50;
         Request_Access := Request'Unchecked_Access;
         Report.all.Dispatch_Stage := 51;
         Report_Access := Report.all.Boundary_Report'Unchecked_Access;
         Report.all.Dispatch_Stage := 52;
         Reply_Access := Reply'Unchecked_Access;
         Report.all.Dispatch_Stage := 53;
         Boundary.Dispatch_Registered_Native_Request_Full_Access
           (Registry,
            Table.Session,
            Table.Provider,
            Info.Provider_Interface_Kind,
            Request_Access,
            Snapshots,
            Report_Access,
            Reply_Access);
         Report.all.Dispatch_Stage := 60;
         Report.all.Registered_Dispatched := True;
      end if;

      Report.all.Dispatch_Stage := 90;
      Report.all.Reply_Status := Reply.Status;
      Report.all.HResult := Reply.HResult;
      Report.all.ABI_HResult_Code := HRESULT_Code (Reply.HResult);
      return Reply;
   exception
      when others =>
         if Report.all.Dispatch_Stage = 0 then
            Report.all.Dispatch_Stage := 999;
         end if;
         Report.all.Reply_Status := A11y.Results.Internal_Error;
         Report.all.HResult := Boundary.E_FAIL;
         Report.all.ABI_HResult_Code := HRESULT_Code (Boundary.E_FAIL);
         return Error_Reply (A11y.Results.Internal_Error);
   end Invoke_Provider_Method_Report_Access;

   function Invoke_Callback_Frame
     (Table     : COM_Export_Table;
      Frame     : ABI_Callback_Frame;
      Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : out ABI_Callback_Report;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return Boundary.Boundary_Reply
   is
      Snapshot_Copy :
        aliased A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle :=
          Snapshots;
   begin
      return Invoke_Callback_Frame_Access
        (Table, Frame, Registry, Snapshot_Copy'Access, Report, Direction,
         Point);
   end Invoke_Callback_Frame;

   function Invoke_Callback_Frame_Access
     (Table     : COM_Export_Table;
      Frame     : ABI_Callback_Frame;
      Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : in out ABI_Callback_Report;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return Boundary.Boundary_Reply
   is
      Report_Copy : aliased ABI_Callback_Report := Report;
      Reply : Boundary.Boundary_Reply;
   begin
      Reply := Invoke_Callback_Frame_Report_Access
        (Table,
         Frame,
         Registry,
         Snapshots,
         Report_Copy'Unchecked_Access,
         Direction,
         Point);
      Report := Report_Copy;
      return Reply;
   end Invoke_Callback_Frame_Access;

   function Invoke_Callback_Frame_Report_Access
     (Table     : COM_Export_Table;
      Frame     : ABI_Callback_Frame;
      Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : not null ABI_Callback_Report_Access;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return Boundary.Boundary_Reply
   is
      Result : A11y.Results.Result;
      Method : ABI.UIA_ABI_Method;
      Reply : Boundary.Boundary_Reply;
   begin
      Report.all := (others => <>);
      Report.all.Frame_Matches_Export :=
        Frame.Session_Code =
          Interfaces.Unsigned_64
            (A11y.Native_Identity.To_Natural (Table.Session))
        and then Frame.Provider_Code =
          Interfaces.Unsigned_64 (Registry_API.To_Natural (Table.Provider));

      if not Report.all.Frame_Matches_Export then
         Reply := Error_Reply (A11y.Results.Node_Unavailable);
      else
         Method := Method_From_Code (Frame.Method_Code, Result);
         if A11y.Results.Failed (Result) then
            Reply := Error_Reply (Result.Status);
         else
            Report.all.Method_Code_Valid := True;
            Report.all.Method := Method;
            Reply := Invoke_Provider_Method_Report_Access
              (Table,
               Method,
               Registry,
               Snapshots,
               Report.all.Invoke'Unchecked_Access,
               Direction,
               Point);
         end if;
      end if;

      Report.all.Reply_Status := Reply.Status;
      Report.all.ABI_HResult_Code := HRESULT_Code (Reply.HResult);
      return Reply;
   exception
      when others =>
         Report.all.Reply_Status := A11y.Results.Internal_Error;
         Report.all.ABI_HResult_Code := HRESULT_Code (Boundary.E_FAIL);
         return Error_Reply (A11y.Results.Internal_Error);
   end Invoke_Callback_Frame_Report_Access;

   function All_Callbacks_Audited (Table : COM_Export_Table) return Boolean is
   begin
      for Slot in Callback_Slot loop
         if Table.Callbacks (Slot)
           and then not Bridge.Is_ABI_Only (Required_Bridge_Operation (Slot))
         then
            return False;
         end if;
      end loop;

      return True;
   end All_Callbacks_Audited;

end A11y.Windows_Backend.UIA_COM_Exports;
