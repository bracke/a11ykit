with A11y.Native_Boundary_Calls;
with A11y.MacOS_Backend.NSAccessibility_Elements;

package body A11y.MacOS_Backend.NSAccessibility_Provider_Boundary is
   use type A11y.Results.Status_Code;
   use type A11y.Node_Ids.Node_Id;
   use type
     A11y.MacOS_Backend.NSAccessibility_Request_Router.Routed_Reply_Kind;

   function Native_Status_For
     (Status : A11y.Results.Status_Code)
      return Native_Status is
     (case A11y.Native_Boundary_Calls.Return_Class (Status) is
        when A11y.Native_Boundary_Calls.Return_Success =>
          Native_Success,
        when A11y.Native_Boundary_Calls.Return_Unsupported =>
          Native_Not_Applicable,
        when A11y.Native_Boundary_Calls.Return_Unavailable |
             A11y.Native_Boundary_Calls.Return_Shutting_Down =>
          Native_Element_Unavailable,
        when A11y.Native_Boundary_Calls.Return_Invalid_Argument =>
          Native_Invalid_Argument,
        when A11y.Native_Boundary_Calls.Return_Permission_Denied =>
          Native_Permission_Denied,
        when A11y.Native_Boundary_Calls.Return_Resource_Limit =>
          Native_Out_Of_Resources,
        when A11y.Native_Boundary_Calls.Return_Disabled |
             A11y.Native_Boundary_Calls.Return_Invalid_State |
             A11y.Native_Boundary_Calls.Return_Read_Only |
             A11y.Native_Boundary_Calls.Return_Busy |
             A11y.Native_Boundary_Calls.Return_Timed_Out |
             A11y.Native_Boundary_Calls.Return_Cancelled =>
          Native_Busy,
        when A11y.Native_Boundary_Calls.Return_Protocol_Failure |
             A11y.Native_Boundary_Calls.Return_Native_Failure |
             A11y.Native_Boundary_Calls.Return_Internal_Error =>
          Native_Failed);

   function Status_For_Native_Status
     (Status : Native_Status)
      return A11y.Results.Status_Code is
     (case Status is
        when Native_Success =>
          A11y.Results.Success,
        when Native_Not_Applicable =>
          A11y.Results.Unsupported_Capability,
        when Native_No_Value =>
          A11y.Results.Unsupported_Property,
        when Native_Element_Unavailable =>
          A11y.Results.Node_Unavailable,
        when Native_Invalid_Argument =>
          A11y.Results.Invalid_Argument,
        when Native_Permission_Denied =>
          A11y.Results.Permission_Denied,
        when Native_Out_Of_Resources =>
          A11y.Results.Resource_Limit,
        when Native_Busy =>
          A11y.Results.Busy,
        when Native_Failed =>
          A11y.Results.Internal_Error);

   function Native_Status_Name (Status : Native_Status) return String is
     (case Status is
        when Native_Success =>
          "success",
        when Native_Not_Applicable =>
          "not-applicable",
        when Native_No_Value =>
          "no-value",
        when Native_Element_Unavailable =>
          "element-unavailable",
        when Native_Invalid_Argument =>
          "invalid-argument",
        when Native_Permission_Denied =>
          "permission-denied",
        when Native_Out_Of_Resources =>
          "out-of-resources",
        when Native_Busy =>
          "busy",
        when Native_Failed =>
          "failed");

   function Diagnostic_For_Native_Status
     (Status : Native_Status;
      Result : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic
   is
   begin
      return Diagnostic_For_Native_Status
        (Status, A11y.Resource_Limits.Default_Config, Result);
   end Diagnostic_For_Native_Status;

   function Diagnostic_For_Native_Status
     (Status : Native_Status;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic
   is
      Item : A11y.Diagnostics.Diagnostic;
      Semantic_Status : constant A11y.Results.Status_Code :=
        Status_For_Native_Status (Status);
   begin
      A11y.Diagnostics.Create_For_Status
        (Identifier => "macos.nsaccessibility.native_status",
         Status     => Semantic_Status,
         Item       => Item,
         Result     => Result,
         Feature    => "macos.nsaccessibility.native_status_diagnostic",
         Redacted   => True);
      if A11y.Results.Failed (Result) then
         return Item;
      end if;

      A11y.Diagnostics.Add_Field
        (Item,
         "native_status_name",
         Native_Status_Name (Status),
         Limits,
         Result,
         Redacted => False);
      if A11y.Results.Failed (Result) then
         return Item;
      end if;

      A11y.Diagnostics.Add_Field
        (Item,
         "native_status",
         Native_Status'Image (Status),
         Limits,
         Result,
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
   end Diagnostic_For_Native_Status;

   function Reply
     (Kind   : Boundary_Reply_Kind;
      Status : A11y.Results.Status_Code;
      Routed :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Routed_Reply_Kind :=
          A11y.MacOS_Backend.NSAccessibility_Request_Router.Routed_Error;
      Native_Object : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object)
      return Boundary_Reply is
     (Kind          => Kind,
      Native_Result => Native_Status_For (Status),
      Status        => Status,
      Routed        => Routed,
      Payload       =>
        (Kind =>
           A11y.MacOS_Backend.NSAccessibility_Request_Router.Routed_Error,
         Status => Status),
      Native_Object => Native_Object);

   function Reply
     (Kind   : Boundary_Reply_Kind;
      Status : A11y.Results.Status_Code;
      Payload :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Routed_Reply;
      Native_Object : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object)
      return Boundary_Reply is
     (Kind          => Kind,
      Native_Result => Native_Status_For (Status),
      Status        => Status,
      Routed        => Payload.Kind,
      Payload       => Payload,
      Native_Object => Native_Object);

   function Router_Request
     (Request : Boundary_Request)
      return A11y.MacOS_Backend.NSAccessibility_Request_Router.Request
   is
      Kind :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Request_Kind;
      Relation : A11y.Relations.Relation_Kind := Request.Relation;
   begin
      case Request.Kind is
         when Copy_Attribute_Names =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router
                .Attribute_Names_Query;
            Relation := A11y.Relations.Labelled_By;
         when Copy_Attribute_Value =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Attribute_Query;
            Relation := A11y.Relations.Labelled_By;
         when Is_Attribute_Settable =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router
                .Attribute_Settable_Query;
            Relation := A11y.Relations.Labelled_By;
         when Copy_Action_Names =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Action_Set_Query;
            Relation := A11y.Relations.Labelled_By;
         when Perform_Action =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Action_Request_Query;
            Relation := A11y.Relations.Labelled_By;
         when Copy_Parent =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Parent_Query;
            Relation := A11y.Relations.Labelled_By;
         when Copy_Children =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Children_Query;
            Relation := A11y.Relations.Labelled_By;
         when Copy_Child_At_Index =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Child_At_Query;
            Relation := A11y.Relations.Labelled_By;
         when Copy_Element_Id =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Element_Id_Query;
            Relation := A11y.Relations.Labelled_By;
         when Copy_Relation_Targets =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Relation_Query;
         when Copy_Value =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Value_Query;
         when Set_Value =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Value_Set_Query;
         when Copy_Selection =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Selection_Query;
         when Set_Selection =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Selection_Request_Query;
         when Copy_Text =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Text_Query;
         when Edit_Text =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Text_Edit_Query;
         when Copy_Table =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Table_Query;
         when Copy_Image =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Image_Query;
         when Copy_Document =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Document_Query;
         when Copy_Live_Region =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Live_Region_Query;
         when Copy_Surface =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Surface_Query;
         when Post_Notification =>
            Kind :=
              A11y.MacOS_Backend.NSAccessibility_Request_Router.Notification_Query;
            Relation := A11y.Relations.Labelled_By;
      end case;

      return
        (Kind        => Kind,
         Attribute   => Request.Attribute,
         Action      => Request.Action,
         Child_Index => Request.Child_Index,
         Relation    => Relation,
         Value       => Request.Value,
         Requested_Value => Request.Requested_Value,
         Selection   => Request.Selection,
         Selection_Request => Request.Selection_Request,
         Selection_Target => Request.Selection_Target,
         Text        => Request.Text,
         Text_Edit   => Request.Text_Edit,
         Table       => Request.Table,
         Image       => Request.Image,
         Document    => Request.Document,
         Live_Region => Request.Live_Region,
         Surface     => Request.Surface,
         Index       => Request.Index,
         Count       => Request.Count,
         Replacement => Request.Replacement,
         Row         => Request.Row,
         Column      => Request.Column,
         Event       => Request.Event,
         Use_Prepared_Event => Request.Use_Prepared_Event,
         Prepared_Event => Request.Prepared_Event);
   end Router_Request;

   function Native_Object_For
     (Routed : A11y.MacOS_Backend.NSAccessibility_Request_Router.Routed_Reply)
      return A11y.Native_Object_Caches.Native_Object_Id is
   begin
      if Routed.Kind =
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Notification
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

   function Method_Family_Supports_Request
     (Family  : Native_Method_Family;
      Request : Native_Request_Kind)
      return Boolean is
   begin
      case Family is
         when Any_Method =>
            return True;
         when Attribute_Method =>
            return Request in
              Copy_Attribute_Names |
              Copy_Attribute_Value |
              Is_Attribute_Settable |
              Copy_Relation_Targets;
         when Action_Method =>
            return Request in Copy_Action_Names | Perform_Action;
         when Hierarchy_Method =>
            return Request in
              Copy_Parent |
              Copy_Children |
              Copy_Child_At_Index |
              Copy_Element_Id;
         when Value_Method =>
            return Request in Copy_Value | Set_Value;
         when Selection_Method =>
            return Request in Copy_Selection | Set_Selection;
         when Text_Method =>
            return Request in Copy_Text | Edit_Text;
         when Table_Method =>
            return Request = Copy_Table;
         when Image_Method =>
            return Request = Copy_Image;
         when Document_Method =>
            return Request = Copy_Document;
         when Live_Region_Method =>
            return Request = Copy_Live_Region;
         when Surface_Method =>
            return Request = Copy_Surface;
         when Notification_Method =>
            return Request = Post_Notification;
      end case;
   end Method_Family_Supports_Request;

   function Effective_Event_Source
     (Request : Boundary_Request)
      return A11y.Node_Ids.Node_Id is
     (if Request.Use_Prepared_Event then
        Request.Prepared_Event.Event.Source
      else
        Request.Event.Source);

   function Primary_Node
     (Request   : Boundary_Request;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle)
      return A11y.Node_Ids.Node_Id is
   begin
      case Request.Kind is
         when Copy_Attribute_Names |
              Copy_Attribute_Value |
              Is_Attribute_Settable =>
            return Snapshots.Properties.Id;
         when Copy_Action_Names | Perform_Action =>
            return Snapshots.Action_Node;
         when Copy_Parent | Copy_Children | Copy_Child_At_Index |
              Copy_Element_Id =>
            return Snapshots.Hierarchy.Node;
         when Copy_Relation_Targets =>
            return Snapshots.Relation_Source;
         when Copy_Value | Set_Value =>
            return Snapshots.Value.Id;
         when Copy_Selection =>
            return Snapshots.Selection.Item;
         when Set_Selection =>
            return
              (if A11y.Node_Ids.Is_Valid (Request.Selection_Target)
               then Request.Selection_Target
               else Snapshots.Selection.Root);
         when Copy_Text | Edit_Text =>
            return Snapshots.Text.Id;
         when Copy_Table =>
            return Snapshots.Table.Id;
         when Copy_Image =>
            return Snapshots.Image.Id;
         when Copy_Document =>
            return Snapshots.Document.Id;
         when Copy_Live_Region =>
            return Snapshots.Live_Region.Id;
         when Copy_Surface =>
            return Snapshots.Surface.Id;
         when Post_Notification =>
            return Effective_Event_Source (Request);
      end case;
   end Primary_Node;

   function Admit_Native_Identity
     (Request   : Boundary_Request;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle)
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
        (Snapshots.Hierarchy.Session, Request.Native_Node_Component, Result);
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

   function Admit_Native_Payload
     (Request   : Boundary_Request;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle)
      return A11y.Results.Result
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Snapshots.Limits);
   begin
      if A11y.Results.Failed (Validation) then
         return Validation;
      end if;

      if Request.Kind = Edit_Text
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

   function Dispatch_Request
     (Request   : Boundary_Request;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle)
      return Boundary_Reply
   is
      Admission : A11y.Results.Result;
      Routed : A11y.MacOS_Backend.NSAccessibility_Request_Router.Routed_Reply;
   begin
      Admission := Admit_Native_Identity (Request, Snapshots);
      if A11y.Results.Failed (Admission) then
         return Reply (Native_Error, Admission.Status);
      end if;

      Admission := Admit_Native_Payload (Request, Snapshots);
      if A11y.Results.Failed (Admission) then
         return Reply (Native_Error, Admission.Status);
      end if;

      Routed := A11y.MacOS_Backend.NSAccessibility_Request_Router.Dispatch
        (Router_Request (Request), Snapshots);

      if Routed.Kind =
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Routed_Error
      then
         if Routed.Status = A11y.Results.Unsupported_Property
           or else Routed.Status = A11y.Results.Unsupported_Capability
           or else Routed.Status = A11y.Results.Unsupported_Action
         then
            return Reply (Native_Nil, Routed.Status, Routed);
         end if;

         return Reply (Native_Error, Routed.Status, Routed);
      elsif Routed.Kind =
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Attribute_Not_Supported
        or else Routed.Kind =
          A11y.MacOS_Backend.NSAccessibility_Request_Router.Hierarchy_Empty
        or else Routed.Kind =
          A11y.MacOS_Backend.NSAccessibility_Request_Router.Relation_Not_Supported
      then
         return Reply (Native_Nil, Routed.Status, Routed);
      end if;

      return Reply
        (Native_Reply, Routed.Status, Routed, Native_Object_For (Routed));
   exception
      when others =>
         return Reply (Native_Error, A11y.Results.Internal_Error);
   end Dispatch_Request;

   function Dispatch_Native_Request
     (Request   : Boundary_Request;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle)
      return Boundary_Reply
   is
   begin
      if not Request.Has_Native_Identity then
         return Reply (Native_Error, A11y.Results.Invalid_Argument);
      end if;

      return Dispatch_Request (Request, Snapshots);
   exception
      when others =>
         return Reply (Native_Error, A11y.Results.Internal_Error);
   end Dispatch_Native_Request;

   function Dispatch_Registered_Native_Request
     (Registry  :
        in out A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Element   :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Id;
      Request   : Boundary_Request;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      Require_Main_Thread : Boolean := False;
      Method_Family : Native_Method_Family := Any_Method)
      return Boundary_Reply
   is
      Report : Registered_Native_Request_Report;
   begin
      return Dispatch_Registered_Native_Request_With_Report
        (Registry, Session, Element, Request, Snapshots, Report,
         Require_Main_Thread, Method_Family);
   end Dispatch_Registered_Native_Request;

   function Dispatch_Registered_Native_Request_With_Report
     (Registry  :
        in out A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Element   :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Id;
      Request   : Boundary_Request;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      Report    : out Registered_Native_Request_Report;
      Require_Main_Thread : Boolean := False;
      Method_Family : Native_Method_Family := Any_Method)
      return Boundary_Reply
   is
      Registered :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Record_Snapshot;
      Context :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Native_Request : Boundary_Request := Request;
      Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Reply_Item : Boundary_Reply;
      Call_Admitted : Boolean := False;
   begin
      Report := (others => <>);
      Report.Method_Family := Method_Family;
      Report.Request_Kind := Request.Kind;

      if not Method_Family_Supports_Request (Method_Family, Request.Kind) then
         Reply_Item := Reply
           (Native_Nil, A11y.Results.Unsupported_Capability);
         Record_Final_Reply (Report, Reply_Item);
         return Reply_Item;
      end if;
      Report.Method_Family_Supported := True;

      A11y.MacOS_Backend.NSAccessibility_Element_Registry.Resolve_Element
        (Registry, Session, Element, Registered, Result);
      if A11y.Results.Failed (Result) then
         Reply_Item := Reply (Native_Error, Result.Status);
         Record_Final_Reply (Report, Reply_Item);
         return Reply_Item;
      end if;
      Report.Resolved := True;
      Report.Resolved_Node := Registered.Element.Node;
      Report.Resolved_Root := Registered.Element.Root;

      Native_Request.Has_Native_Identity := True;
      Native_Request.Native_Node_Component :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Session, Registered.Element.Node, Result);
      if A11y.Results.Failed (Result) then
         Reply_Item := Reply (Native_Error, Result.Status);
         Record_Final_Reply (Report, Reply_Item);
         return Reply_Item;
      end if;
      Report.Native_Node_Component := Native_Request.Native_Node_Component;
      Report.Native_Identity_Prepared := True;

      Result := Admit_Native_Identity (Native_Request, Snapshots);
      if A11y.Results.Failed (Result) then
         Reply_Item := Reply (Native_Error, Result.Status);
         Record_Final_Reply (Report, Reply_Item);
         return Reply_Item;
      end if;

      Result := Admit_Native_Payload (Native_Request, Snapshots);
      if A11y.Results.Failed (Result) then
         Reply_Item := Reply (Native_Error, Result.Status);
         Record_Final_Reply (Report, Reply_Item);
         return Reply_Item;
      end if;

      A11y.MacOS_Backend.NSAccessibility_Element_Registry
        .Begin_Native_Call_With_Report
          (Registry, Session, Element, Context, Report.Begin_Report, Result,
           Require_Main_Thread);
      if A11y.Results.Failed (Result) then
         Reply_Item := Reply (Native_Error, Result.Status);
         Record_Final_Reply (Report, Reply_Item);
         return Reply_Item;
      end if;
      Call_Admitted := True;
      Report.Native_Admitted := True;

      Reply_Item := Dispatch_Native_Request (Native_Request, Snapshots);
      Report.Reply_Status := Reply_Item.Status;

      A11y.MacOS_Backend.NSAccessibility_Element_Registry
        .End_Native_Call_With_Report
          (Registry, Session, Element, Context, Report.End_Report, End_Result);
      Call_Admitted := False;
      if A11y.Results.Failed (End_Result) then
         Reply_Item := Reply (Native_Error, End_Result.Status);
         Record_Final_Status (Report, Reply_Item.Status);
         return Reply_Item;
      end if;
      Report.Native_Completed := True;

      Record_Final_Status (Report, Reply_Item.Status);
      return Reply_Item;
   exception
      when others =>
         if Call_Admitted then
            A11y.MacOS_Backend.NSAccessibility_Element_Registry
              .End_Native_Call_With_Report
                (Registry, Session, Element, Context, Report.End_Report,
                 End_Result);
         end if;
         Record_Final_Status (Report, A11y.Results.Internal_Error);
         return Reply (Native_Error, A11y.Results.Internal_Error);
   end Dispatch_Registered_Native_Request_With_Report;

end A11y.MacOS_Backend.NSAccessibility_Provider_Boundary;
