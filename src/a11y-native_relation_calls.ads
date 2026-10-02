with A11y.Dispatchers;
with A11y.Native_Callbacks;
with A11y.Native_Object_Caches;
with A11y.Native_Runtimes;
with A11y.Node_Ids;
with A11y.Relations;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Native_Relation_Calls is

   type Native_Relation_Target_Result is record
      Status     : A11y.Results.Status_Code := A11y.Results.Success;
      Source     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Target     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Has_Target : Boolean := False;
   end record;

   type Native_Relation_Targets_Result is record
      Status    : A11y.Results.Status_Code := A11y.Results.Success;
      Source    : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Targets   : A11y.Relations.Target_Vectors.Vector;
      Truncated : Boolean := False;
   end record;

   procedure Query_Object_Relation_Targets
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Graph      : A11y.Relations.Relation_Graph;
      Kind       : A11y.Relations.Relation_Kind;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config;
      Result     : out Native_Relation_Targets_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

   procedure Query_Node_Relation_Targets
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Graph      : A11y.Relations.Relation_Graph;
      Kind       : A11y.Relations.Relation_Kind;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config;
      Result     : out Native_Relation_Targets_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

   procedure Query_Object_Active_Descendant
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Graph      : A11y.Relations.Relation_Graph;
      Result     : out Native_Relation_Target_Result;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

   procedure Query_Node_Active_Descendant
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Graph      : A11y.Relations.Relation_Graph;
      Result     : out Native_Relation_Target_Result;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token);

end A11y.Native_Relation_Calls;
