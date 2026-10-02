with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;

with NSAX_Router_Test_Suite;

procedure NSAX_Router_Tests is
   task type Suite_Task with Storage_Size => 256 * 1_024 * 1_024;

   task body Suite_Task is
   begin
      NSAX_Router_Test_Suite.Run;
   exception
      when Error : others =>
         Ada.Text_IO.Put_Line
           ("FAIL NSAccessibility router suite raised "
            & Ada.Exceptions.Exception_Information (Error));
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end Suite_Task;

   Runner : Suite_Task;
begin
   null;
end NSAX_Router_Tests;
