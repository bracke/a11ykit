with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Strings.Unbounded;

with A11ykit;
with A11ykit.Tree;
with A11ykit.Provider;

--  Exercises the platform-agnostic core: the flat-to-hierarchy inference and the
--  provider's availability contract. The per-OS providers are unimplemented, so
--  there is nothing host-specific to test here yet.
procedure A11ykit_Tests is
   use Ada.Strings.Unbounded;
   use A11ykit;
   use A11ykit.Tree;

   Failures : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Ada.Text_IO.Put_Line ("ok   " & Message);
      else
         Ada.Text_IO.Put_Line ("FAIL " & Message);
         Failures := Failures + 1;
      end if;
   end Check;

   function Make
     (Item_Role : Role;
      X, Y, W, H : Natural;
      Name       : String;
      Focused    : Boolean := False)
      return Node
   is
      Result : Node;
   begin
      Result.Node_Role := Item_Role;
      Result.Bounds := (X => X, Y => Y, Width => W, Height => H);
      Result.Name := To_Unbounded_String (Name);
      Result.Node_State.Focused := Focused;
      return Result;
   end Make;

   Flat : Node_Vectors.Vector;
   Tree : Accessibility_Tree;
begin
   --  A window enclosing a toolbar (which holds a button) and a list. The button
   --  sits inside both the window and the toolbar, so the tightest container --
   --  the toolbar -- must win.
   Flat.Append (Make (Role_Window, 0, 0, 100, 100, "window"));
   Flat.Append (Make (Role_Toolbar, 0, 0, 100, 20, "toolbar"));
   Flat.Append (Make (Role_Button, 0, 0, 20, 20, "button", Focused => True));
   Flat.Append (Make (Role_List, 0, 20, 100, 80, "list"));

   Tree := Build (Flat);

   Check (Tree.Nodes (1).Parent = 0, "the outermost node (window) is the root");
   Check (Tree.Nodes (2).Parent = 1, "the toolbar nests under the window");
   Check
     (Tree.Nodes (3).Parent = 2,
      "the button nests under the tightest container (toolbar), not the window");
   Check (Tree.Nodes (4).Parent = 1, "the list nests under the window, not the toolbar");
   Check (Tree.Focused = 3, "the focused node is located");

   Check (Natural (Children_Of (Tree, 0).Length) = 1, "there is one root node");
   Check (Natural (Children_Of (Tree, 1).Length) = 2, "the window has two children");
   Check (Natural (Children_Of (Tree, 2).Length) = 1, "the toolbar has one child");
   Check (Natural (Children_Of (Tree, 3).Length) = 0, "the button is a leaf");

   --  Provider contract: no host provider is implemented yet, so it reports
   --  unavailable, and Start/Publish are safe no-ops.
   Check (not A11ykit.Provider.Available, "no host provider is available yet");
   A11ykit.Provider.Start;
   A11ykit.Provider.Publish (Tree);
   A11ykit.Provider.Stop;
   Check (A11ykit.Provider.Backend_Name'Length > 0, "the platform names its target backend");

   if Failures = 0 then
      Ada.Text_IO.Put_Line ("All a11ykit tests passed.");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line (Failures'Image & " a11ykit test(s) FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end A11ykit_Tests;
