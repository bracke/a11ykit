package body A11y.MacOS_Backend.NSAccessibility_ABI_Surface is

   use type A11y.Results.Status_Code;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;

   package Boundary renames
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary;
   package Bridge renames
     A11y.MacOS_Backend.NSAccessibility_Bridge_Audit;
   package Registry renames
     A11y.MacOS_Backend.NSAccessibility_Element_Registry;
   package Properties renames
     A11y.MacOS_Backend.NSAccessibility_Properties;

   function Descriptor
     (Selector : NSAX_Selector)
      return Selector_Descriptor
   is
      package Boundary renames
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary;
   begin
      return
        (case Selector is
           when Accessibility_Attribute_Names =>
             (Supported => True,
              Method_Family => Boundary.Attribute_Method,
              Request_Kind => Boundary.Copy_Attribute_Names,
              Requires_Native_Identity => True,
              Requires_Main_Thread => True,
              Status => A11y.Results.Success),
           when Accessibility_Attribute_Value =>
             (Supported => True,
              Method_Family => Boundary.Attribute_Method,
              Request_Kind => Boundary.Copy_Attribute_Value,
              Requires_Native_Identity => True,
              Requires_Main_Thread => True,
              Status => A11y.Results.Success),
           when Accessibility_Is_Attribute_Settable =>
             (Supported => True,
              Method_Family => Boundary.Attribute_Method,
              Request_Kind => Boundary.Is_Attribute_Settable,
              Requires_Native_Identity => True,
              Requires_Main_Thread => True,
              Status => A11y.Results.Success),
           when Accessibility_Set_Value =>
             (Supported => True,
              Method_Family => Boundary.Value_Method,
              Request_Kind => Boundary.Set_Value,
              Requires_Native_Identity => True,
              Requires_Main_Thread => True,
              Status => A11y.Results.Success),
           when Accessibility_Action_Names =>
             (Supported => True,
              Method_Family => Boundary.Action_Method,
              Request_Kind => Boundary.Copy_Action_Names,
              Requires_Native_Identity => True,
              Requires_Main_Thread => True,
              Status => A11y.Results.Success),
           when Accessibility_Perform_Action =>
             (Supported => True,
              Method_Family => Boundary.Action_Method,
              Request_Kind => Boundary.Perform_Action,
              Requires_Native_Identity => True,
              Requires_Main_Thread => True,
              Status => A11y.Results.Success),
           when Accessibility_Parent =>
             (Supported => True,
              Method_Family => Boundary.Hierarchy_Method,
              Request_Kind => Boundary.Copy_Parent,
              Requires_Native_Identity => True,
              Requires_Main_Thread => True,
              Status => A11y.Results.Success),
           when Accessibility_Children =>
             (Supported => True,
              Method_Family => Boundary.Hierarchy_Method,
              Request_Kind => Boundary.Copy_Children,
              Requires_Native_Identity => True,
              Requires_Main_Thread => True,
              Status => A11y.Results.Success),
           when Accessibility_Child_At_Index =>
             (Supported => True,
              Method_Family => Boundary.Hierarchy_Method,
              Request_Kind => Boundary.Copy_Child_At_Index,
              Requires_Native_Identity => True,
              Requires_Main_Thread => True,
              Status => A11y.Results.Success),
           when Accessibility_Hit_Test |
                Accessibility_Focused_UI_Element =>
             (Supported => True,
              Method_Family => Boundary.Hierarchy_Method,
              Request_Kind => Boundary.Copy_Element_Id,
              Requires_Native_Identity => True,
              Requires_Main_Thread => True,
              Status => A11y.Results.Success),
           when Accessibility_Post_Notification =>
             (Supported => True,
              Method_Family => Boundary.Notification_Method,
              Request_Kind => Boundary.Post_Notification,
              Requires_Native_Identity => True,
              Requires_Main_Thread => True,
              Status => A11y.Results.Success));
   end Descriptor;

   function Selector_Name (Selector : NSAX_Selector) return String is
     (case Selector is
        when Accessibility_Attribute_Names =>
          "accessibilityAttributeNames",
        when Accessibility_Attribute_Value =>
          "accessibilityAttributeValue:",
        when Accessibility_Is_Attribute_Settable =>
          "accessibilityIsAttributeSettable:",
        when Accessibility_Set_Value =>
          "accessibilitySetValue:forAttribute:",
        when Accessibility_Action_Names =>
          "accessibilityActionNames",
        when Accessibility_Perform_Action =>
          "accessibilityPerformAction:",
        when Accessibility_Parent =>
          "accessibilityParent",
        when Accessibility_Children =>
          "accessibilityChildren",
        when Accessibility_Child_At_Index =>
          "accessibilityChildAtIndex:",
        when Accessibility_Hit_Test =>
          "accessibilityHitTest:",
        when Accessibility_Focused_UI_Element =>
          "accessibilityFocusedUIElement",
        when Accessibility_Post_Notification =>
          "accessibilityPostNotification:");

   function Bridge_Entry (Selector : NSAX_Selector) return Native_Bridge_Entry
   is
      Info : constant Selector_Descriptor := Descriptor (Selector);
      Operation : constant Bridge.Bridge_Operation :=
        (if Selector = Accessibility_Post_Notification then
           Bridge.Post_Notification_Callback
         else
           Bridge.Dispatch_Selector_Frame_Callback);
   begin
      return
        (Selector   => Selector,
         Operation  => Operation,
         ABI_Only   => Bridge.Is_ABI_Only (Operation),
         Requires_Main_Thread => Info.Requires_Main_Thread,
         Dispatches_Notification => Selector = Accessibility_Post_Notification);
   end Bridge_Entry;

   function Selector_Code
     (Selector : NSAX_Selector)
      return Interfaces.Unsigned_32 is
     (case Selector is
        when Accessibility_Attribute_Names => 1,
        when Accessibility_Attribute_Value => 2,
        when Accessibility_Is_Attribute_Settable => 3,
        when Accessibility_Set_Value => 4,
        when Accessibility_Action_Names => 5,
        when Accessibility_Perform_Action => 6,
        when Accessibility_Parent => 7,
        when Accessibility_Children => 8,
        when Accessibility_Child_At_Index => 9,
        when Accessibility_Hit_Test => 10,
        when Accessibility_Focused_UI_Element => 11,
        when Accessibility_Post_Notification => 12);

   function Attribute_Code
     (Attribute : Properties.Core_Attribute)
      return Interfaces.Unsigned_32 is
     (case Attribute is
        when Properties.Role => 1,
        when Properties.Title => 2,
        when Properties.Label => 3,
        when Properties.Description => 4,
        when Properties.Help => 5,
        when Properties.Placeholder => 6,
        when Properties.Value_Text => 7,
        when Properties.Keyboard_Shortcut => 8,
        when Properties.Locale => 9,
        when Properties.Orientation => 10,
        when Properties.Position_In_Set => 11,
        when Properties.Size_Of_Set => 12,
        when Properties.Hierarchical_Level => 13,
        when Properties.Heading_Level => 14,
        when Properties.Landmark => 15,
        when Properties.Identifier => 16,
        when Properties.Frame => 17,
        when Properties.Enabled => 18,
        when Properties.Focused => 19,
        when Properties.Selected => 20,
        when Properties.Required => 21,
        when Properties.Modal => 22);

   function Attribute_From_Code
     (Code   : Interfaces.Unsigned_32;
      Result : out A11y.Results.Result)
      return Properties.Core_Attribute
   is
   begin
      Result := A11y.Results.Ok;
      case Code is
         when 1 => return Properties.Role;
         when 2 => return Properties.Title;
         when 3 => return Properties.Label;
         when 4 => return Properties.Description;
         when 5 => return Properties.Help;
         when 6 => return Properties.Placeholder;
         when 7 => return Properties.Value_Text;
         when 8 => return Properties.Keyboard_Shortcut;
         when 9 => return Properties.Locale;
         when 10 => return Properties.Orientation;
         when 11 => return Properties.Position_In_Set;
         when 12 => return Properties.Size_Of_Set;
         when 13 => return Properties.Hierarchical_Level;
         when 14 => return Properties.Heading_Level;
         when 15 => return Properties.Landmark;
         when 16 => return Properties.Identifier;
         when 17 => return Properties.Frame;
         when 18 => return Properties.Enabled;
         when 19 => return Properties.Focused;
         when 20 => return Properties.Selected;
         when 21 => return Properties.Required;
         when 22 => return Properties.Modal;
         when others =>
            Result := (Status => A11y.Results.Invalid_Argument);
            return Properties.Title;
      end case;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Properties.Title;
   end Attribute_From_Code;

   function Action_Code
     (Action : A11y.Actions.Action_Id)
      return Interfaces.Unsigned_32 is
     (case Action is
        when A11y.Actions.Activate => 1,
        when A11y.Actions.Press => 2,
        when A11y.Actions.Toggle => 3,
        when A11y.Actions.Expand => 4,
        when A11y.Actions.Collapse => 5,
        when A11y.Actions.Show_Menu => 6,
        when A11y.Actions.Dismiss => 7,
        when A11y.Actions.Increment => 8,
        when A11y.Actions.Decrement => 9,
        when A11y.Actions.Select_Item => 10,
        when A11y.Actions.Deselect => 11,
        when A11y.Actions.Clear_Selection => 12,
        when A11y.Actions.Scroll_Into_View => 13,
        when A11y.Actions.Set_Focus => 14,
        when A11y.Actions.Open => 15,
        when A11y.Actions.Close => 16);

   function Relation_Code
     (Relation : A11y.Relations.Relation_Kind)
      return Interfaces.Unsigned_32 is
     (case Relation is
        when A11y.Relations.Labelled_By => 1_001,
        when A11y.Relations.Label_For => 1_002,
        when A11y.Relations.Controlled_By => 1_003,
        when A11y.Relations.Controller_For => 1_004,
        when A11y.Relations.Flows_To => 1_005,
        when A11y.Relations.Flows_From => 1_006,
        when A11y.Relations.Member_Of => 1_007,
        when A11y.Relations.Details => 1_008,
        when A11y.Relations.Details_For => 1_009,
        when A11y.Relations.Error_Message => 1_010,
        when A11y.Relations.Error_For => 1_011,
        when A11y.Relations.Active_Descendant => 1_012,
        when A11y.Relations.Popup_For => 1_013,
        when A11y.Relations.Popup_Controlled_By => 1_014,
        when A11y.Relations.Described_By => 1_015,
        when A11y.Relations.Description_For => 1_016,
        when A11y.Relations.Embedded_By => 1_017,
        when A11y.Relations.Embeds => 1_018);

   function Relation_From_Code
     (Code   : Interfaces.Unsigned_32;
      Result : out A11y.Results.Result)
      return A11y.Relations.Relation_Kind
   is
   begin
      Result := A11y.Results.Ok;
      case Code is
         when 1_001 => return A11y.Relations.Labelled_By;
         when 1_002 => return A11y.Relations.Label_For;
         when 1_003 => return A11y.Relations.Controlled_By;
         when 1_004 => return A11y.Relations.Controller_For;
         when 1_005 => return A11y.Relations.Flows_To;
         when 1_006 => return A11y.Relations.Flows_From;
         when 1_007 => return A11y.Relations.Member_Of;
         when 1_008 => return A11y.Relations.Details;
         when 1_009 => return A11y.Relations.Details_For;
         when 1_010 => return A11y.Relations.Error_Message;
         when 1_011 => return A11y.Relations.Error_For;
         when 1_012 => return A11y.Relations.Active_Descendant;
         when 1_013 => return A11y.Relations.Popup_For;
         when 1_014 => return A11y.Relations.Popup_Controlled_By;
         when 1_015 => return A11y.Relations.Described_By;
         when 1_016 => return A11y.Relations.Description_For;
         when 1_017 => return A11y.Relations.Embedded_By;
         when 1_018 => return A11y.Relations.Embeds;
         when others =>
            Result := (Status => A11y.Results.Invalid_Argument);
            return A11y.Relations.Labelled_By;
      end case;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Relations.Labelled_By;
   end Relation_From_Code;

   function Action_From_Code
     (Code   : Interfaces.Unsigned_32;
      Result : out A11y.Results.Result)
      return A11y.Actions.Action_Id
   is
   begin
      Result := A11y.Results.Ok;
      case Code is
         when 1 => return A11y.Actions.Activate;
         when 2 => return A11y.Actions.Press;
         when 3 => return A11y.Actions.Toggle;
         when 4 => return A11y.Actions.Expand;
         when 5 => return A11y.Actions.Collapse;
         when 6 => return A11y.Actions.Show_Menu;
         when 7 => return A11y.Actions.Dismiss;
         when 8 => return A11y.Actions.Increment;
         when 9 => return A11y.Actions.Decrement;
         when 10 => return A11y.Actions.Select_Item;
         when 11 => return A11y.Actions.Deselect;
         when 12 => return A11y.Actions.Clear_Selection;
         when 13 => return A11y.Actions.Scroll_Into_View;
         when 14 => return A11y.Actions.Set_Focus;
         when 15 => return A11y.Actions.Open;
         when 16 => return A11y.Actions.Close;
         when others =>
            Result := (Status => A11y.Results.Invalid_Argument);
            return A11y.Actions.Activate;
      end case;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Actions.Activate;
   end Action_From_Code;

   function Selector_From_Code
     (Code   : Interfaces.Unsigned_32;
      Result : out A11y.Results.Result)
      return NSAX_Selector
   is
   begin
      Result := A11y.Results.Ok;
      case Code is
         when 1 => return Accessibility_Attribute_Names;
         when 2 => return Accessibility_Attribute_Value;
         when 3 => return Accessibility_Is_Attribute_Settable;
         when 4 => return Accessibility_Set_Value;
         when 5 => return Accessibility_Action_Names;
         when 6 => return Accessibility_Perform_Action;
         when 7 => return Accessibility_Parent;
         when 8 => return Accessibility_Children;
         when 9 => return Accessibility_Child_At_Index;
         when 10 => return Accessibility_Hit_Test;
         when 11 => return Accessibility_Focused_UI_Element;
         when 12 => return Accessibility_Post_Notification;
         when others =>
            Result := (Status => A11y.Results.Invalid_Argument);
            return Accessibility_Attribute_Value;
      end case;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Accessibility_Attribute_Value;
   end Selector_From_Code;

   function Can_Dispatch
     (Export :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Export_Descriptor;
      Selector : NSAX_Selector)
      return Boolean
   is
      Info : constant Selector_Descriptor := Descriptor (Selector);
   begin
      return Export.Exportable
        and then not Export.Defunct
        and then Info.Supported
        and then
          (not Info.Requires_Main_Thread or else Export.Main_Thread_Bound);
   end Can_Dispatch;

   function Prepare_Request
     (Export :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Export_Descriptor;
      Selector : NSAX_Selector;
      Result   : out A11y.Results.Result)
      return A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
        .Boundary_Request
   is
      Info : constant Selector_Descriptor := Descriptor (Selector);
      Request :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Request;
   begin
      Request.Kind := Info.Request_Kind;
      Request.Has_Native_Identity := False;
      Request.Native_Node_Component := 0;

      if not Export.Exportable or else Export.Defunct then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif not Info.Supported then
         Result := (Status => Info.Status);
      elsif Info.Requires_Main_Thread and then not Export.Main_Thread_Bound then
         Result := (Status => A11y.Results.Invalid_State);
      elsif not Can_Dispatch (Export, Selector) then
         Result := (Status => A11y.Results.Unsupported_Capability);
      else
         Request.Has_Native_Identity := Info.Requires_Native_Identity;
         if Info.Requires_Native_Identity then
            Request.Native_Node_Component := Export.Native_Node_Component;
         end if;
         Result := A11y.Results.Ok;
      end if;

      return Request;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Request;
   end Prepare_Request;

   function Fits_Natural (Code : Interfaces.Unsigned_64) return Boolean is
     (Code <= Interfaces.Unsigned_64 (Natural'Last));

   function Error_Reply
     (Status : A11y.Results.Status_Code)
      return Boundary.Boundary_Reply is
     ((Kind          => Boundary.Native_Error,
       Native_Result => Boundary.Native_Status_For (Status),
       Status        => Status,
       others        => <>));

   function Build_Selector_Frame
     (Session     : A11y.Native_Identity.Backend_Session_Id;
      Element     :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Id;
      Selector    : NSAX_Selector;
      Child_Index : Positive := 1;
      Operand_Code : Interfaces.Unsigned_32 := 0)
      return Selector_Frame is
     ((Session_Code =>
         Interfaces.Unsigned_64
           (A11y.Native_Identity.To_Natural (Session)),
       Element_Code =>
         Interfaces.Unsigned_64 (Registry.To_Natural (Element)),
       Selector_Code => Selector_Code (Selector),
       Child_Index_Code => Interfaces.Unsigned_32 (Child_Index),
       Operand_Code => Operand_Code));

   function Build_Callback_Frame
     (Session_Code  : Interfaces.Unsigned_64;
      Element_Code  : Interfaces.Unsigned_64;
      Raw_Selector_Code : Interfaces.Unsigned_32;
      Operand_Code  : Interfaces.Unsigned_32 := 0)
      return Selector_Frame
   is
      Child_Index_Code : Interfaces.Unsigned_32 := 1;
      Native_Operand   : Interfaces.Unsigned_32 := Operand_Code;
   begin
      if Raw_Selector_Code = Selector_Code (Accessibility_Child_At_Index) then
         Child_Index_Code := Operand_Code;
         Native_Operand := 0;
      end if;

      return
        (Session_Code     => Session_Code,
         Element_Code     => Element_Code,
         Selector_Code    => Raw_Selector_Code,
         Child_Index_Code => Child_Index_Code,
         Operand_Code     => Native_Operand);
   end Build_Callback_Frame;

   function Dispatch_Selector_Frame
     (Registry  :
        in out A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Element_Registry;
      Frame     : Selector_Frame;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      Report    : out Selector_Frame_Report)
      return A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
        .Boundary_Reply
   is
      Session : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Element : A11y.MacOS_Backend.NSAccessibility_Element_Registry
        .Element_Id := A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .No_Element;
      Selector : NSAX_Selector := Accessibility_Attribute_Value;
      Selector_Result : A11y.Results.Result;
      Operand_Result : A11y.Results.Result;
      Relation_Result : A11y.Results.Result;
      Request : Boundary.Boundary_Request;
      Info : Selector_Descriptor;
      Reply : Boundary.Boundary_Reply;
   begin
      Report := (others => <>);

      if not Fits_Natural (Frame.Session_Code)
        or else Frame.Session_Code = 0
      then
         Report.Status := A11y.Results.Invalid_Argument;
         Report.Native_Status := Boundary.Native_Status_For (Report.Status);
         return Error_Reply (Report.Status);
      end if;
      Session := A11y.Native_Identity.From_Natural
        (Natural (Frame.Session_Code));
      Report.Session_Code_Valid := A11y.Native_Identity.Is_Valid (Session);
      if not Report.Session_Code_Valid then
         Report.Status := A11y.Results.Node_Unavailable;
         Report.Native_Status := Boundary.Native_Status_For (Report.Status);
         return Error_Reply (Report.Status);
      end if;

      if not Fits_Natural (Frame.Element_Code)
        or else Frame.Element_Code = 0
      then
         Report.Status := A11y.Results.Invalid_Argument;
         Report.Native_Status := Boundary.Native_Status_For (Report.Status);
         return Error_Reply (Report.Status);
      end if;
      Element := A11y.MacOS_Backend.NSAccessibility_Element_Registry
        .From_Natural (Natural (Frame.Element_Code));
      Report.Element_Code_Valid :=
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Is_Valid
          (Element);
      if not Report.Element_Code_Valid then
         Report.Status := A11y.Results.Node_Unavailable;
         Report.Native_Status := Boundary.Native_Status_For (Report.Status);
         return Error_Reply (Report.Status);
      end if;

      Selector :=
        Selector_From_Code (Frame.Selector_Code, Selector_Result);
      Report.Selector_Code_Valid :=
        A11y.Results.Succeeded (Selector_Result);
      Report.Selector := Selector;
      if not Report.Selector_Code_Valid then
         Report.Status := Selector_Result.Status;
         Report.Native_Status := Boundary.Native_Status_For (Report.Status);
         return Error_Reply (Report.Status);
      end if;

      Info := Descriptor (Selector);
      if not Info.Supported then
         Report.Status := Info.Status;
         Report.Native_Status := Boundary.Native_Status_For (Report.Status);
         return Error_Reply (Report.Status);
      end if;

      Request.Kind := Info.Request_Kind;
      Request.Has_Native_Identity := False;
      if Frame.Operand_Code /= 0 then
         case Selector is
            when Accessibility_Attribute_Value |
                 Accessibility_Is_Attribute_Settable |
                 Accessibility_Set_Value =>
               if Selector = Accessibility_Attribute_Value
                 and then Frame.Operand_Code >= 1_000
               then
                  Request.Kind := Boundary.Copy_Relation_Targets;
                  Request.Relation :=
                    Relation_From_Code
                      (Frame.Operand_Code, Relation_Result);
                  Operand_Result := Relation_Result;
               else
                  Request.Attribute :=
                    Attribute_From_Code (Frame.Operand_Code, Operand_Result);
               end if;
            when Accessibility_Perform_Action =>
               Request.Action :=
                 Action_From_Code (Frame.Operand_Code, Operand_Result);
            when others =>
               Operand_Result := A11y.Results.Ok;
         end case;

         if not A11y.Results.Succeeded (Operand_Result) then
            Report.Status := Operand_Result.Status;
            Report.Native_Status := Boundary.Native_Status_For
              (Report.Status);
            return Error_Reply (Report.Status);
         end if;
      end if;
      if Selector = Accessibility_Child_At_Index then
         if Frame.Child_Index_Code = 0
           or else Frame.Child_Index_Code >
             Interfaces.Unsigned_32 (Positive'Last)
         then
            Report.Status := A11y.Results.Invalid_Argument;
            Report.Native_Status := Boundary.Native_Status_For
              (Report.Status);
            return Error_Reply (Report.Status);
         end if;
         Request.Child_Index := Positive (Frame.Child_Index_Code);
      end if;
      Report.Request_Prepared := True;

      Reply :=
        Boundary.Dispatch_Registered_Native_Request_With_Report
          (Registry,
           Session,
           Element,
           Request,
           Snapshots,
           Report.Dispatch,
           Info.Requires_Main_Thread,
           Info.Method_Family);
      Report.Status := Reply.Status;
      Report.Native_Status := Reply.Native_Result;
      return Reply;
   exception
      when others =>
         Report.Status := A11y.Results.Internal_Error;
         Report.Native_Status := Boundary.Native_Failed;
         return Error_Reply (A11y.Results.Internal_Error);
   end Dispatch_Selector_Frame;

   function Dispatch_Callback
     (Registry  :
        in out A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Element_Registry;
      Session_Code  : Interfaces.Unsigned_64;
      Element_Code  : Interfaces.Unsigned_64;
      Selector_Code : Interfaces.Unsigned_32;
      Operand_Code  : Interfaces.Unsigned_32;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      Report    : out Selector_Frame_Report)
      return A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
        .Boundary_Reply
   is
      Frame : constant Selector_Frame :=
        Build_Callback_Frame
          (Session_Code      => Session_Code,
           Element_Code      => Element_Code,
           Raw_Selector_Code => Selector_Code,
           Operand_Code      => Operand_Code);
   begin
      return Dispatch_Selector_Frame (Registry, Frame, Snapshots, Report);
   exception
      when others =>
         Report := (others => <>);
         Report.Status := A11y.Results.Internal_Error;
         Report.Native_Status := Boundary.Native_Failed;
         return Error_Reply (A11y.Results.Internal_Error);
   end Dispatch_Callback;

end A11y.MacOS_Backend.NSAccessibility_ABI_Surface;
