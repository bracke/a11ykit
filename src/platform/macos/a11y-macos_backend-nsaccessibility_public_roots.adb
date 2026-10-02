with Interfaces;

package body A11y.MacOS_Backend.NSAccessibility_Public_Roots is

   package ABI renames A11y.MacOS_Backend.NSAccessibility_ABI_Surface;
   package Registry_API renames
     A11y.MacOS_Backend.NSAccessibility_Element_Registry;

   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use type A11y.Results.Status_Code;

   procedure Export_Public_Root
     (Registry              : in out Registry_API.Element_Registry;
      Session               : A11y.Native_Identity.Backend_Session_Id;
      Root                  : A11y.Node_Ids.Node_Id;
      Node                  : A11y.Node_Ids.Node_Id;
      Report                : out Public_Root_Export_Report;
      Native_View_Component : Natural := 0)
   is
      Result : A11y.Results.Result;
      Component_Result : A11y.Results.Result;
      Expected_Component : Natural := 0;
   begin
      Report := (others => <>);
      Report.Session := Session;
      Report.Root := Root;
      Report.Node := Node;

      Registry_API.Ensure_Element_With_Report
        (Registry, Session, Root, Node, Report.Element,
         Report.Ensure_Report, Result);
      Report.Element_Ensured := A11y.Results.Succeeded (Result);
      if not Report.Element_Ensured then
         Report.Status := Result.Status;
         return;
      end if;

      Registry_API.Bind_Main_Thread
        (Registry, Session, Report.Element, Result);
      Report.Element_Main_Thread_Bound := A11y.Results.Succeeded (Result);
      if not Report.Element_Main_Thread_Bound then
         Report.Status := Result.Status;
         return;
      end if;

      if Native_View_Component /= 0 then
         Registry_API.Bind_Native_View
           (Registry, Session, Report.Element, Native_View_Component, Result);
         Report.Native_View_Bound := A11y.Results.Succeeded (Result);
         if not Report.Native_View_Bound then
            Report.Status := Result.Status;
            return;
         end if;
      else
         Report.Native_View_Bound := True;
      end if;

      Registry_API.Resolve_Element
        (Registry, Session, Report.Element, Report.Resolved_Element, Result);
      Report.Element_Resolved :=
        A11y.Results.Succeeded (Result)
        and then Report.Resolved_Element.Used
        and then not Report.Resolved_Element.Released
        and then Report.Resolved_Element.Element.Main_Thread_Bound
        and then
          (Native_View_Component = 0
           or else Report.Resolved_Element.Element.Native_View_Bound);
      if not Report.Element_Resolved then
         Report.Status := Result.Status;
         return;
      end if;

      Expected_Component :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Session, Node, Component_Result);
      Report.Native_Node_Component := Expected_Component;
      Report.Native_Node_Component_Stable :=
        A11y.Results.Succeeded (Component_Result)
        and then Expected_Component /= 0
        and then Report.Native_Node_Component = Expected_Component;

      Report.Children_Frame :=
        ABI.Build_Selector_Frame
          (Session, Report.Element, ABI.Accessibility_Children);
      Report.Children_Frame_Built :=
        Report.Children_Frame.Session_Code =
          Interfaces.Unsigned_64 (A11y.Native_Identity.To_Natural (Session))
        and then Report.Children_Frame.Element_Code =
          Interfaces.Unsigned_64 (Registry_API.To_Natural (Report.Element))
        and then Report.Children_Frame.Selector_Code =
          ABI.Selector_Code (ABI.Accessibility_Children);

      Report.Child_At_Index_Frame :=
        ABI.Build_Selector_Frame
          (Session, Report.Element, ABI.Accessibility_Child_At_Index, 1);
      Report.Child_At_Index_Frame_Built :=
        Report.Child_At_Index_Frame.Session_Code =
          Interfaces.Unsigned_64 (A11y.Native_Identity.To_Natural (Session))
        and then Report.Child_At_Index_Frame.Element_Code =
          Interfaces.Unsigned_64 (Registry_API.To_Natural (Report.Element))
        and then Report.Child_At_Index_Frame.Selector_Code =
          ABI.Selector_Code (ABI.Accessibility_Child_At_Index)
        and then Report.Child_At_Index_Frame.Child_Index_Code = 1;

      Report.Attribute_Frame :=
        ABI.Build_Selector_Frame
          (Session, Report.Element, ABI.Accessibility_Attribute_Value);
      Report.Attribute_Frame_Built :=
        Report.Attribute_Frame.Session_Code =
          Interfaces.Unsigned_64 (A11y.Native_Identity.To_Natural (Session))
        and then Report.Attribute_Frame.Element_Code =
          Interfaces.Unsigned_64 (Registry_API.To_Natural (Report.Element))
        and then Report.Attribute_Frame.Selector_Code =
          ABI.Selector_Code (ABI.Accessibility_Attribute_Value);

      Report.Attribute_Settable_Frame :=
        ABI.Build_Selector_Frame
          (Session, Report.Element, ABI.Accessibility_Is_Attribute_Settable);
      Report.Attribute_Settable_Frame_Built :=
        Report.Attribute_Settable_Frame.Session_Code =
          Interfaces.Unsigned_64 (A11y.Native_Identity.To_Natural (Session))
        and then Report.Attribute_Settable_Frame.Element_Code =
          Interfaces.Unsigned_64 (Registry_API.To_Natural (Report.Element))
        and then Report.Attribute_Settable_Frame.Selector_Code =
          ABI.Selector_Code (ABI.Accessibility_Is_Attribute_Settable);

      Report.Action_Frame :=
        ABI.Build_Selector_Frame
          (Session, Report.Element, ABI.Accessibility_Perform_Action);
      Report.Action_Frame_Built :=
        Report.Action_Frame.Session_Code =
          Interfaces.Unsigned_64 (A11y.Native_Identity.To_Natural (Session))
        and then Report.Action_Frame.Element_Code =
          Interfaces.Unsigned_64 (Registry_API.To_Natural (Report.Element))
        and then Report.Action_Frame.Selector_Code =
          ABI.Selector_Code (ABI.Accessibility_Perform_Action);

      Report.Hit_Test_Frame :=
        ABI.Build_Selector_Frame
          (Session, Report.Element, ABI.Accessibility_Hit_Test);
      Report.Hit_Test_Frame_Built :=
        Report.Hit_Test_Frame.Session_Code =
          Interfaces.Unsigned_64 (A11y.Native_Identity.To_Natural (Session))
        and then Report.Hit_Test_Frame.Element_Code =
          Interfaces.Unsigned_64 (Registry_API.To_Natural (Report.Element))
        and then Report.Hit_Test_Frame.Selector_Code =
          ABI.Selector_Code (ABI.Accessibility_Hit_Test);

      Report.Focused_Element_Frame :=
        ABI.Build_Selector_Frame
          (Session, Report.Element, ABI.Accessibility_Focused_UI_Element);
      Report.Focused_Element_Frame_Built :=
        Report.Focused_Element_Frame.Session_Code =
          Interfaces.Unsigned_64 (A11y.Native_Identity.To_Natural (Session))
        and then Report.Focused_Element_Frame.Element_Code =
          Interfaces.Unsigned_64 (Registry_API.To_Natural (Report.Element))
        and then Report.Focused_Element_Frame.Selector_Code =
          ABI.Selector_Code (ABI.Accessibility_Focused_UI_Element);

      Report.Notification_Frame :=
        ABI.Build_Selector_Frame
          (Session, Report.Element, ABI.Accessibility_Post_Notification);
      Report.Notification_Frame_Built :=
        Report.Notification_Frame.Session_Code =
          Interfaces.Unsigned_64 (A11y.Native_Identity.To_Natural (Session))
        and then Report.Notification_Frame.Element_Code =
          Interfaces.Unsigned_64 (Registry_API.To_Natural (Report.Element))
        and then Report.Notification_Frame.Selector_Code =
          ABI.Selector_Code (ABI.Accessibility_Post_Notification);

      if Report.Children_Frame_Built
        and then Report.Child_At_Index_Frame_Built
        and then Report.Attribute_Frame_Built
        and then Report.Attribute_Settable_Frame_Built
        and then Report.Action_Frame_Built
        and then Report.Hit_Test_Frame_Built
        and then Report.Focused_Element_Frame_Built
        and then Report.Notification_Frame_Built
      then
         Report.Status := A11y.Results.Success;
      else
         Report.Status := A11y.Results.Internal_Error;
      end if;
   exception
      when others =>
         Report.Status := A11y.Results.Internal_Error;
   end Export_Public_Root;

end A11y.MacOS_Backend.NSAccessibility_Public_Roots;
