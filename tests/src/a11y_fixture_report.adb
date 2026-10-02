with Ada.Strings.Unbounded;

with A11y.Documents;
with A11y.Images;
with A11y.Node_Ids;
with A11y.Roles;
with A11y.Windows;
with A11y_Test_Fixtures;

package body A11y_Fixture_Report is
   use Ada.Strings.Unbounded;
   use type A11y.Documents.Document_Role;
   use type A11y.Images.Image_Kind;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Roles.Role;
   use type A11y.Windows.Surface_Kind;
   use type A11y_Test_Fixtures.Command_Kind;

   function Q (Value : String) return String is
      Result : Unbounded_String;
   begin
      Append (Result, '"');
      for Ch of Value loop
         case Ch is
            when '"' =>
               Append (Result, "\""");
            when '\' =>
               Append (Result, "\\");
            when Character'Val (8) =>
               Append (Result, "\b");
            when Character'Val (9) =>
               Append (Result, "\t");
            when Character'Val (10) =>
               Append (Result, "\n");
            when Character'Val (12) =>
               Append (Result, "\f");
            when Character'Val (13) =>
               Append (Result, "\r");
            when others =>
               if Character'Pos (Ch) < 32 then
                  Append (Result, ' ');
               else
                  Append (Result, Ch);
               end if;
         end case;
      end loop;
      Append (Result, '"');
      return To_String (Result);
   end Q;

   function Bool (Value : Boolean) return String is
     (if Value then "true" else "false");

   function Command_Name
     (Kind : A11y_Test_Fixtures.Command_Kind)
      return String is
     (A11y_Test_Fixtures.Command_Kind'Image (Kind));

   function Has_Role (Role : A11y.Roles.Role) return Boolean is
      Nodes : constant A11y_Test_Fixtures.Node_Vectors.Vector :=
        A11y_Test_Fixtures.Nodes;
   begin
      for Node of Nodes loop
         if Node.Role = Role then
            return True;
         end if;
      end loop;
      return False;
   end Has_Role;

   function Has_Command
     (Kind : A11y_Test_Fixtures.Command_Kind)
      return Boolean
   is
      Commands : constant A11y_Test_Fixtures.Command_Vectors.Vector :=
        A11y_Test_Fixtures.Script;
   begin
      for Command of Commands loop
         if Command.Kind = Kind then
            return True;
         end if;
      end loop;
      return False;
   end Has_Command;

   function Has_Node (Id : A11y.Node_Ids.Node_Id) return Boolean is
      Nodes : constant A11y_Test_Fixtures.Node_Vectors.Vector :=
        A11y_Test_Fixtures.Nodes;
   begin
      for Node of Nodes loop
         if Node.Id = Id then
            return True;
         end if;
      end loop;
      return False;
   end Has_Node;

   function Protected_Password_Present return Boolean is
      Nodes : constant A11y_Test_Fixtures.Node_Vectors.Vector :=
        A11y_Test_Fixtures.Nodes;
   begin
      for Node of Nodes loop
         if Node.Id = A11y_Test_Fixtures.Password_Field_Id
           and then Node.Role = A11y.Roles.Password_Field
           and then Node.Protected_Text
         then
            return True;
         end if;
      end loop;
      return False;
   end Protected_Password_Present;

   function Image_Coverage_Present return Boolean is
      Nodes : constant A11y_Test_Fixtures.Node_Vectors.Vector :=
        A11y_Test_Fixtures.Nodes;
      Has_Informative : Boolean := False;
      Has_Decorative : Boolean := False;
   begin
      for Node of Nodes loop
         if Node.Id = A11y_Test_Fixtures.Informative_Image_Id
           and then Node.Role = A11y.Roles.Image
           and then Node.Image.Kind = A11y.Images.Informative
           and then A11y.Images.Has_Text_Alternative (Node.Image)
         then
            Has_Informative := True;
         elsif Node.Id = A11y_Test_Fixtures.Decorative_Image_Id
           and then Node.Role = A11y.Roles.Image
           and then Node.Image.Kind = A11y.Images.Decorative
           and then not A11y.Images.Should_Expose (Node.Image)
         then
            Has_Decorative := True;
         end if;
      end loop;
      return Has_Informative and then Has_Decorative;
   end Image_Coverage_Present;

   function Document_Coverage_Present return Boolean is
      Nodes : constant A11y_Test_Fixtures.Node_Vectors.Vector :=
        A11y_Test_Fixtures.Nodes;
      Has_Document : Boolean := False;
      Has_Heading : Boolean := False;
      Has_Link : Boolean := False;
   begin
      for Node of Nodes loop
         if Node.Role = A11y.Roles.Document
           and then Node.Document.Role = A11y.Documents.Document
         then
            Has_Document := True;
         elsif Node.Role = A11y.Roles.Heading
           and then Node.Document.Role = A11y.Documents.Heading
           and then Node.Document.Heading_Level = 1
         then
            Has_Heading := True;
         elsif Node.Id = A11y_Test_Fixtures.Link_Id
           and then Node.Role = A11y.Roles.Link
         then
            Has_Link := True;
         end if;
      end loop;
      return Has_Document and then Has_Heading and then Has_Link;
   end Document_Coverage_Present;

   function Surface_Coverage_Present return Boolean is
      Nodes : constant A11y_Test_Fixtures.Node_Vectors.Vector :=
        A11y_Test_Fixtures.Nodes;
      Has_Window : Boolean := False;
      Has_Modal : Boolean := False;
      Has_Popup : Boolean := False;
   begin
      for Node of Nodes loop
         if Node.Id = A11y_Test_Fixtures.Main_Window_Id
           and then Node.Role = A11y.Roles.Window
         then
            Has_Window := True;
         elsif Node.Surface.Kind = A11y.Windows.Modal_Dialog
           and then A11y.Windows.Is_Modal (Node.Surface)
         then
            Has_Modal := True;
         elsif Node.Id = A11y_Test_Fixtures.Popup_Id
           and then Node.Surface.Kind = A11y.Windows.Popup
           and then
             A11y.Windows.Has_State
               (Node.Surface.State, A11y.Windows.Visible)
         then
            Has_Popup := True;
         end if;
      end loop;
      return Has_Window and then Has_Modal and then Has_Popup;
   end Surface_Coverage_Present;

   function Role_Coverage_Present return Boolean is
     (Has_Role (A11y.Roles.Application)
      and then Has_Role (A11y.Roles.Window)
      and then Has_Role (A11y.Roles.Dialog)
      and then Has_Role (A11y.Roles.Group)
      and then Has_Role (A11y.Roles.Static_Text)
      and then Has_Role (A11y.Roles.Button)
      and then Has_Role (A11y.Roles.Toggle_Button)
      and then Has_Role (A11y.Roles.Check_Box)
      and then Has_Role (A11y.Roles.Radio_Button)
      and then Has_Role (A11y.Roles.Text_Field)
      and then Has_Role (A11y.Roles.Password_Field)
      and then Has_Role (A11y.Roles.Slider)
      and then Has_Role (A11y.Roles.Progress_Bar)
      and then Has_Role (A11y.Roles.Spin_Button)
      and then Has_Role (A11y.Roles.List)
      and then Has_Role (A11y.Roles.List_Item)
      and then Has_Role (A11y.Roles.Tree)
      and then Has_Role (A11y.Roles.Tree_Item)
      and then Has_Role (A11y.Roles.Table)
      and then Has_Role (A11y.Roles.Row)
      and then Has_Role (A11y.Roles.Column)
      and then Has_Role (A11y.Roles.Cell)
      and then Has_Role (A11y.Roles.Menu_Bar)
      and then Has_Role (A11y.Roles.Menu)
      and then Has_Role (A11y.Roles.Menu_Item)
      and then Has_Role (A11y.Roles.Tab_List)
      and then Has_Role (A11y.Roles.Tab)
      and then Has_Role (A11y.Roles.Document)
      and then Has_Role (A11y.Roles.Image)
      and then Has_Role (A11y.Roles.Tooltip)
      and then Has_Role (A11y.Roles.Status)
      and then Has_Role (A11y.Roles.Alert));

   function Script_Coverage_Present return Boolean is
   begin
      for Kind in A11y_Test_Fixtures.Command_Kind loop
         if not Has_Command (Kind) then
            return False;
         end if;
      end loop;
      return True;
   end Script_Coverage_Present;

   function Node_Count return Natural is
     (Natural (A11y_Test_Fixtures.Nodes.Length));

   function Command_Count return Natural is
     (Natural (A11y_Test_Fixtures.Script.Length));

   function Complete return Boolean is
     (Has_Node (A11y_Test_Fixtures.Application_Id)
      and then Has_Node (A11y_Test_Fixtures.Main_Window_Id)
      and then Role_Coverage_Present
      and then Protected_Password_Present
      and then Image_Coverage_Present
      and then Document_Coverage_Present
      and then Surface_Coverage_Present
      and then Script_Coverage_Present);

   function Markdown return String is
      Result : Unbounded_String;
      Nodes : constant A11y_Test_Fixtures.Node_Vectors.Vector :=
        A11y_Test_Fixtures.Nodes;
      Commands : constant A11y_Test_Fixtures.Command_Vectors.Vector :=
        A11y_Test_Fixtures.Script;
   begin
      Append (Result, "# a11y Fixture Report" & ASCII.LF & ASCII.LF);
      Append
        (Result,
         "- schema: " & Schema & ASCII.LF
         & "- nodes:" & Natural'Image (Node_Count) & ASCII.LF
         & "- commands:" & Natural'Image (Command_Count) & ASCII.LF
         & "- complete: " & Bool (Complete) & ASCII.LF & ASCII.LF);

      Append (Result, "## Nodes" & ASCII.LF & ASCII.LF);
      Append (Result, "| Node | Role | Name | Protected |" & ASCII.LF);
      Append (Result, "| --- | --- | --- | --- |" & ASCII.LF);
      for Node of Nodes loop
         Append
           (Result,
            "| "
            & A11y.Node_Ids.Image (Node.Id)
            & " | "
            & A11y.Roles.Stable_Name (Node.Role)
            & " | "
            & To_String (Node.Name)
            & " | "
            & Bool (Node.Protected_Text)
            & " |"
            & ASCII.LF);
      end loop;

      Append (Result, ASCII.LF & "## Script" & ASCII.LF & ASCII.LF);
      Append (Result, "| Command | Target |" & ASCII.LF);
      Append (Result, "| --- | --- |" & ASCII.LF);
      for Command of Commands loop
         Append
           (Result,
            "| "
            & Command_Name (Command.Kind)
            & " | "
            & A11y.Node_Ids.Image (Command.Target)
            & " |"
            & ASCII.LF);
      end loop;

      return To_String (Result);
   end Markdown;

   function JSON return String is
      Result : Unbounded_String;
      Nodes : constant A11y_Test_Fixtures.Node_Vectors.Vector :=
        A11y_Test_Fixtures.Nodes;
      Commands : constant A11y_Test_Fixtures.Command_Vectors.Vector :=
        A11y_Test_Fixtures.Script;
      First : Boolean := True;
   begin
      Append (Result, "{" & ASCII.LF);
      Append (Result, "  ""schema"": " & Q (Schema) & "," & ASCII.LF);
      Append
        (Result,
         "  ""node_count"": " & Natural'Image (Node_Count) & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""command_count"": " & Natural'Image (Command_Count) & ","
         & ASCII.LF);
      Append (Result, "  ""complete"": " & Bool (Complete) & "," & ASCII.LF);
      Append (Result, "  ""nodes"": [" & ASCII.LF);

      for Node of Nodes loop
         if First then
            First := False;
         else
            Append (Result, "," & ASCII.LF);
         end if;

         Append
           (Result,
            "    {"
            & """id"": "
            & Q (A11y.Node_Ids.Image (Node.Id))
            & ", ""role"": "
            & Q (A11y.Roles.Stable_Name (Node.Role))
            & ", ""name"": "
            & Q (To_String (Node.Name))
            & ", ""protected_text"": "
            & Bool (Node.Protected_Text)
            & ", ""image_kind"": "
            & Q (A11y.Images.Stable_Name (Node.Image.Kind))
            & ", ""document_role"": "
            & Q (A11y.Documents.Stable_Name (Node.Document.Role))
            & ", ""heading_level"": "
            & Natural'Image (Node.Document.Heading_Level)
            & ", ""surface_kind"": "
            & Q (A11y.Windows.Stable_Name (Node.Surface.Kind))
            & ", ""surface_modal"": "
            & Bool (Node.Surface.State.Modal)
            & ", ""surface_visible"": "
            & Bool (Node.Surface.State.Visible)
            & "}");
      end loop;

      Append (Result, ASCII.LF & "  ]," & ASCII.LF);
      Append (Result, "  ""script"": [" & ASCII.LF);
      First := True;

      for Command of Commands loop
         if First then
            First := False;
         else
            Append (Result, "," & ASCII.LF);
         end if;

         Append
           (Result,
            "    {"
            & """command"": "
            & Q (Command_Name (Command.Kind))
            & ", ""target"": "
            & Q (A11y.Node_Ids.Image (Command.Target))
            & "}");
      end loop;

      Append (Result, ASCII.LF & "  ]" & ASCII.LF & "}" & ASCII.LF);
      return To_String (Result);
   end JSON;

end A11y_Fixture_Report;
