with Interfaces;

package A11y_NSAX_Native_Runtime_Probes is

   type Virtual_Element_Probe_Report is record
      Native_Runtime_Available : Boolean := False;
      Mask                     : Interfaces.Unsigned_32 := 0;
      Value_Returning_Mask     : Interfaces.Unsigned_32 := 0;
      Object_Returning_Mask    : Interfaces.Unsigned_32 := 0;
      Completed                : Boolean := False;
      Value_Returning_Completed : Boolean := False;
      Object_Returning_Completed : Boolean := False;
   end record;

   type Public_AX_Client_Probe_Report is record
      Native_Runtime_Available : Boolean := False;
      Process_Id_Available     : Boolean := False;
      Mask                     : Interfaces.Unsigned_32 := 0;
      Completed                : Boolean := False;
   end record;

   function Run_Virtual_Element_Probe return Virtual_Element_Probe_Report;

   function Run_Public_AX_Client_Probe return Public_AX_Client_Probe_Report;

end A11y_NSAX_Native_Runtime_Probes;
