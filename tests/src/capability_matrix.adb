with Ada.Command_Line;
with Ada.Text_IO;

with A11y_Tool_Reports;
with Project_Tools.JSON;

procedure Capability_Matrix is
begin
   if Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--json"
   then
      declare
         Document : constant String := A11y_Tool_Reports.Capability_Matrix_JSON;
      begin
         if Project_Tools.JSON.Field_Value (Document, "schema")
           /= A11y_Tool_Reports.Capability_Matrix_Schema
         then
            raise Program_Error with "generated JSON schema self-check failed";
         end if;

         Ada.Text_IO.Put (Document);
      end;
   elsif Ada.Command_Line.Argument_Count = 0 then
      Ada.Text_IO.Put (A11y_Tool_Reports.Capability_Matrix_Markdown);
   else
      Ada.Text_IO.Put_Line ("usage: capability_matrix [--json]");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;
   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
exception
   when others =>
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Capability_Matrix;
