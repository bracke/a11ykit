with Ada.Command_Line;
with Ada.Text_IO;

with A11y_Public_Surface_Audit;

procedure Public_Surface_Audit is
begin
   if Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--json"
   then
      Ada.Text_IO.Put (A11y_Public_Surface_Audit.JSON);
   else
      Ada.Text_IO.Put (A11y_Public_Surface_Audit.Markdown);
   end if;
end Public_Surface_Audit;
