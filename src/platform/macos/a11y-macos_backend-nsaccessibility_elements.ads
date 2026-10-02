with Ada.Containers.Vectors;

with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Results;

package A11y.MacOS_Backend.NSAccessibility_Elements is

   Max_Retain_Count : constant Natural := 1_000_000;
   Max_Tracked_Native_Calls : constant Natural := 1_000_000;

   type Element_State is
     (Element_Created,
      Element_Live,
      Element_Defunct,
      Element_Destroyed);

   type Element_Object is private;

   type Element_Snapshot is record
      State             : Element_State := Element_Created;
      Session           : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Root              : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Node              : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Retains           : Natural := 0;
      Active_Calls      : Natural := 0;
      Call_Generation   : Natural := 0;
      Main_Thread_Bound : Boolean := False;
      Native_View_Bound : Boolean := False;
      Native_View_Component : Natural := 0;
      Defunct           : Boolean := False;
   end record;

   type Element_Call_Context is private;

   type Element_Export_Descriptor is record
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
      Main_Thread_Bound     : Boolean := False;
      Native_View_Bound     : Boolean := False;
      Native_View_Component : Natural := 0;
      Defunct               : Boolean := False;
   end record;

   type Element_Call_Snapshot is record
      Active                : Boolean := False;
      Status                : A11y.Results.Status_Code :=
        A11y.Results.Success;
      Session               : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Root                  : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Node                  : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Native_Node_Component : Natural := 0;
      Native_Call_Token     : Natural := 0;
      Native_Call_Generation : Natural := 0;
      Main_Thread_Bound     : Boolean := False;
      Defunct               : Boolean := False;
   end record;

   procedure Initialize
     (Element : in out Element_Object;
      Session : A11y.Native_Identity.Backend_Session_Id;
      Root    : A11y.Node_Ids.Node_Id;
      Node    : A11y.Node_Ids.Node_Id;
      Result  : out A11y.Results.Result);

   procedure Bind_Main_Thread
     (Element : in out Element_Object;
      Result  : out A11y.Results.Result);

   procedure Retain
     (Element : in out Element_Object;
      Retains : out Natural;
      Result  : out A11y.Results.Result);

   procedure Release
     (Element : in out Element_Object;
      Retains : out Natural;
      Result  : out A11y.Results.Result);

   procedure Mark_Defunct
     (Element : in out Element_Object;
      Result  : out A11y.Results.Result);

   procedure Bind_Native_View
     (Element               : in out Element_Object;
      Native_View_Component : Natural;
      Result                : out A11y.Results.Result);

   procedure Begin_Native_Call
     (Element             : in out Element_Object;
      Context             : out Element_Call_Context;
      Result              : out A11y.Results.Result;
      Require_Main_Thread : Boolean := False);

   procedure End_Native_Call
     (Element : in out Element_Object;
      Context : in out Element_Call_Context;
      Result  : out A11y.Results.Result);

   function Drained (Element : Element_Object) return Boolean;

   function Export_Descriptor
     (Element : Element_Object)
      return Element_Export_Descriptor;

   function Snapshot (Element : Element_Object) return Element_Snapshot;

   function Snapshot
     (Context : Element_Call_Context)
      return Element_Call_Snapshot;

   function Rejected_Call_Context
     (Status : A11y.Results.Status_Code)
      return Element_Call_Context;

private
   package Active_Token_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Natural);

   type Element_Object is record
      State             : Element_State := Element_Created;
      Session           : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Root              : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Node              : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Retains           : Natural := 0;
      Active_Calls      : Natural := 0;
      Call_Generation   : Natural := 0;
      Next_Call_Token   : Natural := 1;
      Active_Call_Token_Sum : Long_Long_Integer := 0;
      Active_Call_Token_Square_Sum : Long_Long_Integer := 0;
      Active_Tokens    : Active_Token_Vectors.Vector;
      Main_Thread_Bound : Boolean := False;
      Native_View_Bound : Boolean := False;
      Native_View_Component : Natural := 0;
      Defunct           : Boolean := False;
   end record;

   type Element_Call_Context is record
      Active                : Boolean := False;
      Status                : A11y.Results.Status_Code :=
        A11y.Results.Success;
      Session               : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Root                  : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Node                  : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Native_Node_Component : Natural := 0;
      Native_Call_Token     : Natural := 0;
      Native_Call_Generation : Natural := 0;
      Main_Thread_Bound     : Boolean := False;
      Defunct               : Boolean := False;
   end record;

end A11y.MacOS_Backend.NSAccessibility_Elements;
