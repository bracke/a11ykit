with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Results;
with A11y.Windows_Backend.UIA_COM_Exports;
with A11y.Windows_Backend.UIA_COM_Live_Exports;
with A11y.Windows_Backend.UIA_COM_Object_Exports;
with A11y.Windows_Backend.UIA_COM_VTables;
with A11y.Windows_Backend.UIA_Com_Providers;
with A11y.Windows_Backend.UIA_Provider_Registry;

package A11y.Windows_Backend.UIA_Public_Roots is

   type Public_Root_Export_Report is record
      Provider_Ensured          : Boolean := False;
      Provider_Initialized      : Boolean := False;
      Export_Table_Built        : Boolean := False;
      Object_Descriptor_Built   : Boolean := False;
      Object_Exported           : Boolean := False;
      Native_Node_Component_Stable : Boolean := False;
      Fragment_Interface_Queryable : Boolean := False;
      Simple_Interface_Queryable   : Boolean := False;
      Fragment_Root_Interface_Queryable : Boolean := False;
      Session                   : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Root                      : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Node                      : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Native_Node_Component     : Natural := 0;
      Provider                  :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id :=
          A11y.Windows_Backend.UIA_Provider_Registry.No_Provider;
      Token                     :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Token :=
          A11y.Windows_Backend.UIA_COM_Object_Exports.No_COM_Object;
      Export                    :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Export_Descriptor;
      Table                     :
        A11y.Windows_Backend.UIA_COM_Exports.COM_Export_Table;
      Descriptor                :
        A11y.Windows_Backend.UIA_COM_VTables.COM_Object_Descriptor;
      Object_Export             :
        A11y.Windows_Backend.UIA_COM_Object_Exports.Object_Export_Report;
      Fragment_Query            :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Query_Report;
      Simple_Query              :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Query_Report;
      Fragment_Root_Query       :
        A11y.Windows_Backend.UIA_COM_Live_Exports.Interface_Query_Report;
      Status                    : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   procedure Export_Public_Root
     (Registry     :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Object_Table :
        in out A11y.Windows_Backend.UIA_COM_Object_Exports
          .COM_Object_Export_Table;
      Session      : A11y.Native_Identity.Backend_Session_Id;
      Root         : A11y.Node_Ids.Node_Id;
      Node         : A11y.Node_Ids.Node_Id;
      Report       : out Public_Root_Export_Report);

end A11y.Windows_Backend.UIA_Public_Roots;
