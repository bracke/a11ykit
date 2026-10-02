package body A11y.Node_Keys is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;

   function Key_Index
     (Self : Key_Registry;
      Key  : String)
      return Natural
   is
   begin
      if Self.Items.Is_Empty then
         return 0;
      end if;

      for Index in Self.Items.First_Index .. Self.Items.Last_Index loop
         if To_String (Self.Items (Index).Key) = Key then
            return Index;
         end if;
      end loop;
      return 0;
   end Key_Index;

   function Node_Index
     (Self : Key_Registry;
      Node : A11y.Node_Ids.Node_Id)
      return Natural
   is
   begin
      if Self.Items.Is_Empty then
         return 0;
      end if;

      for Index in Self.Items.First_Index .. Self.Items.Last_Index loop
         if Self.Items (Index).Node = Node then
            return Index;
         end if;
      end loop;
      return 0;
   end Node_Index;

   procedure Configure_Limits
     (Self   : in out Key_Registry;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
   is
      Candidate : Natural;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Candidate := Natural
        (A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Virtual_Node_Realization));
      if Natural (Self.Items.Length) > Candidate then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      Self.Limit := Candidate;
      Result := A11y.Results.Ok;
   end Configure_Limits;

   procedure Bind
     (Self   : in out Key_Registry;
      Key    : String;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
      Existing_Key  : Natural;
      Existing_Node : Natural;
   begin
      if Key'Length = 0 or else not A11y.Node_Ids.Is_Valid (Node) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      Existing_Key := Key_Index (Self, Key);
      if Existing_Key /= 0 then
         Result :=
           (Status =>
              (if Self.Items (Existing_Key).Node = Node
               then A11y.Results.Success
               else A11y.Results.Invalid_State));
         return;
      end if;

      Existing_Node := Node_Index (Self, Node);
      if Existing_Node /= 0 then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      if Natural (Self.Items.Length) >= Self.Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      Self.Items.Append
        (Binding'(Key => To_Unbounded_String (Key), Node => Node));
      Result := A11y.Results.Ok;
   end Bind;

   procedure Unbind_Key
     (Self   : in out Key_Registry;
      Key    : String;
      Result : out A11y.Results.Result)
   is
      Index : constant Natural := Key_Index (Self, Key);
   begin
      if Key'Length = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif Index = 0 then
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Self.Items.Delete (Index);
         Result := A11y.Results.Ok;
      end if;
   end Unbind_Key;

   procedure Unbind_Node
     (Self   : in out Key_Registry;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
      Index : Natural;
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      Index := Node_Index (Self, Node);
      if Index = 0 then
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Self.Items.Delete (Index);
         Result := A11y.Results.Ok;
      end if;
   end Unbind_Node;

   function Lookup
     (Self : Key_Registry;
      Key  : String)
      return A11y.Node_Ids.Node_Id
   is
      Index : constant Natural := Key_Index (Self, Key);
   begin
      if Index = 0 then
         return A11y.Node_Ids.No_Node;
      end if;
      return Self.Items (Index).Node;
   end Lookup;

   function Count (Self : Key_Registry) return Natural is
     (Natural (Self.Items.Length));

   function Capacity (Self : Key_Registry) return Natural is
     (Self.Limit);

end A11y.Node_Keys;
