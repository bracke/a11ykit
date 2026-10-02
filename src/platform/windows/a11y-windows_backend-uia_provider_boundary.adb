with Ada.Unchecked_Deallocation;

with A11y.Native_Boundary_Calls;

package body A11y.Windows_Backend.UIA_Provider_Boundary is
   use type A11y.Results.Status_Code;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Windows_Backend.UIA_Request_Router.Routed_Reply_Kind;

   function HResult_For
     (Status : A11y.Results.Status_Code)
      return HRESULT_Status is
     (case A11y.Native_Boundary_Calls.Return_Class (Status) is
        when A11y.Native_Boundary_Calls.Return_Success =>
          S_OK,
        when A11y.Native_Boundary_Calls.Return_Unsupported =>
          S_FALSE,
        when A11y.Native_Boundary_Calls.Return_Unavailable |
             A11y.Native_Boundary_Calls.Return_Shutting_Down =>
          UIA_E_ELEMENTNOTAVAILABLE,
        when A11y.Native_Boundary_Calls.Return_Invalid_Argument =>
          E_INVALIDARG,
        when A11y.Native_Boundary_Calls.Return_Permission_Denied =>
          E_ACCESSDENIED,
        when A11y.Native_Boundary_Calls.Return_Resource_Limit =>
          E_OUTOFMEMORY,
        when A11y.Native_Boundary_Calls.Return_Disabled =>
          UIA_E_ELEMENTNOTENABLED,
        when A11y.Native_Boundary_Calls.Return_Invalid_State |
             A11y.Native_Boundary_Calls.Return_Read_Only |
             A11y.Native_Boundary_Calls.Return_Busy |
             A11y.Native_Boundary_Calls.Return_Timed_Out |
             A11y.Native_Boundary_Calls.Return_Cancelled =>
          UIA_E_INVALIDOPERATION,
        when A11y.Native_Boundary_Calls.Return_Protocol_Failure |
             A11y.Native_Boundary_Calls.Return_Native_Failure |
             A11y.Native_Boundary_Calls.Return_Internal_Error =>
          E_FAIL);

   function Status_For_HResult
     (Status : HRESULT_Status)
      return A11y.Results.Status_Code is
     (case Status is
        when S_OK =>
          A11y.Results.Success,
        when S_FALSE =>
          A11y.Results.Unsupported_Capability,
        when UIA_E_ELEMENTNOTAVAILABLE =>
          A11y.Results.Node_Unavailable,
        when UIA_E_ELEMENTNOTENABLED =>
          A11y.Results.Disabled,
        when UIA_E_INVALIDOPERATION =>
          A11y.Results.Invalid_State,
        when E_INVALIDARG =>
          A11y.Results.Invalid_Argument,
        when E_ACCESSDENIED =>
          A11y.Results.Permission_Denied,
        when E_OUTOFMEMORY =>
          A11y.Results.Resource_Limit,
        when E_FAIL =>
          A11y.Results.Internal_Error);

   function HResult_Code (Status : HRESULT_Status) return String is
     (case Status is
        when S_OK =>
          "0x00000000",
        when S_FALSE =>
          "0x00000001",
        when UIA_E_ELEMENTNOTAVAILABLE =>
          "0x80040201",
        when UIA_E_ELEMENTNOTENABLED =>
          "0x80040200",
        when UIA_E_INVALIDOPERATION =>
          "0x80131509",
        when E_INVALIDARG =>
          "0x80070057",
        when E_ACCESSDENIED =>
          "0x80070005",
        when E_OUTOFMEMORY =>
          "0x8007000E",
        when E_FAIL =>
          "0x80004005");

   function Diagnostic_For_HResult
     (Status : HRESULT_Status;
      Result : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic
   is
   begin
      return Diagnostic_For_HResult
        (Status, A11y.Resource_Limits.Default_Config, Result);
   end Diagnostic_For_HResult;

   function Diagnostic_For_HResult
     (Status : HRESULT_Status;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic
   is
      Item : A11y.Diagnostics.Diagnostic;
      Semantic_Status : constant A11y.Results.Status_Code :=
        Status_For_HResult (Status);
   begin
      A11y.Diagnostics.Create_For_Status
        (Identifier => "windows.uia.hresult",
         Status     => Semantic_Status,
         Item       => Item,
         Result     => Result,
         Feature    => "windows.uia.hresult_diagnostic",
         Redacted   => True);
      if A11y.Results.Failed (Result) then
         return Item;
      end if;

      A11y.Diagnostics.Add_Field
        (Item, "hresult_name", HRESULT_Status'Image (Status), Limits, Result,
         Redacted => False);
      if A11y.Results.Failed (Result) then
         return Item;
      end if;

      A11y.Diagnostics.Add_Field
        (Item, "hresult_code", HResult_Code (Status), Limits, Result,
         Redacted => False);
      if A11y.Results.Failed (Result) then
         return Item;
      end if;

      A11y.Diagnostics.Add_Field
        (Item,
         "structured_status",
         A11y.Results.Stable_Name (Semantic_Status),
         Limits,
         Result,
         Redacted => False);
      if A11y.Results.Failed (Result) then
         return Item;
      end if;

      Result := A11y.Results.Ok;
      return Item;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Item;
   end Diagnostic_For_HResult;

   function Reply
     (Kind   : Boundary_Reply_Kind;
      Status : A11y.Results.Status_Code;
      Routed : A11y.Windows_Backend.UIA_Request_Router.Routed_Reply_Kind :=
        A11y.Windows_Backend.UIA_Request_Router.Routed_Error;
      Native_Object : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object)
      return Boundary_Reply is
     (Kind    => Kind,
      HResult => HResult_For (Status),
      Status  => Status,
      Routed  => Routed,
      Payload =>
        (Kind   => A11y.Windows_Backend.UIA_Request_Router.Routed_Error,
         Status => Status),
      Native_Object => Native_Object);

   function Reply
     (Kind   : Boundary_Reply_Kind;
      Status : A11y.Results.Status_Code;
      Payload : A11y.Windows_Backend.UIA_Request_Router.Routed_Reply;
      Native_Object : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object)
      return Boundary_Reply is
     (Kind    => Kind,
      HResult => HResult_For (Status),
      Status  => Status,
      Routed  => Payload.Kind,
      Payload => Payload,
      Native_Object => Native_Object);

   function Router_Request
     (Request : Boundary_Request)
      return A11y.Windows_Backend.UIA_Request_Router.Request
   is
      Kind : A11y.Windows_Backend.UIA_Request_Router.Request_Kind;
      Relation : A11y.Relations.Relation_Kind := Request.Relation;
   begin
      case Request.Kind is
         when Get_Provider_Options =>
            Kind :=
              A11y.Windows_Backend.UIA_Request_Router
                .Provider_Options_Query;
            Relation := A11y.Relations.Labelled_By;
         when Get_Host_Raw_Element_Provider =>
            Kind :=
              A11y.Windows_Backend.UIA_Request_Router
                .Host_Raw_Element_Provider_Query;
            Relation := A11y.Relations.Labelled_By;
         when Get_Property_Value =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Property_Query;
            Relation := A11y.Relations.Labelled_By;
         when Get_Pattern_Provider =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Pattern_Query;
            Relation := A11y.Relations.Labelled_By;
         when Invoke_Action =>
            Kind :=
              A11y.Windows_Backend.UIA_Request_Router.Action_Request_Query;
            Relation := A11y.Relations.Labelled_By;
         when Navigate_Fragment =>
            Kind :=
              A11y.Windows_Backend.UIA_Request_Router.Fragment_Navigation_Query;
            Relation := A11y.Relations.Labelled_By;
         when Get_Embedded_Fragment_Roots =>
            Kind :=
              A11y.Windows_Backend.UIA_Request_Router
                .Embedded_Fragment_Roots_Query;
            Relation := A11y.Relations.Labelled_By;
         when Get_Fragment_Root =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Fragment_Root_Query;
            Relation := A11y.Relations.Labelled_By;
         when Get_Fragment_Focus =>
            Kind :=
              A11y.Windows_Backend.UIA_Request_Router
                .Fragment_Root_Focus_Query;
            Relation := A11y.Relations.Labelled_By;
         when Get_Fragment_From_Point =>
            Kind :=
              A11y.Windows_Backend.UIA_Request_Router
                .Fragment_Root_Point_Query;
            Relation := A11y.Relations.Labelled_By;
         when Get_Runtime_Id =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Runtime_Id_Query;
            Relation := A11y.Relations.Labelled_By;
         when Get_Relation_Targets =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Relation_Query;
         when Get_Value =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Value_Query;
         when Set_Value =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Value_Set_Query;
         when Get_Selection =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Selection_Query;
         when Set_Selection =>
            Kind :=
              A11y.Windows_Backend.UIA_Request_Router.Selection_Request_Query;
         when Get_Text =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Text_Query;
         when Get_Text_Edit =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Text_Edit_Query;
         when Get_Table =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Table_Query;
         when Get_Image =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Image_Query;
         when Get_Document =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Document_Query;
         when Get_Live_Region =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Live_Region_Query;
         when Get_Surface =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Surface_Query;
         when Advise_Event =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Event_Advise_Query;
            Relation := A11y.Relations.Labelled_By;
         when Unadvise_Event =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Event_Unadvise_Query;
            Relation := A11y.Relations.Labelled_By;
         when Raise_Event =>
            Kind := A11y.Windows_Backend.UIA_Request_Router.Event_Emission_Query;
            Relation := A11y.Relations.Labelled_By;
      end case;

      return
        (Kind      => Kind,
         Property  => Request.Property,
         Action    => Request.Action,
         Direction => Request.Direction,
         Relation  => Relation,
         Value     => Request.Value,
         Requested_Value => Request.Requested_Value,
         Selection => Request.Selection,
         Selection_Request => Request.Selection_Request,
         Selection_Target => Request.Selection_Target,
         Text      => Request.Text,
         Text_Edit => Request.Text_Edit,
         Table     => Request.Table,
         Image     => Request.Image,
         Document  => Request.Document,
         Live_Region => Request.Live_Region,
         Surface   => Request.Surface,
         Index     => Request.Index,
         Count     => Request.Count,
         Replacement => Request.Replacement,
         Row       => Request.Row,
         Column    => Request.Column,
         Event     => Request.Event,
         Use_Prepared_Event => Request.Use_Prepared_Event,
         Prepared_Event => Request.Prepared_Event);
   end Router_Request;

   function Native_Object_For
     (Routed : A11y.Windows_Backend.UIA_Request_Router.Routed_Reply)
      return A11y.Native_Object_Caches.Native_Object_Id is
   begin
      if Routed.Kind =
        A11y.Windows_Backend.UIA_Request_Router.Event_Emission
      then
         return Routed.Native_Object;
      end if;

      return A11y.Native_Object_Caches.No_Object;
   end Native_Object_For;

   procedure Record_Final_Reply
     (Report : in out Registered_Native_Request_Report;
      Reply  : Boundary_Reply) is
   begin
      Report.Reply_Status := Reply.Status;
      Report.Final_Status := Reply.Status;
   end Record_Final_Reply;

   procedure Record_Final_Status
     (Report : in out Registered_Native_Request_Report;
      Status : A11y.Results.Status_Code) is
   begin
      Report.Final_Status := Status;
   end Record_Final_Status;

   function Interface_Supports_Request
     (Requested : A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Request   : UIA_Request_Kind)
      return Boolean is
   begin
      case Requested is
         when A11y.Windows_Backend.UIA_Com_Providers.IUnknown_Interface =>
            return False;
         when A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Simple =>
           return Request in
              Get_Provider_Options |
              Get_Host_Raw_Element_Provider |
              Get_Property_Value |
              Get_Pattern_Provider |
              Invoke_Action |
              Set_Value;
         when A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Fragment =>
            return Request in
              Navigate_Fragment |
              Get_Property_Value |
              Get_Embedded_Fragment_Roots |
              Get_Fragment_Root |
              Get_Runtime_Id |
              Get_Relation_Targets |
              Get_Value |
              Set_Value |
              Get_Selection |
              Set_Selection |
              Get_Text |
              Get_Text_Edit |
              Get_Table |
              Get_Image |
              Get_Document |
              Get_Live_Region |
              Get_Surface |
              Invoke_Action |
              Raise_Event;
         when A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Fragment_Root =>
            return Request in
              Get_Fragment_Focus |
              Get_Fragment_From_Point |
              Raise_Event;
         when A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Advise_Events =>
            return Request in Advise_Event | Unadvise_Event;
         when A11y.Windows_Backend.UIA_Com_Providers.Unsupported_Interface =>
            return False;
      end case;
   end Interface_Supports_Request;

   function Effective_Event_Source
     (Request : Boundary_Request)
      return A11y.Node_Ids.Node_Id is
     (if Request.Use_Prepared_Event then
        Request.Prepared_Event.Event.Source
      else
        Request.Event.Source);

   function Primary_Node_Access
     (Request   : not null Boundary_Request_Access;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle)
      return A11y.Node_Ids.Node_Id;

   function Primary_Node
     (Request   : Boundary_Request;
      Snapshots : A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle)
      return A11y.Node_Ids.Node_Id is
      Request_Copy : aliased Boundary_Request := Request;
      Snapshot_Copy :
        aliased A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle :=
          Snapshots;
   begin
      return Primary_Node_Access
        (Request_Copy'Unchecked_Access, Snapshot_Copy'Access);
   end Primary_Node;

   function Primary_Node_Access
     (Request   : not null Boundary_Request_Access;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle)
      return A11y.Node_Ids.Node_Id is
   begin
      case Request.Kind is
         when Get_Provider_Options =>
            return Snapshots.Properties.Id;
         when Get_Host_Raw_Element_Provider =>
            return Snapshots.Properties.Id;
         when Get_Property_Value =>
            return Snapshots.Properties.Id;
         when Get_Pattern_Provider | Invoke_Action =>
            return Snapshots.Action_Node;
         when Navigate_Fragment |
              Get_Embedded_Fragment_Roots |
              Get_Fragment_Root |
              Get_Fragment_Focus |
              Get_Fragment_From_Point |
              Get_Runtime_Id =>
            return Snapshots.Fragment.Node;
         when Get_Relation_Targets =>
            return Snapshots.Relation_Source;
         when Get_Value | Set_Value =>
            return Snapshots.Value.Id;
         when Get_Selection =>
            return Snapshots.Selection.Item;
         when Set_Selection =>
            return
              (if A11y.Node_Ids.Is_Valid (Request.Selection_Target)
               then Request.Selection_Target
               else Snapshots.Selection.Root);
         when Get_Text | Get_Text_Edit =>
            return Snapshots.Text.Id;
         when Get_Table =>
            return Snapshots.Table.Id;
         when Get_Image =>
            return Snapshots.Image.Id;
         when Get_Document =>
            return Snapshots.Document.Id;
         when Get_Live_Region =>
            return Snapshots.Live_Region.Id;
         when Get_Surface =>
            return Snapshots.Surface.Id;
         when Advise_Event | Unadvise_Event =>
            return Snapshots.Fragment.Node;
         when Raise_Event =>
            return Effective_Event_Source (Request.all);
      end case;
   end Primary_Node_Access;

   function Admit_Native_Identity
     (Request   : Boundary_Request;
      Snapshots : A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle)
      return A11y.Results.Result
   is
      Result : A11y.Results.Result;
      Expected : constant A11y.Node_Ids.Node_Id :=
        Primary_Node (Request, Snapshots);
      Resolved : A11y.Node_Ids.Node_Id;
   begin
      if not Request.Has_Native_Identity then
         return A11y.Results.Ok;
      elsif not A11y.Node_Ids.Is_Valid (Expected) then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      Resolved := A11y.Native_Identity.Node_From_Runtime_Identifier_Component
        (Snapshots.Fragment.Session, Request.Native_Node_Component, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      elsif Resolved /= Expected then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      return A11y.Results.Ok;
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Admit_Native_Identity;

   function Admit_Native_Identity_Access
     (Request   : not null Boundary_Request_Access;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Native_Node_Component : Natural)
      return A11y.Results.Result
   is
      Result : A11y.Results.Result;
      Expected : constant A11y.Node_Ids.Node_Id :=
        Primary_Node_Access (Request, Snapshots);
      Resolved : A11y.Node_Ids.Node_Id;
   begin
      if not A11y.Node_Ids.Is_Valid (Expected) then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      Resolved := A11y.Native_Identity.Node_From_Runtime_Identifier_Component
        (Snapshots.Fragment.Session, Native_Node_Component, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      elsif Resolved /= Expected then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      return A11y.Results.Ok;
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Admit_Native_Identity_Access;

   function Admit_Native_Payload
     (Request   : Boundary_Request;
      Snapshots : A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle)
      return A11y.Results.Result
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Snapshots.Limits);
   begin
      if A11y.Results.Failed (Validation) then
         return Validation;
      end if;

      if Request.Kind = Get_Text_Edit
        and then A11y.Resource_Limits.Exceeded
          (Snapshots.Limits,
           A11y.Resource_Limits.Native_String_Size,
           Ada.Strings.Wide_Wide_Unbounded.Length (Request.Replacement))
      then
         return (Status => A11y.Results.Resource_Limit);
      end if;

      return A11y.Results.Ok;
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Admit_Native_Payload;

   function Admit_Native_Payload_Access
     (Request   : not null Boundary_Request_Access;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle)
      return A11y.Results.Result
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Snapshots.Limits);
   begin
      if A11y.Results.Failed (Validation) then
         return Validation;
      end if;

      if Request.Kind = Get_Text_Edit
        and then A11y.Resource_Limits.Exceeded
          (Snapshots.Limits,
           A11y.Resource_Limits.Native_String_Size,
           Ada.Strings.Wide_Wide_Unbounded.Length (Request.Replacement))
      then
         return (Status => A11y.Results.Resource_Limit);
      end if;

      return A11y.Results.Ok;
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Admit_Native_Payload_Access;

   function Dispatch_Request
     (Request   : Boundary_Request;
      Snapshots : A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle)
      return Boundary_Reply
   is
      Admission : A11y.Results.Result;
      Routed : A11y.Windows_Backend.UIA_Request_Router.Routed_Reply;
   begin
      Admission := Admit_Native_Identity (Request, Snapshots);
      if A11y.Results.Failed (Admission) then
         return Reply (Provider_Error, Admission.Status);
      end if;

      Admission := Admit_Native_Payload (Request, Snapshots);
      if A11y.Results.Failed (Admission) then
         return Reply (Provider_Error, Admission.Status);
      end if;

      if Request.Kind = Get_Fragment_From_Point then
         declare
            Effective_Snapshots :
              A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle :=
                Snapshots;
         begin
            Effective_Snapshots.Fragment.Hit_Test_Point :=
              Request.Hit_Test_Point;
            Routed := A11y.Windows_Backend.UIA_Request_Router.Dispatch
              (Router_Request (Request), Effective_Snapshots);
         end;
      else
         Routed := A11y.Windows_Backend.UIA_Request_Router.Dispatch
           (Router_Request (Request), Snapshots);
      end if;

      if Routed.Kind = A11y.Windows_Backend.UIA_Request_Router.Routed_Error then
         if Routed.Status = A11y.Results.Unsupported_Property
           or else Routed.Status = A11y.Results.Unsupported_Capability
           or else Routed.Status = A11y.Results.Unsupported_Action
         then
            return Reply (Provider_Not_Supported, Routed.Status, Routed);
         end if;

         return Reply (Provider_Error, Routed.Status, Routed);
      elsif Routed.Kind =
        A11y.Windows_Backend.UIA_Request_Router.Property_Not_Supported
        or else Routed.Kind =
          A11y.Windows_Backend.UIA_Request_Router.Relation_Not_Supported
      then
         return Reply (Provider_Not_Supported, Routed.Status, Routed);
      end if;

      return Reply
        (Provider_Reply, Routed.Status, Routed, Native_Object_For (Routed));
   exception
      when others =>
         return Reply (Provider_Error, A11y.Results.Internal_Error);
   end Dispatch_Request;

   function Dispatch_Native_Request
     (Request   : Boundary_Request;
      Snapshots : A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle)
      return Boundary_Reply
   is
   begin
      if not Request.Has_Native_Identity then
         return Reply (Provider_Error, A11y.Results.Invalid_Argument);
      end if;

      return Dispatch_Request (Request, Snapshots);
   exception
      when others =>
         return Reply (Provider_Error, A11y.Results.Internal_Error);
   end Dispatch_Native_Request;

   function Dispatch_Registered_Native_Request
     (Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Provider  : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Request   : Boundary_Request;
      Snapshots : A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle)
      return Boundary_Reply
   is
      Report : Registered_Native_Request_Report;
   begin
      return Dispatch_Registered_Native_Request_With_Report
        (Registry, Session, Provider, Requested, Request, Snapshots, Report);
   end Dispatch_Registered_Native_Request;

   function Dispatch_Registered_Native_Request_With_Report
     (Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Provider  : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Request   : Boundary_Request;
      Snapshots : A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : out Registered_Native_Request_Report)
      return Boundary_Reply
   is
      Snapshot_Copy :
        aliased A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle :=
          Snapshots;
      Request_Copy : aliased Boundary_Request := Request;
   begin
      return Dispatch_Registered_Native_Request_With_Report_Access
        (Registry, Session, Provider, Requested, Request_Copy'Unchecked_Access,
         Snapshot_Copy'Access, Report);
   end Dispatch_Registered_Native_Request_With_Report;

   function Dispatch_Registered_Native_Request_With_Report_Access
     (Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Provider  : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Request   : not null Boundary_Request_Access;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : out Registered_Native_Request_Report)
      return Boundary_Reply
   is
      Reply_Item : Boundary_Reply;
   begin
      Dispatch_Registered_Native_Request_Into_Access
        (Registry, Session, Provider, Requested, Request, Snapshots, Report,
         Reply_Item);
      return Reply_Item;
   end Dispatch_Registered_Native_Request_With_Report_Access;

   function Dispatch_Routed_Request_Access
     (Request   : not null Boundary_Request_Access;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle)
      return A11y.Windows_Backend.UIA_Request_Router.Routed_Reply
   is
   begin
      if Request.Kind = Get_Fragment_From_Point then
         declare
            type Snapshot_Bundle_Access is access
              A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
            procedure Free is new Ada.Unchecked_Deallocation
              (A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle,
               Snapshot_Bundle_Access);
            Effective_Snapshots : Snapshot_Bundle_Access :=
              new A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle'
                (Snapshots.all);
            Routed :
              A11y.Windows_Backend.UIA_Request_Router.Routed_Reply;
         begin
            Effective_Snapshots.Fragment.Hit_Test_Point :=
              Request.Hit_Test_Point;
            Routed := A11y.Windows_Backend.UIA_Request_Router.Dispatch
              (Router_Request (Request.all), Effective_Snapshots.all);
            Free (Effective_Snapshots);
            return Routed;
         exception
            when others =>
               Free (Effective_Snapshots);
               return
                 (Kind   => A11y.Windows_Backend.UIA_Request_Router
                              .Routed_Error,
                  Status => A11y.Results.Internal_Error);
         end;
      end if;

      return A11y.Windows_Backend.UIA_Request_Router.Dispatch
        (Router_Request (Request.all), Snapshots.all);
   exception
      when others =>
         return
           (Kind   => A11y.Windows_Backend.UIA_Request_Router.Routed_Error,
            Status => A11y.Results.Internal_Error);
   end Dispatch_Routed_Request_Access;

   procedure Dispatch_Registered_Native_Request_Into_Access
     (Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Provider  : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Request   : not null Boundary_Request_Access;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : in out Registered_Native_Request_Report;
      Reply_Out : in out Boundary_Reply)
   is
      Report_Copy : aliased Registered_Native_Request_Report;
   begin
      Dispatch_Registered_Native_Request_Into_Report_Access
        (Registry,
         Session,
         Provider,
         Requested,
         Request,
         Snapshots,
         Report_Copy'Unchecked_Access,
         Reply_Out);
      Report := Report_Copy;
   end Dispatch_Registered_Native_Request_Into_Access;

   procedure Dispatch_Registered_Native_Request_Into_Report_Access
     (Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Provider  : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Request   : not null Boundary_Request_Access;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : not null Registered_Native_Request_Report_Access;
      Reply_Out : in out Boundary_Reply)
   is
      Reply_Copy : aliased Boundary_Reply := Reply_Out;
   begin
      Dispatch_Registered_Native_Request_Full_Access
        (Registry,
         Session,
         Provider,
         Requested,
         Request,
         Snapshots,
         Report,
         Reply_Copy'Unchecked_Access);
      Reply_Out := Reply_Copy;
   end Dispatch_Registered_Native_Request_Into_Report_Access;

   procedure Dispatch_Registered_Native_Request_Full_Access
     (Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Provider  : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Request   : not null Boundary_Request_Access;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : not null Registered_Native_Request_Report_Access;
      Reply_Out : not null Boundary_Reply_Access)
   is
   begin
      Report.all := (others => <>);
      Report.all.Requested_Interface := Requested;
      Report.all.Request_Kind := Request.Kind;
      Report.all.Boundary_Stage := 10;

      if not Interface_Supports_Request (Requested, Request.Kind) then
         Reply_Out.all := Reply
           (Provider_Not_Supported, A11y.Results.Unsupported_Capability);
         Record_Final_Reply (Report.all, Reply_Out.all);
         return;
      end if;
      Report.all.Interface_Supported := True;
      Report.all.Boundary_Stage := 20;

      declare
         type Provider_Record_Snapshot_Access is access
           A11y.Windows_Backend.UIA_Provider_Registry
             .Provider_Record_Snapshot;
         type Provider_Call_Context_Access is access
           A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
         procedure Free is new Ada.Unchecked_Deallocation
           (A11y.Windows_Backend.UIA_Provider_Registry
              .Provider_Record_Snapshot,
            Provider_Record_Snapshot_Access);
         procedure Free is new Ada.Unchecked_Deallocation
           (A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context,
            Provider_Call_Context_Access);
         Registered : Provider_Record_Snapshot_Access :=
           new A11y.Windows_Backend.UIA_Provider_Registry
             .Provider_Record_Snapshot;
         Context : Provider_Call_Context_Access :=
           new A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
         Result : A11y.Results.Result;
         End_Result : A11y.Results.Result;
         Native_Node_Component : Natural := 0;
         Call_Admitted : Boolean := False;
         procedure Cleanup is
         begin
            Free (Registered);
            Free (Context);
         end Cleanup;
      begin
      Report.all.Boundary_Stage := 30;
      A11y.Windows_Backend.UIA_Provider_Registry.Resolve_Provider
        (Registry, Session, Provider, Registered.all, Result);
      if A11y.Results.Failed (Result) then
         Reply_Out.all := Reply (Provider_Error, Result.Status);
         Record_Final_Reply (Report.all, Reply_Out.all);
         Cleanup;
         return;
      end if;
      Report.all.Resolved := True;
      Report.all.Resolved_Node := Registered.all.Provider.Node;
      Report.all.Resolved_Root := Registered.all.Provider.Root;
      Report.all.Boundary_Stage := 40;

      Native_Node_Component :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Session, Registered.all.Provider.Node, Result);
      if A11y.Results.Failed (Result) then
         Reply_Out.all := Reply (Provider_Error, Result.Status);
         Record_Final_Reply (Report.all, Reply_Out.all);
         Cleanup;
         return;
      end if;
      Report.all.Native_Node_Component := Native_Node_Component;
      Report.all.Native_Identity_Prepared := True;
      Report.all.Boundary_Stage := 50;

      Result :=
        Admit_Native_Identity_Access
          (Request, Snapshots, Native_Node_Component);
      if A11y.Results.Failed (Result) then
         Reply_Out.all := Reply (Provider_Error, Result.Status);
         Record_Final_Reply (Report.all, Reply_Out.all);
         Cleanup;
         return;
      end if;
      Report.all.Boundary_Stage := 60;

      Result := Admit_Native_Payload_Access (Request, Snapshots);
      if A11y.Results.Failed (Result) then
         Reply_Out.all := Reply (Provider_Error, Result.Status);
         Record_Final_Reply (Report.all, Reply_Out.all);
         Cleanup;
         return;
      end if;
      Report.all.Boundary_Stage := 70;

      A11y.Windows_Backend.UIA_Provider_Registry.Begin_Native_Call_With_Report
         (Registry,
          Session,
          Provider,
          Requested,
          Context.all,
          Report.all.Begin_Report,
         Result);
      if A11y.Results.Failed (Result) then
         Reply_Out.all := Reply (Provider_Error, Result.Status);
         Record_Final_Reply (Report.all, Reply_Out.all);
         Cleanup;
         return;
      end if;
      Call_Admitted := True;
      Report.all.Native_Admitted := True;
      Report.all.Boundary_Stage := 80;

         declare
            Routed : A11y.Windows_Backend.UIA_Request_Router.Routed_Reply;
         begin
            Report.all.Boundary_Stage := 90;
            Routed := Dispatch_Routed_Request_Access (Request, Snapshots);
            Report.all.Boundary_Stage := 100;

            if Routed.Kind =
              A11y.Windows_Backend.UIA_Request_Router.Routed_Error
            then
               if Routed.Status = A11y.Results.Unsupported_Property
                 or else Routed.Status = A11y.Results.Unsupported_Capability
                 or else Routed.Status = A11y.Results.Unsupported_Action
               then
                  Reply_Out.all :=
                    Reply (Provider_Not_Supported, Routed.Status, Routed);
               else
                  Reply_Out.all :=
                    Reply (Provider_Error, Routed.Status, Routed);
               end if;
            elsif Routed.Kind =
              A11y.Windows_Backend.UIA_Request_Router.Property_Not_Supported
              or else Routed.Kind =
                A11y.Windows_Backend.UIA_Request_Router.Relation_Not_Supported
            then
               Reply_Out.all :=
                 Reply (Provider_Not_Supported, Routed.Status, Routed);
            else
               Reply_Out.all :=
                 Reply
                   (Provider_Reply,
                    Routed.Status,
                    Routed,
                    Native_Object_For (Routed));
            end if;
            Report.all.Boundary_Stage := 110;
         exception
            when others =>
               Report.all.Boundary_Stage := 901;
               Reply_Out.all :=
                 Reply (Provider_Error, A11y.Results.Internal_Error);
         end;
      Report.all.Reply_Status := Reply_Out.all.Status;
      Report.all.Boundary_Stage := 120;

      A11y.Windows_Backend.UIA_Provider_Registry.End_Native_Call_With_Report
        (Registry,
         Session,
         Provider,
         Context.all,
         Report.all.End_Report,
         End_Result);
      Call_Admitted := False;
      if A11y.Results.Failed (End_Result) then
         Reply_Out.all := Reply (Provider_Error, End_Result.Status);
         Record_Final_Status (Report.all, Reply_Out.all.Status);
         Cleanup;
         return;
      end if;
      Report.all.Native_Completed := True;
      Report.all.Boundary_Stage := 130;

      Record_Final_Status (Report.all, Reply_Out.all.Status);
      Report.all.Boundary_Stage := 140;
      Cleanup;
      return;
      exception
         when others =>
            if Report.all.Boundary_Stage = 0 then
               Report.all.Boundary_Stage := 999;
            end if;
            if Call_Admitted then
               begin
                  A11y.Windows_Backend.UIA_Provider_Registry
                    .End_Native_Call_With_Report
                      (Registry,
                       Session,
                       Provider,
                       Context.all,
                       Report.all.End_Report,
                       End_Result);
               exception
                  when others =>
                     null;
               end;
            end if;
            Report.all.Reply_Status := A11y.Results.Internal_Error;
            Record_Final_Status (Report.all, A11y.Results.Internal_Error);
            Reply_Out.all :=
              Reply (Provider_Error, A11y.Results.Internal_Error);
            Cleanup;
            return;
      end;
   exception
      when others =>
         if Report.all.Boundary_Stage = 0 then
            Report.all.Boundary_Stage := 999;
         end if;
         Report.all.Reply_Status := A11y.Results.Internal_Error;
         Record_Final_Status (Report.all, A11y.Results.Internal_Error);
         Reply_Out.all := Reply (Provider_Error, A11y.Results.Internal_Error);
         return;
   end Dispatch_Registered_Native_Request_Full_Access;

end A11y.Windows_Backend.UIA_Provider_Boundary;
