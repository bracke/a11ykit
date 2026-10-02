with A11y.Results;

package A11y.Windows_Backend.UIA_Bridge_Audit is

   type Bridge_Operation is
     (Query_Interface_Callback,
      Add_Ref_Callback,
      Release_Callback,
      Provider_Method_Callback,
      Provider_Method_Frame_Callback,
      Provider_Method_Full_Frame_Callback,
      Copy_BSTR,
      Destroy_BSTR,
      Copy_UInt32_SAFEARRAY,
      Destroy_SAFEARRAY,
      Translate_HResult,
      Bridge_Target_Probe,
      Client_Runtime_Probe,
      Host_Window_Handshake_Probe,
      Minimal_Provider_Host_Window_Probe,
      Callback_Provider_Host_Window_Probe);

   type Ownership_Rule is
     (No_Ownership_Transfer,
      Caller_Owns_Return,
      Callee_Consumes_Argument,
      Balanced_AddRef_Release);

   type Thread_Rule is
     (Any_COM_Apartment,
      Provider_Apartment_Required);

   type Exception_Rule is
     (Contain_Ada_Exception,
      No_Exception_Boundary);

   type Calling_Convention_Rule is
     (C_ABI_Callback,
      C_ABI_Helper);

   type Nullability_Rule is
     (No_Null_Values,
      Nullable_Native_Handle,
      Nullable_Return_On_Failure);

   type Lifetime_Rule is
     (No_Durable_State,
      Callback_Frame_Ephemeral,
      Native_Value_Must_Be_Destroyed,
      Balanced_Reference_Lifetime);

   type Representation_Rule is
     (Opaque_Integer_Handles,
      Stable_HResult_Code,
      Bounded_UTF16_Value,
      Bounded_UInt32_Array);

   type Operation_Contract is record
      Allowed              : Boolean := False;
      Ownership            : Ownership_Rule := No_Ownership_Transfer;
      Threading            : Thread_Rule := Any_COM_Apartment;
      Exception_Behavior   : Exception_Rule := No_Exception_Boundary;
      Calling_Convention   : Calling_Convention_Rule := C_ABI_Helper;
      Nullability          : Nullability_Rule := No_Null_Values;
      Lifetime             : Lifetime_Rule := No_Durable_State;
      Representation       : Representation_Rule := Opaque_Integer_Handles;
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

end A11y.Windows_Backend.UIA_Bridge_Audit;
