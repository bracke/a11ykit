with A11y.Results;

package A11y.MacOS_Backend.NSAccessibility_Bridge_Audit is

   type Bridge_Operation is
     (Bridge_Target_Probe,
      Create_Autorelease_Pool,
      Drain_Autorelease_Pool,
      Retain_Object,
      Release_Object,
      Copy_UTF8_String,
      Copy_UInt32_Array,
      Create_Virtual_Element,
      Create_Virtual_Element_With_Value_Callback,
      Create_Virtual_Element_With_Callbacks,
      Install_Process_Root,
      Virtual_Element_Matches,
      Probe_Virtual_Element_Bridge,
      Probe_Value_Returning_Virtual_Element_Bridge,
      Probe_Object_Returning_Virtual_Element_Bridge,
      Probe_Public_AX_Client_For_PID,
      Dispatch_Selector_Callback,
      Copy_Value_Callback,
      Copy_Object_Callback,
      Dispatch_Selector_Frame_Callback,
      Post_Notification_Callback,
      Post_Notification_For_Object);

   type Ownership_Rule is
     (No_Ownership_Transfer,
      Caller_Owns_Return,
      Callee_Consumes_Argument,
      Balanced_Retain_Release);

   type Thread_Rule is
     (Any_Thread,
      Main_Thread_Required);

   type Exception_Rule is
     (Contain_Objective_C_Exception,
      Contain_Ada_Exception,
      No_Exception_Boundary);

   type Calling_Convention_Rule is
     (Objective_C_ABI_Callback,
      Objective_C_ABI_Helper);

   type Nullability_Rule is
     (No_Null_Values,
      Nullable_Native_Object,
      Nullable_Return_On_Failure);

   type Lifetime_Rule is
     (No_Durable_State,
      Callback_Frame_Ephemeral,
      Native_Object_Must_Be_Released,
      Balanced_Retain_Release_Lifetime);

   type Representation_Rule is
     (Opaque_Object_Reference,
      Bounded_UTF8_Value,
      Bounded_UInt32_Array);

   type Operation_Contract is record
      Allowed              : Boolean := False;
      Ownership            : Ownership_Rule := No_Ownership_Transfer;
      Threading            : Thread_Rule := Any_Thread;
      Exception_Behavior   : Exception_Rule := No_Exception_Boundary;
      Calling_Convention   : Calling_Convention_Rule :=
        Objective_C_ABI_Helper;
      Nullability          : Nullability_Rule := No_Null_Values;
      Lifetime             : Lifetime_Rule := No_Durable_State;
      Representation       : Representation_Rule := Opaque_Object_Reference;
      Accessibility_Policy : Boolean := False;
      Status               : A11y.Results.Status_Code := A11y.Results.Success;
   end record;

   function Contract
     (Operation : Bridge_Operation)
      return Operation_Contract;

   function Operation_Name (Operation : Bridge_Operation) return String;

   function Bounded_Limit (Operation : Bridge_Operation) return Natural;

   function Is_ABI_Only
     (Operation : Bridge_Operation)
      return Boolean;

   function All_Operations_Audited return Boolean;

end A11y.MacOS_Backend.NSAccessibility_Bridge_Audit;
