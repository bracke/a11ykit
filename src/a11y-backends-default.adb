with A11y.Backends.Disabled_Backends;

package body A11y.Backends.Default is

   function Create_Null return A11y.Backends.Null_Backends.Null_Backend is
      Result : A11y.Backends.Null_Backends.Null_Backend;
   begin
      return Result;
   end Create_Null;

   function Create_Default return A11y.Backends.Backend'Class is
      Selection : constant A11y.Backends.Selection.Selection_Result :=
        A11y.Backends.Selection.Resolve ("default");
      Target : constant A11y.Backends.Native_Backends.Native_Target_Result :=
        A11y.Backends.Native_Backends.Target_For_Current_Platform;
      Constructed : constant A11y.Backends.Backend_Kind :=
        A11y.Backends.Constructed_Backend
          (Selection.Selected, Target.Supported);
   begin
      case Constructed is
         when A11y.Backends.Native =>
            return A11y.Backends.Native_Backends.Create (Target.Target);
         when A11y.Backends.Disabled =>
            declare
               Result : A11y.Backends.Disabled_Backends.Disabled_Backend;
            begin
               return Result;
            end;
         when A11y.Backends.Default_Backend |
              A11y.Backends.Null_Backend =>
            return Create_Null;
      end case;
   end Create_Default;

   function Create_From_Override
     (Override  : String;
      Selection : out A11y.Backends.Selection.Selection_Result)
      return A11y.Backends.Backend'Class
   is
   begin
      Selection := A11y.Backends.Selection.Resolve (Override);

      declare
         Target : constant A11y.Backends.Native_Backends.Native_Target_Result :=
           A11y.Backends.Native_Backends.Target_For_Current_Platform;
         Constructed : constant A11y.Backends.Backend_Kind :=
           A11y.Backends.Constructed_Backend
             (Selection.Selected, Target.Supported);
      begin
         case Constructed is
         when A11y.Backends.Native =>
            return A11y.Backends.Native_Backends.Create (Target.Target);
         when A11y.Backends.Disabled =>
            declare
               Result : A11y.Backends.Disabled_Backends.Disabled_Backend;
            begin
               return Result;
            end;
         when A11y.Backends.Default_Backend |
              A11y.Backends.Null_Backend =>
            return Create_Null;
         end case;
      end;
   end Create_From_Override;

end A11y.Backends.Default;
