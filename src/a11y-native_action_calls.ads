with A11y.Actions;
with A11y.Dispatchers;
with A11y.Native_Callbacks;
with A11y.Native_Object_Caches;
with A11y.Native_Runtimes;
with A11y.Node_Ids;
with A11y.States;

package A11y.Native_Action_Calls is

   procedure Invoke_Object_Action
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : in out A11y.Actions.Action_Provider'Class;
      Action     : A11y.Actions.Action_Id;
      Result     : out A11y.Actions.Action_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

   procedure Invoke_Object_Action
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : in out A11y.Actions.Action_Provider'Class;
      Action     : A11y.Actions.Action_Id;
      States     : A11y.States.State_Set;
      Result     : out A11y.Actions.Action_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

   procedure Invoke_Node_Action
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : in out A11y.Actions.Action_Provider'Class;
      Action     : A11y.Actions.Action_Id;
      Result     : out A11y.Actions.Action_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

   procedure Invoke_Node_Action
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : in out A11y.Actions.Action_Provider'Class;
      Action     : A11y.Actions.Action_Id;
      States     : A11y.States.State_Set;
      Result     : out A11y.Actions.Action_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

end A11y.Native_Action_Calls;
