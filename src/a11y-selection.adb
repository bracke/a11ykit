with A11y.Selection.Classification;

package body A11y.Selection is
   use type A11y.Node_Ids.Node_Id;

   None_Name                : aliased constant String := "none";
   Single_Name              : aliased constant String := "single";
   Multiple_Name            : aliased constant String := "multiple";
   Contiguous_Multiple_Name : aliased constant String := "contiguous-multiple";
   Extended_Name            : aliased constant String := "extended";
   No_Direction_Name        : aliased constant String := "none";
   Forward_Name             : aliased constant String := "forward";
   Backward_Name            : aliased constant String := "backward";
   Unknown_Name             : aliased constant String := "unknown";

   function Metadata (Mode : Selection_Mode) return Selection_Mode_Metadata is
     (case Mode is
        when None =>
          (Stable_Name => None_Name'Access,
           Allows_Selection => False,
           Allows_Multiple => False,
           Allows_Range => False),
        when Single =>
          (Stable_Name => Single_Name'Access,
           Allows_Selection => True,
           Allows_Multiple => False,
           Allows_Range => False),
        when Multiple =>
          (Stable_Name => Multiple_Name'Access,
           Allows_Selection => True,
           Allows_Multiple => True,
           Allows_Range => False),
        when Contiguous_Multiple =>
          (Stable_Name => Contiguous_Multiple_Name'Access,
           Allows_Selection => True,
           Allows_Multiple => True,
           Allows_Range => True),
        when Extended =>
          (Stable_Name => Extended_Name'Access,
           Allows_Selection => True,
           Allows_Multiple => True,
           Allows_Range => True));

   function Stable_Name (Mode : Selection_Mode) return String is
     (Metadata (Mode).Stable_Name.all);

   function Stable_Name (Direction : Selection_Direction) return String is
     (case Direction is
        when No_Direction => No_Direction_Name,
        when Forward => Forward_Name,
        when Backward => Backward_Name,
        when Unknown => Unknown_Name);

   function Allows_Selection
     (Mode : Selection_Mode)
      return Standard.Boolean is
     (A11y.Selection.Classification.Allows_Selection (Mode))
   with SPARK_Mode => On;

   function Allows_Multiple
     (Mode : Selection_Mode)
      return Standard.Boolean is
     (A11y.Selection.Classification.Allows_Multiple (Mode))
   with SPARK_Mode => On;

   function Allows_Range
     (Mode : Selection_Mode)
      return Standard.Boolean is
     (A11y.Selection.Classification.Allows_Range (Mode))
   with SPARK_Mode => On;

   function Allows_Required_Selection
     (Mode : Selection_Mode)
      return Standard.Boolean is
     (A11y.Selection.Classification.Allows_Required_Selection (Mode))
   with SPARK_Mode => On;

   function Count_Allowed
     (Mode  : Selection_Mode;
      Count : Natural)
      return Standard.Boolean is
     (A11y.Selection.Classification.Count_Allowed (Mode, Count))
   with SPARK_Mode => On;

   function Is_Known_Direction
     (Direction : Selection_Direction)
      return Standard.Boolean is
     (A11y.Selection.Classification.Is_Known_Direction (Direction))
   with SPARK_Mode => On;

   function Is_Range_Direction
     (Direction : Selection_Direction)
      return Standard.Boolean is
     (A11y.Selection.Classification.Is_Range_Direction (Direction))
   with SPARK_Mode => On;

   function Direction_Allowed
     (Mode      : Selection_Mode;
      Direction : Selection_Direction)
      return Standard.Boolean is
     (A11y.Selection.Classification.Direction_Allowed (Mode, Direction))
   with SPARK_Mode => On;

   function Empty_Metadata return Selection_Metadata is
     (Selection_Mode     => None,
      Selection_Required => False,
      Limit              => Max_Selected_Items,
      Selected_Count     => 0,
      Anchor_Node        => A11y.Node_Ids.No_Node,
      Current_Node       => A11y.Node_Ids.No_Node,
      Range_Direction    => No_Direction)
   with SPARK_Mode => On;

   function Mode (Self : Selection_Metadata) return Selection_Mode is
     (Self.Selection_Mode)
   with SPARK_Mode => On;

   function Requires_Selection (Self : Selection_Metadata) return Boolean is
     (Self.Selection_Required)
   with SPARK_Mode => On;

   function Count (Self : Selection_Metadata) return Natural is
     (Self.Selected_Count)
   with SPARK_Mode => On;

   function Capacity (Self : Selection_Metadata) return Natural is
     (Self.Limit)
   with SPARK_Mode => On;

   function Anchor (Self : Selection_Metadata) return A11y.Node_Ids.Node_Id is
     (Self.Anchor_Node)
   with SPARK_Mode => On;

   function Current_Item
     (Self : Selection_Metadata)
      return A11y.Node_Ids.Node_Id is
     (Self.Current_Node)
   with SPARK_Mode => On;

   function Direction (Self : Selection_Metadata) return Selection_Direction is
     (Self.Range_Direction)
   with SPARK_Mode => On;

   function Metadata_Of (Self : Selection_Set) return Selection_Metadata is
     (Self.Metadata);

   function Mode (Self : Selection_Set) return Selection_Mode is
     (Mode (Self.Metadata));

   function Requires_Selection (Self : Selection_Set) return Boolean is
     (Requires_Selection (Self.Metadata));

   function Count (Self : Selection_Set) return Natural is
     (Count (Self.Metadata));

   function Capacity (Self : Selection_Set) return Natural is
     (Capacity (Self.Metadata));

   function Contains
     (Self : Selection_Set;
      Node : A11y.Node_Ids.Node_Id)
      return Boolean
   is
   begin
      for Item of Self.Selected loop
         if Item = Node then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   function Selected_At
     (Self  : Selection_Set;
      Index : Positive)
      return A11y.Node_Ids.Node_Id
   is
   begin
      if Index > Natural (Self.Selected.Length) then
         return A11y.Node_Ids.No_Node;
      end if;
      return Self.Selected (Index);
   end Selected_At;

   function Items (Self : Selection_Set) return Node_Vectors.Vector is
     (Self.Selected);

   function Anchor (Self : Selection_Set) return A11y.Node_Ids.Node_Id is
     (Anchor (Self.Metadata));

   function Current_Item (Self : Selection_Set) return A11y.Node_Ids.Node_Id is
     (Current_Item (Self.Metadata));

   function Direction (Self : Selection_Set) return Selection_Direction is
      Anchor_Index  : Natural := 0;
      Current_Index : Natural := 0;
   begin
      if not A11y.Node_Ids.Is_Valid (Self.Metadata.Anchor_Node)
        or else not A11y.Node_Ids.Is_Valid (Self.Metadata.Current_Node)
      then
         return No_Direction;
      elsif Self.Metadata.Anchor_Node = Self.Metadata.Current_Node then
         return No_Direction;
      end if;

      for Index in 1 .. Natural (Self.Selected.Length) loop
         if Self.Selected (Index) = Self.Metadata.Anchor_Node then
            Anchor_Index := Index;
         elsif Self.Selected (Index) = Self.Metadata.Current_Node then
            Current_Index := Index;
         end if;
      end loop;

      if Anchor_Index = 0 or else Current_Index = 0 then
         return Unknown;
      elsif Self.Metadata.Range_Direction = No_Direction then
         return Unknown;
      else
         return Self.Metadata.Range_Direction;
      end if;
   end Direction;

   function Validate (Self : Selection_Set) return A11y.Results.Result is
      Count : constant Natural := Natural (Self.Selected.Length);
   begin
      if Self.Metadata.Selected_Count /= Count then
         return (Status => A11y.Results.Invalid_State);
      elsif Self.Metadata.Limit = 0
        or else Self.Metadata.Limit > Max_Selected_Items
      then
         return (Status => A11y.Results.Invalid_State);
      elsif Count > Self.Metadata.Limit then
         return (Status => A11y.Results.Resource_Limit);
      elsif Self.Metadata.Selection_Mode = None
        and then (Count > 0 or else Self.Metadata.Selection_Required)
      then
         return (Status => A11y.Results.Invalid_State);
      elsif Self.Metadata.Selection_Mode = None
        and then A11y.Node_Ids.Is_Valid (Self.Metadata.Current_Node)
      then
         return (Status => A11y.Results.Invalid_State);
      elsif Self.Metadata.Selection_Required and then Count = 0 then
         return (Status => A11y.Results.Invalid_State);
      elsif Self.Metadata.Selection_Mode = Single and then Count > 1 then
         return (Status => A11y.Results.Invalid_State);
      elsif Count = 0
        and then A11y.Node_Ids.Is_Valid (Self.Metadata.Anchor_Node)
      then
         return (Status => A11y.Results.Invalid_State);
      elsif Count > 0
        and then not A11y.Node_Ids.Is_Valid (Self.Metadata.Anchor_Node)
      then
         return (Status => A11y.Results.Node_Unavailable);
      elsif Self.Metadata.Current_Node /= A11y.Node_Ids.No_Node
        and then not A11y.Node_Ids.Is_Valid (Self.Metadata.Current_Node)
      then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      for Index in 1 .. Count loop
         if not A11y.Node_Ids.Is_Valid (Self.Selected (Index)) then
            return (Status => A11y.Results.Node_Unavailable);
         end if;

         for Other in Index + 1 .. Count loop
            if Self.Selected (Index) = Self.Selected (Other) then
               return (Status => A11y.Results.Invalid_State);
            end if;
         end loop;
      end loop;

      if A11y.Node_Ids.Is_Valid (Self.Metadata.Anchor_Node)
        and then not Contains (Self, Self.Metadata.Anchor_Node)
      then
         return (Status => A11y.Results.Invalid_State);
      end if;

      return A11y.Results.Ok;
   end Validate;

   procedure Configure
     (Self               : in out Selection_Set;
      Mode               : Selection_Mode;
      Requires_Selection : Boolean := False)
   is
   begin
      Self.Metadata.Selection_Mode := Mode;
      Self.Metadata.Selection_Required := Requires_Selection;
      if Mode = None then
         Self.Selected.Clear;
         Self.Metadata.Selected_Count := 0;
         Self.Metadata.Anchor_Node := A11y.Node_Ids.No_Node;
         Self.Metadata.Current_Node := A11y.Node_Ids.No_Node;
         Self.Metadata.Range_Direction := No_Direction;
      elsif Mode = Single and then Natural (Self.Selected.Length) > 1 then
         declare
            First : constant A11y.Node_Ids.Node_Id := Self.Selected.First_Element;
         begin
            Self.Selected.Clear;
            Self.Selected.Append (First);
            Self.Metadata.Selected_Count := 1;
            Self.Metadata.Anchor_Node := First;
            Self.Metadata.Range_Direction := No_Direction;
         end;
      else
         Self.Metadata.Selected_Count := Natural (Self.Selected.Length);
      end if;
   end Configure;

   procedure Configure_Limits
     (Self   : in out Selection_Set;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
   is
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Set_Capacity
        (Self,
         Natural
           (A11y.Resource_Limits.Value
              (Limits, A11y.Resource_Limits.Selection_Items_Materialized)),
         Result);
   end Configure_Limits;

   procedure Set_Capacity
     (Self     : in out Selection_Set;
      Capacity : Natural;
      Result   : out A11y.Results.Result)
   is
   begin
      if Capacity = 0 or else Capacity > Max_Selected_Items then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif Capacity < Natural (Self.Selected.Length) then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Self.Metadata.Limit := Capacity;
         Result := A11y.Results.Ok;
      end if;
   end Set_Capacity;

   procedure Select_Item
     (Self   : in out Selection_Set;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif not Allows_Selection (Self.Metadata.Selection_Mode) then
         Result := (Status => A11y.Results.Unsupported_Capability);
      elsif Contains (Self, Node) then
         Result := A11y.Results.Ok;
      elsif Self.Metadata.Selection_Mode = Single then
         Self.Selected.Clear;
         Self.Selected.Append (Node);
         Self.Metadata.Selected_Count := 1;
         Self.Metadata.Anchor_Node := Node;
         Self.Metadata.Range_Direction := No_Direction;
         Result := A11y.Results.Ok;
      elsif Natural (Self.Selected.Length) >= Self.Metadata.Limit then
         Result := (Status => A11y.Results.Resource_Limit);
      else
         Self.Selected.Append (Node);
         Self.Metadata.Selected_Count := Natural (Self.Selected.Length);
         if not A11y.Node_Ids.Is_Valid (Self.Metadata.Anchor_Node) then
            Self.Metadata.Anchor_Node := Node;
         end if;
         Result := A11y.Results.Ok;
      end if;
   end Select_Item;

   procedure Deselect
     (Self   : in out Selection_Set;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      if not Self.Selected.Is_Empty then
         for Index in Self.Selected.First_Index .. Self.Selected.Last_Index loop
            if Self.Selected (Index) = Node then
               if Self.Metadata.Selection_Required
                 and then Natural (Self.Selected.Length) = 1
               then
                  Result := (Status => A11y.Results.Invalid_State);
                  return;
               end if;

               Self.Selected.Delete (Index);
               Self.Metadata.Selected_Count := Natural (Self.Selected.Length);
               if Self.Metadata.Anchor_Node = Node then
                  Self.Metadata.Anchor_Node :=
                    (if Self.Selected.Is_Empty
                     then A11y.Node_Ids.No_Node
                     else Self.Selected.First_Element);
               end if;
               if Self.Selected.Is_Empty then
                  Self.Metadata.Range_Direction := No_Direction;
               elsif not Contains (Self, Self.Metadata.Current_Node) then
                  Self.Metadata.Range_Direction := Unknown;
               end if;
               Result := A11y.Results.Ok;
               return;
            end if;
         end loop;
      end if;

      Result := A11y.Results.Ok;
   end Deselect;

   procedure Toggle
     (Self   : in out Selection_Set;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
   begin
      if Contains (Self, Node) then
         Deselect (Self, Node, Result);
      else
         Select_Item (Self, Node, Result);
      end if;
   end Toggle;

   function Contains
     (Items : Node_Vectors.Vector;
      Node  : A11y.Node_Ids.Node_Id)
      return Boolean
   is
   begin
      for Item of Items loop
         if Item = Node then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   procedure Select_Range
     (Self   : in out Selection_Set;
      Nodes  : Node_Vectors.Vector;
      Result : out A11y.Results.Result;
      Direction : Selection_Direction := Forward)
   is
      New_Selected : Node_Vectors.Vector := Self.Selected;
   begin
      if not Allows_Range (Self.Metadata.Selection_Mode) then
         Result := (Status => A11y.Results.Unsupported_Capability);
         return;
      elsif Nodes.Is_Empty then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      elsif Natural (Nodes.Length) > 1 and then Direction = No_Direction then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      for Index in Nodes.First_Index .. Nodes.Last_Index loop
         declare
            Node : constant A11y.Node_Ids.Node_Id := Nodes (Index);
         begin
            if not A11y.Node_Ids.Is_Valid (Node) then
               Result := (Status => A11y.Results.Node_Unavailable);
               return;
            end if;

            for Other in Index + 1 .. Nodes.Last_Index loop
               if Node = Nodes (Other) then
                  Result := (Status => A11y.Results.Invalid_State);
                  return;
               end if;
            end loop;

            if not Contains (New_Selected, Node) then
               if Natural (New_Selected.Length) >= Self.Metadata.Limit then
                  Result := (Status => A11y.Results.Resource_Limit);
                  return;
               end if;
               New_Selected.Append (Node);
            end if;
         end;
      end loop;

      Self.Selected := New_Selected;
      Self.Metadata.Selected_Count := Natural (Self.Selected.Length);
      Self.Metadata.Anchor_Node := Nodes.First_Element;
      Self.Metadata.Current_Node := Nodes.Last_Element;
      Self.Metadata.Range_Direction :=
        (if Natural (Nodes.Length) = 1 then No_Direction else Direction);
      Result := A11y.Results.Ok;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Select_Range;

   procedure Select_All
     (Self   : in out Selection_Set;
      Nodes  : Node_Vectors.Vector;
      Result : out A11y.Results.Result)
   is
      New_Selected : Node_Vectors.Vector;
   begin
      if not Allows_Selection (Self.Metadata.Selection_Mode) then
         Result := (Status => A11y.Results.Unsupported_Capability);
         return;
      elsif Nodes.Is_Empty then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      elsif Natural (Nodes.Length) > 1
        and then not Allows_Multiple (Self.Metadata.Selection_Mode)
      then
         Result := (Status => A11y.Results.Unsupported_Capability);
         return;
      elsif Natural (Nodes.Length) > Self.Metadata.Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      for Index in Nodes.First_Index .. Nodes.Last_Index loop
         declare
            Node : constant A11y.Node_Ids.Node_Id := Nodes (Index);
         begin
            if not A11y.Node_Ids.Is_Valid (Node) then
               Result := (Status => A11y.Results.Node_Unavailable);
               return;
            end if;

            for Other in Index + 1 .. Nodes.Last_Index loop
               if Node = Nodes (Other) then
                  Result := (Status => A11y.Results.Invalid_State);
                  return;
               end if;
            end loop;

            New_Selected.Append (Node);
         end;
      end loop;

      Self.Selected := New_Selected;
      Self.Metadata.Selected_Count := Natural (Self.Selected.Length);
      Self.Metadata.Anchor_Node := Nodes.First_Element;
      Self.Metadata.Current_Node := Nodes.Last_Element;
      Self.Metadata.Range_Direction :=
        (if Natural (Nodes.Length) = 1 then No_Direction else Forward);
      Result := A11y.Results.Ok;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Select_All;

   procedure Clear
     (Self   : in out Selection_Set;
      Result : out A11y.Results.Result)
   is
   begin
      if Self.Metadata.Selection_Required then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      Self.Selected.Clear;
      Self.Metadata.Selected_Count := 0;
      Self.Metadata.Anchor_Node := A11y.Node_Ids.No_Node;
      Self.Metadata.Range_Direction := No_Direction;
      Result := A11y.Results.Ok;
   end Clear;

   procedure Set_Current_Item
     (Self   : in out Selection_Set;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Self.Metadata.Current_Node := Node;
         if Contains (Self, Node)
           and then Contains (Self, Self.Metadata.Anchor_Node)
         then
            Self.Metadata.Range_Direction := Unknown;
         end if;
         Result := A11y.Results.Ok;
      end if;
   end Set_Current_Item;

   procedure Clear_Current_Item
     (Self   : in out Selection_Set;
      Result : out A11y.Results.Result)
   is
   begin
      Self.Metadata.Current_Node := A11y.Node_Ids.No_Node;
      Self.Metadata.Range_Direction := No_Direction;
      Result := A11y.Results.Ok;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Clear_Current_Item;

   function Current_Selection_Safely
     (Self : Selection_Provider'Class)
      return Selection_Set
   is
   begin
      return Self.Current_Selection;
   exception
      when others =>
         return (Metadata => Empty_Metadata,
                 Selected => <>);
   end Current_Selection_Safely;

   function Select_Node_Safely
     (Self : in out Selection_Provider'Class;
      Node : A11y.Node_Ids.Node_Id)
      return A11y.Results.Result
   is
      Snapshot : Selection_Set;
      Candidate : Selection_Set;
      Result : A11y.Results.Result;
   begin
      Snapshot := Self.Current_Selection;
      Result := Validate (Snapshot);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Candidate := Snapshot;
      Select_Item (Candidate, Node, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      return Self.Select_Node (Node);
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Select_Node_Safely;

   function Deselect_Node_Safely
     (Self : in out Selection_Provider'Class;
      Node : A11y.Node_Ids.Node_Id)
      return A11y.Results.Result
   is
      Snapshot : Selection_Set;
      Candidate : Selection_Set;
      Result : A11y.Results.Result;
   begin
      Snapshot := Self.Current_Selection;
      Result := Validate (Snapshot);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Candidate := Snapshot;
      Deselect (Candidate, Node, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      return Self.Deselect_Node (Node);
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Deselect_Node_Safely;

   function Toggle_Node_Safely
     (Self : in out Selection_Provider'Class;
      Node : A11y.Node_Ids.Node_Id)
      return A11y.Results.Result
   is
      Snapshot : Selection_Set;
      Candidate : Selection_Set;
      Result : A11y.Results.Result;
   begin
      Snapshot := Self.Current_Selection;
      Result := Validate (Snapshot);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Candidate := Snapshot;
      Toggle (Candidate, Node, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      return Self.Toggle_Node (Node);
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Toggle_Node_Safely;

   function Clear_Selection_Safely
     (Self : in out Selection_Provider'Class)
      return A11y.Results.Result
   is
      Snapshot : Selection_Set;
      Candidate : Selection_Set;
      Result : A11y.Results.Result;
   begin
      Snapshot := Self.Current_Selection;
      Result := Validate (Snapshot);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Candidate := Snapshot;
      Clear (Candidate, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      return Self.Clear_Selection;
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Clear_Selection_Safely;

end A11y.Selection;
