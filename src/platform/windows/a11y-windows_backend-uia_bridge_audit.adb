package body A11y.Windows_Backend.UIA_Bridge_Audit is

   function Contract
     (Operation : Bridge_Operation)
      return Operation_Contract is
   begin
      return
        (case Operation is
           when Query_Interface_Callback =>
             (Allowed => True,
              Ownership => No_Ownership_Transfer,
              Threading => Any_COM_Apartment,
              Exception_Behavior => Contain_Ada_Exception,
              Calling_Convention => C_ABI_Callback,
              Nullability => Nullable_Native_Handle,
              Lifetime => Callback_Frame_Ephemeral,
              Representation => Opaque_Integer_Handles,
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Add_Ref_Callback | Release_Callback =>
             (Allowed => True,
              Ownership => Balanced_AddRef_Release,
              Threading => Any_COM_Apartment,
              Exception_Behavior => Contain_Ada_Exception,
              Calling_Convention => C_ABI_Callback,
              Nullability => Nullable_Native_Handle,
              Lifetime => Balanced_Reference_Lifetime,
              Representation => Opaque_Integer_Handles,
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Provider_Method_Callback |
                Provider_Method_Frame_Callback |
                Provider_Method_Full_Frame_Callback =>
             (Allowed => True,
              Ownership => No_Ownership_Transfer,
              Threading => Provider_Apartment_Required,
              Exception_Behavior => Contain_Ada_Exception,
              Calling_Convention => C_ABI_Callback,
              Nullability => Nullable_Native_Handle,
              Lifetime => Callback_Frame_Ephemeral,
              Representation => Opaque_Integer_Handles,
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Copy_BSTR | Copy_UInt32_SAFEARRAY =>
             (Allowed => True,
              Ownership => Caller_Owns_Return,
              Threading => Any_COM_Apartment,
              Exception_Behavior => No_Exception_Boundary,
              Calling_Convention => C_ABI_Helper,
              Nullability => Nullable_Return_On_Failure,
              Lifetime => Native_Value_Must_Be_Destroyed,
              Representation =>
                (if Operation = Copy_BSTR
                 then Bounded_UTF16_Value
                 else Bounded_UInt32_Array),
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Destroy_BSTR | Destroy_SAFEARRAY =>
             (Allowed => True,
              Ownership => Callee_Consumes_Argument,
              Threading => Any_COM_Apartment,
              Exception_Behavior => No_Exception_Boundary,
              Calling_Convention => C_ABI_Helper,
              Nullability => Nullable_Native_Handle,
              Lifetime => Native_Value_Must_Be_Destroyed,
              Representation =>
                (if Operation = Destroy_BSTR
                 then Bounded_UTF16_Value
                 else Bounded_UInt32_Array),
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Translate_HResult | Bridge_Target_Probe =>
             (Allowed => True,
              Ownership => No_Ownership_Transfer,
              Threading => Any_COM_Apartment,
              Exception_Behavior => No_Exception_Boundary,
              Calling_Convention => C_ABI_Helper,
              Nullability => No_Null_Values,
              Lifetime => No_Durable_State,
              Representation => Stable_HResult_Code,
              Accessibility_Policy => False,
              Status => A11y.Results.Success),
           when Client_Runtime_Probe |
                Host_Window_Handshake_Probe |
                Minimal_Provider_Host_Window_Probe |
                Callback_Provider_Host_Window_Probe =>
             (Allowed => True,
              Ownership => No_Ownership_Transfer,
              Threading => Any_COM_Apartment,
              Exception_Behavior => No_Exception_Boundary,
              Calling_Convention => C_ABI_Helper,
              Nullability => Nullable_Native_Handle,
              Lifetime =>
                (if Operation in
                   Minimal_Provider_Host_Window_Probe |
                   Callback_Provider_Host_Window_Probe
                 then Balanced_Reference_Lifetime
                 else No_Durable_State),
              Representation => Opaque_Integer_Handles,
              Accessibility_Policy => False,
              Status => A11y.Results.Success));
   end Contract;

   function Operation_Name (Operation : Bridge_Operation) return String is
     (case Operation is
        when Query_Interface_Callback => "a11y_uia_query_interface",
        when Add_Ref_Callback => "a11y_uia_add_ref",
        when Release_Callback => "a11y_uia_release",
        when Provider_Method_Callback => "a11y_uia_dispatch_provider_method",
        when Provider_Method_Frame_Callback =>
          "a11y_uia_dispatch_provider_frame",
        when Provider_Method_Full_Frame_Callback =>
          "a11y_uia_dispatch_provider_full_frame",
        when Copy_BSTR => "a11y_uia_copy_bstr",
        when Destroy_BSTR => "a11y_uia_destroy_bstr",
       when Copy_UInt32_SAFEARRAY => "a11y_uia_copy_uint32_safearray",
       when Destroy_SAFEARRAY => "a11y_uia_destroy_safearray",
       when Translate_HResult => "a11y_uia_translate_hresult",
        when Bridge_Target_Probe => "a11y_uia_bridge_is_windows",
        when Client_Runtime_Probe => "a11y_uia_probe_client_runtime",
        when Host_Window_Handshake_Probe =>
          "a11y_uia_probe_host_window_handshake",
        when Minimal_Provider_Host_Window_Probe =>
          "a11y_uia_probe_minimal_provider_host_window",
        when Callback_Provider_Host_Window_Probe =>
          "a11y_uia_probe_callback_provider_host_window");

   function Bounded_Limit (Operation : Bridge_Operation) return Natural is
     (case Operation is
        when Copy_BSTR => 65_536,
        when Copy_UInt32_SAFEARRAY => 4_096,
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

end A11y.Windows_Backend.UIA_Bridge_Audit;
