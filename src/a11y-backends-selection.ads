with A11y.Results;

package A11y.Backends.Selection is

   type Selection_Mode is
     (Use_Default,
      Use_Native,
      Use_Null,
      Use_Disabled,
      Invalid);

   type Selection_Result is record
      Requested : Selection_Mode := Use_Default;
      Selected  : A11y.Backends.Backend_Kind := A11y.Backends.Null_Backend;
      Status    : A11y.Results.Status_Code := A11y.Results.Success;
      Fallback  : Boolean := False;
   end record;

   function Parse (Override : String) return Selection_Mode;

   function Is_Valid_Mode
     (Mode : Selection_Mode)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Valid_Mode'Result = (Mode /= Invalid);

   function Is_Explicit_Mode
     (Mode : Selection_Mode)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Is_Explicit_Mode'Result =
          (Mode in Use_Native | Use_Null | Use_Disabled);

   function Requires_Native_Transport
     (Mode : Selection_Mode)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Requires_Native_Transport'Result = (Mode = Use_Native);

   function Expected_Selected_Backend
     (Mode                    : Selection_Mode;
      Native_Target_Supported : Boolean;
      Native_Available        : Boolean)
      return Backend_Kind
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        (if Mode = Use_Disabled then
           A11y.Backends."=" (Expected_Selected_Backend'Result, Disabled)
         elsif Mode in Use_Null | Invalid then
           A11y.Backends."="
             (Expected_Selected_Backend'Result, Null_Backend)
         elsif Mode = Use_Native then
           (if Native_Target_Supported then
              A11y.Backends."=" (Expected_Selected_Backend'Result, Native)
            else
              A11y.Backends."="
                (Expected_Selected_Backend'Result, Null_Backend))
         else
           (if Native_Target_Supported and then Native_Available then
              A11y.Backends."=" (Expected_Selected_Backend'Result, Native)
            else
              A11y.Backends."="
                (Expected_Selected_Backend'Result, Null_Backend)));

   function Expected_Status
     (Mode                    : Selection_Mode;
      Native_Target_Supported : Boolean;
      Native_Available        : Boolean)
      return A11y.Results.Status_Code
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        (if Mode = Invalid then
           A11y.Results."="
             (Expected_Status'Result, A11y.Results.Invalid_Argument)
         elsif Mode in Use_Null | Use_Disabled then
           A11y.Results."="
             (Expected_Status'Result, A11y.Results.Success)
         elsif Native_Target_Supported and then Native_Available then
           A11y.Results."="
             (Expected_Status'Result, A11y.Results.Success)
         else
           A11y.Results."="
             (Expected_Status'Result, A11y.Results.Backend_Unavailable));

   function Expected_Fallback
     (Mode                    : Selection_Mode;
      Native_Target_Supported : Boolean;
      Native_Available        : Boolean)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Expected_Fallback'Result =
          (Mode = Invalid
           or else (Mode = Use_Native and then not Native_Target_Supported)
           or else (Mode = Use_Default
                    and then not
                      (Native_Target_Supported and then Native_Available)));

   function Resolve (Override : String) return Selection_Result;
   function Native_Target_Supported return Boolean;
   function Native_Available return Boolean;

end A11y.Backends.Selection;
