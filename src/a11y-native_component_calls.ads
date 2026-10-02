with A11y.Dispatchers;
with A11y.Geometry;
with A11y.Native_Callbacks;
with A11y.Native_Object_Caches;
with A11y.Native_Runtimes;
with A11y.Nodes;
with A11y.Node_Ids;
with A11y.Results;

package A11y.Native_Component_Calls is

   type Native_Boolean_Result is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      Source : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Value  : Boolean := False;
   end record;

   type Native_Hit_Test_Result is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      Source : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Target : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
   end record;

   procedure Query_Object_Contains_Point
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Point      : A11y.Geometry.Point;
      Result     : out Native_Boolean_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

   procedure Query_Node_Contains_Point
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Point      : A11y.Geometry.Point;
      Result     : out Native_Boolean_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

   procedure Query_Object_Hit_Test
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Point      : A11y.Geometry.Point;
      Result     : out Native_Hit_Test_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

   procedure Query_Node_Hit_Test
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Point      : A11y.Geometry.Point;
      Result     : out Native_Hit_Test_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

end A11y.Native_Component_Calls;
