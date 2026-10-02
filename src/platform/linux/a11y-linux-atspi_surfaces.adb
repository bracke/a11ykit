with A11y.Trees.Exposure_Views;

package body A11y.Linux.ATSPi_Surfaces is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Exposure_Policy;

   function Error
     (Status : A11y.Results.Status_Code)
      return Surface_Reply is
     (Kind => Error_Reply, Status => Status);

   function Exposure_Of
     (Snapshot : Surface_Snapshot;
      Node     : A11y.Node_Ids.Node_Id)
      return A11y.Nodes.Exposure_Policy
   is
      Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
   begin
      if Slot not in Snapshot.Exposure'Range then
         return A11y.Nodes.Hide_Node_And_Subtree;
      end if;

      return Snapshot.Exposure (Slot);
   end Exposure_Of;

   function Is_Externally_Exposed
     (Snapshot : Surface_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Boolean
   is
      function Policy_For
        (Current : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy is
        (Exposure_Of (Snapshot, Current));

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Policy_For);

      Parent : A11y.Node_Ids.Node_Id;
      Result : A11y.Results.Result;
   begin
      if not Snapshot.Use_Tree_Projection then
         return True;
      elsif not A11y.Node_Ids.Is_Valid (Snapshot.Root)
        or else not A11y.Node_Ids.Is_Valid (Snapshot.Id)
      then
         return False;
      elsif Snapshot.Id = Snapshot.Root then
         return Exposure_Of (Snapshot, Snapshot.Id) = A11y.Nodes.Expose_Node;
      end if;

      Parent := Exposure_View.Exposed_Parent_Of
        (Snapshot.Tree, Snapshot.Id, Limits, Result);
      return A11y.Results.Succeeded (Result)
        and then A11y.Node_Ids.Is_Valid (Parent);
   exception
      when others =>
         return False;
   end Is_Externally_Exposed;

   function Boolean_Reply_For (Value : Boolean) return Surface_Reply is
     (Kind         => Boolean_Reply,
      Status       => A11y.Results.Success,
      Boolean_Item => Value);

   function Surface_Kind_Name
     (Kind : A11y.Windows.Surface_Kind)
      return String is
     (A11y.Windows.Stable_Name (Kind));

   function Map_Surface_Role
     (Kind : A11y.Windows.Surface_Kind)
      return A11y.Linux.ATSPi_Mappings.ATSPI_Role is
     (case Kind is
        when A11y.Windows.Window |
             A11y.Windows.Sheet |
             A11y.Windows.Palette |
             A11y.Windows.Inspector |
             A11y.Windows.Splash |
             A11y.Windows.Notification |
             A11y.Windows.Utility_Window =>
          A11y.Linux.ATSPi_Mappings.Window,
        when A11y.Windows.Dialog |
             A11y.Windows.Modal_Dialog =>
          A11y.Linux.ATSPi_Mappings.Dialog,
        when A11y.Windows.Menu |
             A11y.Windows.Context_Menu =>
          A11y.Linux.ATSPi_Mappings.Menu,
        when A11y.Windows.Tooltip =>
          A11y.Linux.ATSPi_Mappings.Tool_Tip,
        when A11y.Windows.Popup |
             A11y.Windows.Popover |
             A11y.Windows.Embedded_Surface =>
          A11y.Linux.ATSPi_Mappings.Panel);

   function Map_Surface_States
     (Metadata : A11y.Windows.Surface_Metadata)
      return A11y.Linux.ATSPi_Mappings.ATSPI_State_Set
   is
      Result : A11y.Linux.ATSPi_Mappings.ATSPI_State_Set :=
        A11y.Linux.ATSPi_Mappings.Empty_ATSPI_State_Set;
   begin
      if Metadata.State.Visible then
         Result (A11y.Linux.ATSPi_Mappings.Visible) := True;
         Result (A11y.Linux.ATSPi_Mappings.Showing) := True;
      end if;

      if Metadata.State.Active then
         Result (A11y.Linux.ATSPi_Mappings.Active) := True;
      end if;

      if A11y.Windows.Is_Modal (Metadata) then
         Result (A11y.Linux.ATSPi_Mappings.Modal) := True;
      end if;

      if not Metadata.State.Minimized then
         Result (A11y.Linux.ATSPi_Mappings.Enabled) := True;
         Result (A11y.Linux.ATSPi_Mappings.Sensitive) := True;
      end if;

      return Result;
   end Map_Surface_States;

   function Query_Surface
     (Snapshot : Surface_Snapshot;
      Query    : Surface_Query)
      return Surface_Reply is
     (Query_Surface (Snapshot, Query, Snapshot.Limits));

   function Query_Surface
     (Snapshot : Surface_Snapshot;
      Query    : Surface_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Surface_Reply is
      Result : A11y.Results.Result;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif Snapshot.Defunct
        or else not Is_Externally_Exposed (Snapshot, Limits)
      then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      Result := A11y.Windows.Validate (Snapshot.Metadata);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      case Query is
         when Kind_Name =>
            if A11y.Resource_Limits.Exceeded
              (Limits,
               A11y.Resource_Limits.Native_String_Size,
               Surface_Kind_Name (Snapshot.Metadata.Kind)'Length)
            then
               return Error (A11y.Results.Resource_Limit);
            end if;

            return
              (Kind   => String_Reply,
               Status => A11y.Results.Success,
               Text   =>
                 To_Unbounded_String
                   (Surface_Kind_Name (Snapshot.Metadata.Kind)));
         when Surface_Role =>
            return
              (Kind   => Role_Reply,
               Status => A11y.Results.Success,
               Role   => Map_Surface_Role (Snapshot.Metadata.Kind));
         when Surface_States =>
            return
              (Kind   => State_Set_Reply,
               Status => A11y.Results.Success,
               States => Map_Surface_States (Snapshot.Metadata));
         when Is_Top_Level =>
            return Boolean_Reply_For
              (A11y.Windows.Is_Top_Level (Snapshot.Metadata.Kind));
         when Is_Modal =>
            return Boolean_Reply_For
              (A11y.Windows.Is_Modal (Snapshot.Metadata));
         when Is_Visible =>
            return Boolean_Reply_For (Snapshot.Metadata.State.Visible);
         when Is_Active =>
            return Boolean_Reply_For (Snapshot.Metadata.State.Active);
         when Is_Minimized =>
            return Boolean_Reply_For (Snapshot.Metadata.State.Minimized);
         when Is_Maximized =>
            return Boolean_Reply_For (Snapshot.Metadata.State.Maximized);
         when Is_Fullscreen =>
            return Boolean_Reply_For (Snapshot.Metadata.State.Fullscreen);
         when Can_Close =>
            return Boolean_Reply_For (Snapshot.Metadata.State.Closable);
         when Can_Resize =>
            return Boolean_Reply_For (Snapshot.Metadata.State.Resizable);
         when Can_Move =>
            return Boolean_Reply_For (Snapshot.Metadata.State.Movable);
      end case;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Query_Surface;

end A11y.Linux.ATSPi_Surfaces;
