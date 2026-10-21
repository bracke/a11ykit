--  A window with three list items whose focus moves from one to the next, the
--  way an application's would as a person arrows through a list. Run it with
--  a screen reader active: it should announce the window, then each item as
--  the focus reaches it.
--
--  Usage: focus_walk_demo [seconds per item, default 3]

with Ada.Command_Line;
with Ada.Strings.Unbounded;

with A11ykit;
with A11ykit.Provider;
with A11ykit.Tree;

procedure Focus_Walk_Demo is
   use Ada.Strings.Unbounded;
   use A11ykit;

   Pause : constant Duration :=
     (if Ada.Command_Line.Argument_Count >= 1
      then Duration'Value (Ada.Command_Line.Argument (1)) else 3.0);

   Names : constant array (1 .. 3) of Unbounded_String :=
     [To_Unbounded_String ("first.txt"),
      To_Unbounded_String ("second.txt"),
      To_Unbounded_String ("third.txt")];

   --  The window with the given item focused (0 for none).
   function Window (Focused : Natural) return A11ykit.Tree.Accessibility_Tree is
      Flat : A11ykit.Tree.Node_Vectors.Vector;
   begin
      Flat.Append
        (A11ykit.Tree.Node'(Node_Role   => Role_Window,
                            Bounds      => (X => 0, Y => 0, Width => 400, Height => 300),
                            Name        => To_Unbounded_String ("Focus walk"),
                            Description => Null_Unbounded_String,
                            Node_State  => (others => <>),
                            Parent      => 0));
      Flat.Append
        (A11ykit.Tree.Node'(Node_Role   => Role_List,
                            Bounds      => (X => 0, Y => 0, Width => 400, Height => 300),
                            Name        => To_Unbounded_String ("Files"),
                            Description => Null_Unbounded_String,
                            Node_State  => (others => <>),
                            Parent      => 0));
      for Index in Names'Range loop
         Flat.Append
           (A11ykit.Tree.Node'(Node_Role   => Role_List_Item,
                               Bounds      => (X => 0, Y => 20 * Index, Width => 400, Height => 20),
                               Name        => Names (Index),
                               Description => Null_Unbounded_String,
                               Node_State  => (Enabled => True, Selected => Index = Focused,
                                               Focused => Index = Focused, Active => False),
                               Parent      => 0));
      end loop;
      return A11ykit.Tree.Build (Flat);
   end Window;

   --  Keep answering the screen reader for a while.
   procedure Serve_For (Seconds : Duration) is
      Steps : constant Natural := Natural (Seconds / 0.02);
   begin
      for Step in 1 .. Steps loop
         A11ykit.Provider.Service;
         delay 0.02;
      end loop;
   end Serve_For;
begin
   A11ykit.Provider.Start;
   A11ykit.Provider.Publish (Window (0));
   A11ykit.Provider.Set_Active (True);
   Serve_For (Pause);
   for Index in Names'Range loop
      A11ykit.Provider.Publish (Window (Index));
      Serve_For (Pause);
   end loop;
   A11ykit.Provider.Set_Active (False);
   A11ykit.Provider.Stop;
end Focus_Walk_Demo;
