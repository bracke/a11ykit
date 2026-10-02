package body A11y.MacOS_Backend.NSAccessibility_Bridge_Audit is

   function Contract
     (Operation : Bridge_Operation)
      return Operation_Contract is
   begin
      return
        (case Operation is
           when Bridge_Target_Probe =>
             (Allowed => True,
              Ownership => No_Ownership_Transfer,
              Threading => Any_Thread,
              Exception_Behavior => No_Exception_Boundary,
              Calling_Convention => Objective_C_ABI_Helper,
              Nullability => No_Null_Values,
              Lifetime => No_Durable_State,
              Representation => Opaque_Object_Reference,
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Create_Autorelease_Pool =>
             (Allowed => True,
              Ownership => Caller_Owns_Return,
              Threading => Any_Thread,
              Exception_Behavior => Contain_Objective_C_Exception,
              Calling_Convention => Objective_C_ABI_Helper,
              Nullability => Nullable_Return_On_Failure,
              Lifetime => Native_Object_Must_Be_Released,
              Representation => Opaque_Object_Reference,
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Drain_Autorelease_Pool =>
             (Allowed => True,
              Ownership => Callee_Consumes_Argument,
              Threading => Any_Thread,
              Exception_Behavior => Contain_Objective_C_Exception,
              Calling_Convention => Objective_C_ABI_Helper,
              Nullability => Nullable_Native_Object,
              Lifetime => Native_Object_Must_Be_Released,
              Representation => Opaque_Object_Reference,
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Retain_Object | Release_Object =>
             (Allowed => True,
              Ownership => Balanced_Retain_Release,
              Threading => Any_Thread,
              Exception_Behavior => Contain_Objective_C_Exception,
              Calling_Convention => Objective_C_ABI_Helper,
              Nullability => Nullable_Native_Object,
              Lifetime => Balanced_Retain_Release_Lifetime,
              Representation => Opaque_Object_Reference,
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Copy_UTF8_String | Copy_UInt32_Array =>
             (Allowed => True,
              Ownership => Caller_Owns_Return,
              Threading => Any_Thread,
              Exception_Behavior => Contain_Objective_C_Exception,
              Calling_Convention => Objective_C_ABI_Helper,
              Nullability => Nullable_Return_On_Failure,
              Lifetime => Native_Object_Must_Be_Released,
              Representation =>
                (if Operation = Copy_UTF8_String
                 then Bounded_UTF8_Value
                else Bounded_UInt32_Array),
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Create_Virtual_Element |
                Create_Virtual_Element_With_Value_Callback |
                Create_Virtual_Element_With_Callbacks |
                Install_Process_Root =>
             (Allowed => True,
              Ownership => Caller_Owns_Return,
              Threading => Main_Thread_Required,
              Exception_Behavior => Contain_Objective_C_Exception,
              Calling_Convention => Objective_C_ABI_Helper,
              Nullability => Nullable_Return_On_Failure,
              Lifetime => Native_Object_Must_Be_Released,
              Representation => Opaque_Object_Reference,
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Virtual_Element_Matches =>
             (Allowed => True,
              Ownership => No_Ownership_Transfer,
              Threading => Any_Thread,
              Exception_Behavior => Contain_Objective_C_Exception,
              Calling_Convention => Objective_C_ABI_Helper,
              Nullability => Nullable_Native_Object,
              Lifetime => No_Durable_State,
              Representation => Opaque_Object_Reference,
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Probe_Virtual_Element_Bridge |
                Probe_Value_Returning_Virtual_Element_Bridge |
                Probe_Object_Returning_Virtual_Element_Bridge =>
             (Allowed => True,
              Ownership => No_Ownership_Transfer,
              Threading => Main_Thread_Required,
              Exception_Behavior => Contain_Objective_C_Exception,
              Calling_Convention => Objective_C_ABI_Helper,
              Nullability => Nullable_Native_Object,
              Lifetime => Callback_Frame_Ephemeral,
              Representation => Opaque_Object_Reference,
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Probe_Public_AX_Client_For_PID =>
             (Allowed => True,
              Ownership => No_Ownership_Transfer,
              Threading => Main_Thread_Required,
              Exception_Behavior => Contain_Objective_C_Exception,
              Calling_Convention => Objective_C_ABI_Helper,
              Nullability => No_Null_Values,
              Lifetime => Callback_Frame_Ephemeral,
              Representation => Opaque_Object_Reference,
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Dispatch_Selector_Callback |
                Copy_Value_Callback |
                Copy_Object_Callback |
                Dispatch_Selector_Frame_Callback |
                Post_Notification_Callback =>
             (Allowed => True,
              Ownership => No_Ownership_Transfer,
              Threading => Main_Thread_Required,
              Exception_Behavior => Contain_Ada_Exception,
              Calling_Convention => Objective_C_ABI_Callback,
              Nullability => Nullable_Native_Object,
              Lifetime => Callback_Frame_Ephemeral,
              Representation => Opaque_Object_Reference,
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Post_Notification_For_Object =>
             (Allowed => True,
              Ownership => No_Ownership_Transfer,
              Threading => Main_Thread_Required,
              Exception_Behavior => Contain_Objective_C_Exception,
              Calling_Convention => Objective_C_ABI_Helper,
              Nullability => Nullable_Native_Object,
              Lifetime => Callback_Frame_Ephemeral,
              Representation => Opaque_Object_Reference,
              Accessibility_Policy => False,
              Status => A11y.Results.Success));
   end Contract;

   function Operation_Name (Operation : Bridge_Operation) return String is
     (case Operation is
        when Bridge_Target_Probe => "a11y_nsax_bridge_is_macos",
        when Create_Autorelease_Pool => "a11y_nsax_create_autorelease_pool",
        when Drain_Autorelease_Pool => "a11y_nsax_drain_autorelease_pool",
        when Retain_Object => "a11y_nsax_retain_object",
        when Release_Object => "a11y_nsax_release_object",
        when Copy_UTF8_String => "a11y_nsax_copy_utf8_string",
        when Copy_UInt32_Array => "a11y_nsax_copy_uint32_array",
        when Create_Virtual_Element =>
          "a11y_nsax_create_virtual_element",
        when Create_Virtual_Element_With_Value_Callback =>
          "a11y_nsax_create_virtual_element_with_value_callback",
        when Create_Virtual_Element_With_Callbacks =>
          "a11y_nsax_create_virtual_element_with_callbacks",
        when Install_Process_Root =>
          "a11y_nsax_install_process_root",
        when Virtual_Element_Matches =>
          "a11y_nsax_virtual_element_matches",
        when Probe_Virtual_Element_Bridge =>
          "a11y_nsax_probe_virtual_element_bridge",
        when Probe_Value_Returning_Virtual_Element_Bridge =>
          "a11y_nsax_probe_value_returning_virtual_element_bridge",
        when Probe_Object_Returning_Virtual_Element_Bridge =>
          "a11y_nsax_probe_object_returning_virtual_element_bridge",
        when Probe_Public_AX_Client_For_PID =>
          "a11y_nsax_probe_public_ax_client_for_pid",
        when Dispatch_Selector_Callback => "a11y_nsax_dispatch_selector",
        when Copy_Value_Callback => "a11y_nsax_value_callback",
        when Copy_Object_Callback => "a11y_nsax_object_callback",
        when Dispatch_Selector_Frame_Callback =>
          "a11y_nsax_dispatch_selector_frame",
        when Post_Notification_Callback => "a11y_nsax_post_notification",
        when Post_Notification_For_Object =>
          "a11y_nsax_post_notification_for_object");

   function Bounded_Limit (Operation : Bridge_Operation) return Natural is
     (case Operation is
        when Copy_UTF8_String => 65_536,
        when Copy_UInt32_Array => 4_096,
        when others => 0);

   function Is_ABI_Only
     (Operation : Bridge_Operation)
      return Boolean
   is
      Info : constant Operation_Contract := Contract (Operation);
   begin
      return Info.Allowed and then not Info.Accessibility_Policy;
   end Is_ABI_Only;

   function All_Operations_Audited return Boolean is
   begin
      for Operation in Bridge_Operation loop
         if not Is_ABI_Only (Operation) then
            return False;
         end if;
      end loop;

      return True;
   end All_Operations_Audited;

end A11y.MacOS_Backend.NSAccessibility_Bridge_Audit;
