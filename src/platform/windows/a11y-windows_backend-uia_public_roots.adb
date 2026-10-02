package body A11y.Windows_Backend.UIA_Public_Roots is

   package COM renames A11y.Windows_Backend.UIA_Com_Providers;
   package Exports renames A11y.Windows_Backend.UIA_COM_Exports;
   package Live renames A11y.Windows_Backend.UIA_COM_Live_Exports;
   package Objects renames A11y.Windows_Backend.UIA_COM_Object_Exports;
   package Registry_API renames A11y.Windows_Backend.UIA_Provider_Registry;
   package VTables renames A11y.Windows_Backend.UIA_COM_VTables;

   use type A11y.Results.Status_Code;

   procedure Export_Public_Root
     (Registry     : in out Registry_API.Provider_Registry;
      Object_Table : in out Objects.COM_Object_Export_Table;
      Session      : A11y.Native_Identity.Backend_Session_Id;
      Root         : A11y.Node_Ids.Node_Id;
      Node         : A11y.Node_Ids.Node_Id;
      Report       : out Public_Root_Export_Report)
   is
      Provider_Object : COM.Provider_Object;
      Result          : A11y.Results.Result;
      Component_Result : A11y.Results.Result;
      Expected_Component : Natural := 0;
   begin
      Report := (others => <>);
      Report.Session := Session;
      Report.Root := Root;
      Report.Node := Node;

      Registry_API.Ensure_Provider
        (Registry, Session, Root, Node, Report.Provider, Result);
      Report.Provider_Ensured := A11y.Results.Succeeded (Result);
      if not Report.Provider_Ensured then
         Report.Status := Result.Status;
         return;
      end if;

      COM.Initialize (Provider_Object, Session, Root, Node, Result);
      Report.Provider_Initialized := A11y.Results.Succeeded (Result);
      if not Report.Provider_Initialized then
         Report.Status := Result.Status;
         return;
      end if;

      Report.Export := COM.Export_Descriptor (Provider_Object);
      Expected_Component :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Session, Node, Component_Result);
      Report.Native_Node_Component := Report.Export.Native_Node_Component;
      Report.Native_Node_Component_Stable :=
        A11y.Results.Succeeded (Component_Result)
        and then Expected_Component /= 0
        and then Report.Native_Node_Component = Expected_Component;
      Report.Table :=
        Exports.Build_Export_Table (Report.Provider, Report.Export);
      Report.Export_Table_Built :=
        Report.Table.Exportable and then Report.Table.Status = A11y.Results.Success;
      if not Report.Export_Table_Built then
         Report.Status := Report.Table.Status;
         return;
      end if;

      Report.Descriptor := VTables.Build_Object_Descriptor (Report.Table);
      Report.Object_Descriptor_Built :=
        Report.Descriptor.Exportable
        and then Report.Descriptor.Controlling_IUnknown_Stable
        and then Report.Descriptor.Status = A11y.Results.Success;
      if not Report.Object_Descriptor_Built then
         Report.Status := Report.Descriptor.Status;
         return;
      end if;

      Objects.Export_Object
        (Object_Table, Report.Descriptor, Report.Object_Export);
      Report.Object_Exported :=
        Report.Object_Export.Exported
        and then Report.Object_Export.Status = A11y.Results.Success
        and then Objects.Is_Valid (Report.Object_Export.Token);
      Report.Token := Report.Object_Export.Token;
      if not Report.Object_Exported then
         Report.Status := Report.Object_Export.Status;
         return;
      end if;

      Live.Query_Interface
        (Object_Table,
         Report.Token,
         Session,
         Report.Provider,
         COM.Raw_Element_Provider_Fragment,
         Report.Fragment_Query);
      Report.Fragment_Interface_Queryable :=
        Report.Fragment_Query.Object_Resolved
        and then Report.Fragment_Query.Query.Supported
        and then Report.Fragment_Query.Reference.Present;

      Live.Query_Interface
        (Object_Table,
         Report.Token,
         Session,
         Report.Provider,
         COM.Raw_Element_Provider_Simple,
         Report.Simple_Query);
      Report.Simple_Interface_Queryable :=
        Report.Simple_Query.Object_Resolved
        and then Report.Simple_Query.Query.Supported
        and then Report.Simple_Query.Reference.Present;

      Live.Query_Interface
        (Object_Table,
         Report.Token,
         Session,
         Report.Provider,
         COM.Raw_Element_Provider_Fragment_Root,
         Report.Fragment_Root_Query);
      Report.Fragment_Root_Interface_Queryable :=
        Report.Fragment_Root_Query.Object_Resolved
        and then Report.Fragment_Root_Query.Query.Supported
        and then Report.Fragment_Root_Query.Reference.Present;

      if Report.Fragment_Interface_Queryable
        and then Report.Simple_Interface_Queryable
        and then Report.Fragment_Root_Interface_Queryable
      then
         Report.Status := A11y.Results.Success;
      elsif not Report.Fragment_Interface_Queryable then
         Report.Status := Report.Fragment_Query.Status;
      elsif not Report.Simple_Interface_Queryable then
         Report.Status := Report.Simple_Query.Status;
      else
         Report.Status := Report.Fragment_Root_Query.Status;
      end if;
   exception
      when others =>
         Report.Status := A11y.Results.Internal_Error;
   end Export_Public_Root;

end A11y.Windows_Backend.UIA_Public_Roots;
