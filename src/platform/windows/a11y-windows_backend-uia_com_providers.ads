with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Results;

package A11y.Windows_Backend.UIA_Com_Providers is

   Max_Reference_Count : constant Natural := 1_000_000;
   Max_Tracked_Native_Calls : constant Natural := 1_000_000;

   type Provider_Interface is
     (IUnknown_Interface,
      Raw_Element_Provider_Simple,
      Raw_Element_Provider_Fragment,
      Raw_Element_Provider_Fragment_Root,
      Raw_Element_Provider_Advise_Events,
      Unsupported_Interface);

   type Provider_State is
     (Provider_Created,
      Provider_Alive,
      Provider_Defunct,
      Provider_Destroyed);

   type Provider_Object is private;

   type Provider_Interface_Set is array (Provider_Interface) of Boolean;

   type Provider_Snapshot is record
      State      : Provider_State := Provider_Created;
      Session    : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Node       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Root       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      References : Natural := 0;
      Active_Calls : Natural := 0;
      Call_Generation : Natural := 0;
      Host_Window_Bound : Boolean := False;
      Host_Window_Component : Natural := 0;
      Defunct    : Boolean := False;
   end record;

   type Interface_Query is record
      Supported : Boolean := False;
      Status    : A11y.Results.Status_Code := A11y.Results.Success;
      Kind      : Provider_Interface := Unsupported_Interface;
   end record;

   type Provider_Call_Context is private;

   type Provider_Export_Descriptor is record
      Exportable            : Boolean := False;
      Status                : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Session               : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Root                  : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Node                  : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Native_Node_Component : Natural := 0;
      Interfaces            : Provider_Interface_Set := [others => False];
      Host_Window_Bound     : Boolean := False;
      Host_Window_Component : Natural := 0;
      Defunct               : Boolean := False;
   end record;

   type Provider_Call_Snapshot is record
      Active                : Boolean := False;
      Status                : A11y.Results.Status_Code :=
        A11y.Results.Success;
      Requested             : Provider_Interface := Unsupported_Interface;
      Session               : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Root                  : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Node                  : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Native_Node_Component : Natural := 0;
      Native_Call_Token     : Natural := 0;
      Native_Call_Generation : Natural := 0;
      Defunct               : Boolean := False;
   end record;

   procedure Initialize
     (Provider : in out Provider_Object;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Root     : A11y.Node_Ids.Node_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Result   : out A11y.Results.Result);

   procedure Query_Interface
     (Provider  : in out Provider_Object;
      Requested : Provider_Interface;
      Query     : out Interface_Query);

   procedure Add_Ref
     (Provider   : in out Provider_Object;
      References : out Natural;
      Result     : out A11y.Results.Result);

   procedure Release
     (Provider   : in out Provider_Object;
      References : out Natural;
      Result     : out A11y.Results.Result);

   procedure Mark_Defunct
     (Provider : in out Provider_Object;
      Result   : out A11y.Results.Result);

   procedure Bind_Host_Window_Root
     (Provider              : in out Provider_Object;
      Host_Window_Component : Natural;
      Result                : out A11y.Results.Result);

   procedure Begin_Native_Call
     (Provider  : in out Provider_Object;
      Requested : Provider_Interface;
      Context   : out Provider_Call_Context;
      Result    : out A11y.Results.Result);

   procedure End_Native_Call
     (Provider : in out Provider_Object;
      Context  : in out Provider_Call_Context;
      Result   : out A11y.Results.Result);

   function Drained (Provider : Provider_Object) return Boolean;

   function Export_Descriptor
     (Provider : Provider_Object)
      return Provider_Export_Descriptor;

   function Snapshot (Provider : Provider_Object) return Provider_Snapshot;

   function Snapshot
     (Context : Provider_Call_Context)
      return Provider_Call_Snapshot;

   function Rejected_Call_Context
     (Requested : Provider_Interface;
      Status    : A11y.Results.Status_Code)
      return Provider_Call_Context;

private
   type Provider_Object is record
      State      : Provider_State := Provider_Created;
      Session    : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Root       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Node       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      References : Natural := 0;
      Active_Calls : Natural := 0;
      Call_Generation : Natural := 0;
      Next_Call_Token : Natural := 1;
      Active_Call_Token_Sum : Long_Long_Integer := 0;
      Active_Call_Token_Square_Sum : Long_Long_Integer := 0;
      Host_Window_Bound : Boolean := False;
      Host_Window_Component : Natural := 0;
      Defunct    : Boolean := False;
   end record;

   type Provider_Call_Context is record
      Active                : Boolean := False;
      Status                : A11y.Results.Status_Code :=
        A11y.Results.Success;
      Requested             : Provider_Interface := Unsupported_Interface;
      Session               : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Root                  : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Node                  : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Native_Node_Component : Natural := 0;
      Native_Call_Token     : Natural := 0;
      Native_Call_Generation : Natural := 0;
      Defunct               : Boolean := False;
   end record;

end A11y.Windows_Backend.UIA_Com_Providers;
