package body A11y_NSAX_Native_Runtime_Probes is

   function Run_Virtual_Element_Probe return Virtual_Element_Probe_Report is
   begin
      return
        (Native_Runtime_Available => False,
         Mask                     => 0,
         Value_Returning_Mask     => 0,
         Object_Returning_Mask    => 0,
         Completed                => False,
         Value_Returning_Completed => False,
         Object_Returning_Completed => False);
   end Run_Virtual_Element_Probe;

   function Run_Public_AX_Client_Probe return Public_AX_Client_Probe_Report is
   begin
      return
        (Native_Runtime_Available => False,
         Process_Id_Available     => False,
         Mask                     => 0,
         Completed                => False);
   end Run_Public_AX_Client_Probe;

end A11y_NSAX_Native_Runtime_Probes;
