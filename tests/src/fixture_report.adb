with Ada.Command_Line;
with Ada.Text_IO;

with A11y_Fixture_Report;

procedure Fixture_Report is
begin
   if Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--json"
   then
      Ada.Text_IO.Put (A11y_Fixture_Report.JSON);
   else
      Ada.Text_IO.Put (A11y_Fixture_Report.Markdown);
   end if;
end Fixture_Report;
