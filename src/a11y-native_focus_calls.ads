with A11y.Actions;
with A11y.Dispatchers;
with A11y.Native_Callbacks;
with A11y.Native_Object_Caches;
with A11y.Native_Runtimes;
with A11y.Nodes;
with A11y.Node_Ids;
with A11y.Results;

package A11y.Native_Focus_Calls is

   type Native_Focus_Result is record
      Status  : A11y.Results.Status_Code := A11y.Results.Success;
      Node    : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Focused : Boolean := False;
   end record;

   procedure Query_Object_Focused
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Focus_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

   procedure Query_Node_Focused
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Focus_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

   procedure Request_Object_Focus
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : in out A11y.Actions.Action_Provider'Class;
      Result     : out A11y.Actions.Action_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

   procedure Request_Node_Focus
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : in out A11y.Actions.Action_Provider'Class;
      Result     : out A11y.Actions.Action_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

end A11y.Native_Focus_Calls;
