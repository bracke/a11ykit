with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with A11y.Capabilities;
with A11y.Geometry;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Properties;
with A11y.Results;
with A11y.Roles;
with A11y.States;
with A11y.Trees;

procedure Platform_Neutral_Provider_Demo is
   use Ada.Strings.Unbounded;

   Schema : constant String :=
     "org.a11y.example.platform_neutral_provider.v1";

   Application_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1);
   Window_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (2);
   Button_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (3);

   type Demo_Node is new A11y.Nodes.Accessible_Node with record
      Node          : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Node_Role     : A11y.Roles.Role := A11y.Roles.Custom;
      Node_States   : A11y.States.State_Set := A11y.States.Empty_State_Set;
      Node_Caps     : A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.Empty_Capability_Set;
      Parent_Node   : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      First_Child   : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Second_Child  : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Children      : Natural := 0;
      Accessible_Name : Unbounded_String;
      Description_Text : Unbounded_String;
      Box           : A11y.Geometry.Rectangle;
   end record;

   overriding function Id
     (Self : Demo_Node)
      return A11y.Node_Ids.Node_Id is (Self.Node);

   overriding function Role
     (Self : Demo_Node)
      return A11y.Roles.Role is (Self.Node_Role);

   overriding function States
     (Self : Demo_Node)
      return A11y.States.State_Set is (Self.Node_States);

   overriding function Parent
     (Self : Demo_Node)
      return A11y.Node_Ids.Node_Id is (Self.Parent_Node);

   overriding function Child_Count
     (Self : Demo_Node)
      return Natural is (Self.Children);

   overriding function Child_At
     (Self  : Demo_Node;
      Index : Positive)
      return A11y.Node_Ids.Node_Id is
     (if Index = 1 then Self.First_Child
      elsif Index = 2 then Self.Second_Child
      else A11y.Node_Ids.No_Node);

   overriding function Name
     (Self : Demo_Node)
      return A11y.Properties.String_Property is
     (A11y.Properties.Present (To_String (Self.Accessible_Name)));

   overriding function Description
     (Self : Demo_Node)
      return A11y.Properties.String_Property is
     (if Length (Self.Description_Text) = 0 then A11y.Properties.Empty
      else A11y.Properties.Present (To_String (Self.Description_Text)));

   overriding function Bounds
     (Self : Demo_Node)
      return A11y.Geometry.Rectangle is (Self.Box);

   overriding function Capabilities
     (Self : Demo_Node)
      return A11y.Capabilities.Capability_Set is (Self.Node_Caps);

   overriding function Exposure
     (Self : Demo_Node)
      return A11y.Nodes.Exposure_Policy is (A11y.Nodes.Expose_Node);

   function Visible_States return A11y.States.State_Set is
      Result : A11y.States.State_Set := A11y.States.Empty_State_Set;
   begin
      Result (A11y.States.Enabled) := True;
      Result (A11y.States.Sensitive) := True;
      Result (A11y.States.Visible) := True;
      Result (A11y.States.Showing) := True;
      return Result;
   end Visible_States;

   function Button_States return A11y.States.State_Set is
      Result : A11y.States.State_Set := Visible_States;
   begin
      Result (A11y.States.Focusable) := True;
      return Result;
   end Button_States;

   function Button_Capabilities return A11y.Capabilities.Capability_Set is
      Result : A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.Empty_Capability_Set;
   begin
      Result (A11y.Capabilities.Action) := True;
      return Result;
   end Button_Capabilities;

   App_Node : constant Demo_Node :=
     (Node            => Application_Id,
      Node_Role       => A11y.Roles.Application,
      Node_States     => Visible_States,
      Node_Caps       => A11y.Capabilities.Empty_Capability_Set,
      Parent_Node     => A11y.Node_Ids.No_Node,
      First_Child     => Window_Id,
      Second_Child    => A11y.Node_Ids.No_Node,
      Children        => 1,
      Accessible_Name => To_Unbounded_String ("Demo application"),
      Description_Text => Null_Unbounded_String,
      Box             => (Origin => (X => 0, Y => 0),
                          Extent => (Width => 640, Height => 480)));

   Window_Node : constant Demo_Node :=
     (Node            => Window_Id,
      Node_Role       => A11y.Roles.Window,
      Node_States     => Visible_States,
      Node_Caps       => A11y.Capabilities.Empty_Capability_Set,
      Parent_Node     => Application_Id,
      First_Child     => Button_Id,
      Second_Child    => A11y.Node_Ids.No_Node,
      Children        => 1,
      Accessible_Name => To_Unbounded_String ("Main window"),
      Description_Text => Null_Unbounded_String,
      Box             => (Origin => (X => 0, Y => 0),
                          Extent => (Width => 640, Height => 480)));

   Button_Node : constant Demo_Node :=
     (Node            => Button_Id,
      Node_Role       => A11y.Roles.Button,
      Node_States     => Button_States,
      Node_Caps       => Button_Capabilities,
      Parent_Node     => Window_Id,
      First_Child     => A11y.Node_Ids.No_Node,
      Second_Child    => A11y.Node_Ids.No_Node,
      Children        => 0,
      Accessible_Name => To_Unbounded_String ("Continue"),
      Description_Text => To_Unbounded_String ("Advances the demo flow"),
      Box             => (Origin => (X => 24, Y => 24),
                          Extent => (Width => 160, Height => 48)));

   Tree : A11y.Trees.Semantic_Tree;
   Result : A11y.Results.Result;
begin
   if Ada.Command_Line.Argument_Count > 1
     or else
       (Ada.Command_Line.Argument_Count = 1
        and then Ada.Command_Line.Argument (1) /= "--json")
   then
      Ada.Text_IO.Put_Line
        ("usage: platform_neutral_provider_demo [--json]");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   A11y.Trees.Set_Root (Tree, App_Node.Id, Result);
   if A11y.Results.Failed (Result) then
      raise Program_Error with "failed to set accessibility root";
   end if;

   A11y.Trees.Attach (Tree, App_Node.Id, Window_Node.Id, Result);
   if A11y.Results.Failed (Result) then
      raise Program_Error with "failed to attach window";
   end if;

   A11y.Trees.Attach (Tree, Window_Node.Id, Button_Node.Id, Result);
   if A11y.Results.Failed (Result) then
      raise Program_Error with "failed to attach button";
   end if;

   Result := A11y.Trees.Validate (Tree);
   if A11y.Results.Failed (Result) then
      raise Program_Error with "invalid accessibility tree";
   end if;

   if Ada.Command_Line.Argument_Count = 1 then
      Ada.Text_IO.Put_Line
        ("{""schema"": """
         & Schema
         & """, ""tree_valid"": true, ""application"": "
         & A11y.Node_Ids.Image (App_Node.Id)
         & ", ""window"": "
         & A11y.Node_Ids.Image (Window_Node.Id)
         & ", ""button"": "
         & A11y.Node_Ids.Image (Button_Node.Id)
         & ", ""backend_neutral"": true}");
   else
      Ada.Text_IO.Put_Line
        ("ready application="
         & A11y.Node_Ids.Image (App_Node.Id)
         & " window="
         & A11y.Node_Ids.Image (Window_Node.Id)
         & " button="
         & A11y.Node_Ids.Image (Button_Node.Id));
   end if;
end Platform_Neutral_Provider_Demo;
