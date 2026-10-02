with Ada.Command_Line;
with Ada.Text_IO;

with A11y_Native_Observation_Report;

procedure Native_Observation_Report is
begin
   if Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--json"
   then
      Ada.Text_IO.Put (A11y_Native_Observation_Report.JSON);
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--summary-json"
   then
      Ada.Text_IO.Put (A11y_Native_Observation_Report.Summary_JSON);
   elsif Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--require-native-conformance"
   then
      Ada.Text_IO.Put (A11y_Native_Observation_Report.Summary_JSON);
      if A11y_Native_Observation_Report.Is_Native_Conformance_Ready then
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      else
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      end if;
   else
      Ada.Text_IO.Put (A11y_Native_Observation_Report.Markdown);
   end if;
end Native_Observation_Report;
