with A11y.MacOS_Backend.NSAccessibility_ABI_Surface;
with A11y.MacOS_Backend.NSAccessibility_Element_Registry;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Results;

package A11y.MacOS_Backend.NSAccessibility_Public_Roots is

   type Public_Root_Export_Report is record
      Element_Ensured          : Boolean := False;
      Element_Main_Thread_Bound : Boolean := False;
      Native_View_Bound        : Boolean := False;
      Element_Resolved         : Boolean := False;
      Native_Node_Component_Stable : Boolean := False;
      Children_Frame_Built     : Boolean := False;
      Child_At_Index_Frame_Built : Boolean := False;
      Attribute_Frame_Built    : Boolean := False;
      Attribute_Settable_Frame_Built : Boolean := False;
      Action_Frame_Built       : Boolean := False;
      Hit_Test_Frame_Built     : Boolean := False;
      Focused_Element_Frame_Built : Boolean := False;
      Notification_Frame_Built : Boolean := False;
      Session                  :
        A11y.Native_Identity.Backend_Session_Id :=
          A11y.Native_Identity.No_Session;
      Root                     : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Node                     : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Native_Node_Component    : Natural := 0;
      Element                  :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Id :=
          A11y.MacOS_Backend.NSAccessibility_Element_Registry.No_Element;
      Ensure_Report            :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Registry_Mutation_Report;
      Resolved_Element         :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Element_Record_Snapshot;
      Children_Frame           :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame;
      Child_At_Index_Frame     :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame;
      Attribute_Frame          :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame;
      Attribute_Settable_Frame :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame;
      Action_Frame             :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame;
      Hit_Test_Frame           :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame;
      Focused_Element_Frame    :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame;
      Notification_Frame       :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Selector_Frame;
      Status                   : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   procedure Export_Public_Root
     (Registry              :
        in out A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Element_Registry;
      Session               : A11y.Native_Identity.Backend_Session_Id;
      Root                  : A11y.Node_Ids.Node_Id;
      Node                  : A11y.Node_Ids.Node_Id;
      Report                : out Public_Root_Export_Report;
      Native_View_Component : Natural := 0);

end A11y.MacOS_Backend.NSAccessibility_Public_Roots;
