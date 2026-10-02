package body A11y.Backends.Selection.Classification is
   pragma SPARK_Mode (On);

   function Is_Valid_Mode
     (Mode : Selection_Mode)
      return Boolean is
     (A11y.Backends.Selection.Is_Valid_Mode (Mode));

   function Is_Explicit_Mode
     (Mode : Selection_Mode)
      return Boolean is
     (A11y.Backends.Selection.Is_Explicit_Mode (Mode));

   function Requires_Native_Transport
     (Mode : Selection_Mode)
      return Boolean is
     (A11y.Backends.Selection.Requires_Native_Transport (Mode));

   function Expected_Selected_Backend
     (Mode                    : Selection_Mode;
      Native_Target_Supported : Boolean;
      Native_Available        : Boolean)
      return Backend_Kind is
     (A11y.Backends.Selection.Expected_Selected_Backend
        (Mode, Native_Target_Supported, Native_Available));

   function Expected_Status
     (Mode                    : Selection_Mode;
      Native_Target_Supported : Boolean;
      Native_Available        : Boolean)
      return A11y.Results.Status_Code is
     (A11y.Backends.Selection.Expected_Status
        (Mode, Native_Target_Supported, Native_Available));

   function Expected_Fallback
     (Mode                    : Selection_Mode;
      Native_Target_Supported : Boolean;
      Native_Available        : Boolean)
      return Boolean is
     (A11y.Backends.Selection.Expected_Fallback
        (Mode, Native_Target_Supported, Native_Available));

end A11y.Backends.Selection.Classification;
