package body A11y.Relations is
   use type A11y.Node_Ids.Node_Id;

   Labelled_By_Name          : aliased constant String := "labelled-by";
   Label_For_Name            : aliased constant String := "label-for";
   Described_By_Name         : aliased constant String := "described-by";
   Description_For_Name      : aliased constant String := "description-for";
   Controlled_By_Name        : aliased constant String := "controlled-by";
   Controller_For_Name       : aliased constant String := "controller-for";
   Flows_To_Name             : aliased constant String := "flows-to";
   Flows_From_Name           : aliased constant String := "flows-from";
   Member_Of_Name            : aliased constant String := "member-of";
   Details_Name              : aliased constant String := "details";
   Details_For_Name          : aliased constant String := "details-for";
   Error_Message_Name        : aliased constant String := "error-message";
   Error_For_Name            : aliased constant String := "error-for";
   Active_Descendant_Name    : aliased constant String := "active-descendant";
   Embedded_By_Name          : aliased constant String := "embedded-by";
   Embeds_Name               : aliased constant String := "embeds";
   Popup_For_Name            : aliased constant String := "popup-for";
   Popup_Controlled_By_Name  : aliased constant String :=
     "popup-controlled-by";

   function Metadata (Kind : Relation_Kind) return Relation_Metadata is
     (case Kind is
        when Labelled_By =>
          (Stable_Name => Labelled_By_Name'Access, Inverse => Label_For),
        when Label_For =>
          (Stable_Name => Label_For_Name'Access, Inverse => Labelled_By),
        when Described_By =>
          (Stable_Name => Described_By_Name'Access, Inverse => Description_For),
        when Description_For =>
          (Stable_Name => Description_For_Name'Access, Inverse => Described_By),
        when Controlled_By =>
          (Stable_Name => Controlled_By_Name'Access, Inverse => Controller_For),
        when Controller_For =>
          (Stable_Name => Controller_For_Name'Access, Inverse => Controlled_By),
        when Flows_To =>
          (Stable_Name => Flows_To_Name'Access, Inverse => Flows_From),
        when Flows_From =>
          (Stable_Name => Flows_From_Name'Access, Inverse => Flows_To),
        when Member_Of =>
          (Stable_Name => Member_Of_Name'Access, Inverse => Member_Of),
        when Details =>
          (Stable_Name => Details_Name'Access, Inverse => Details_For),
        when Details_For =>
          (Stable_Name => Details_For_Name'Access, Inverse => Details),
        when Error_Message =>
          (Stable_Name => Error_Message_Name'Access, Inverse => Error_For),
        when Error_For =>
          (Stable_Name => Error_For_Name'Access, Inverse => Error_Message),
        when Active_Descendant =>
          (Stable_Name => Active_Descendant_Name'Access,
           Inverse => Active_Descendant),
        when Embedded_By =>
          (Stable_Name => Embedded_By_Name'Access, Inverse => Embeds),
        when Embeds =>
          (Stable_Name => Embeds_Name'Access, Inverse => Embedded_By),
        when Popup_For =>
          (Stable_Name => Popup_For_Name'Access,
           Inverse => Popup_Controlled_By),
        when Popup_Controlled_By =>
          (Stable_Name => Popup_Controlled_By_Name'Access,
           Inverse => Popup_For));

   function Stable_Name (Kind : Relation_Kind) return String is
     (Metadata (Kind).Stable_Name.all);

   function Is_Self_Inverse
     (Kind : Relation_Kind)
      return Boolean is
     (Kind in Member_Of | Active_Descendant)
   with SPARK_Mode => On;

   function Canonical_Inverse
     (Kind : Relation_Kind)
      return Relation_Kind is
     (case Kind is
        when Labelled_By         => Label_For,
        when Label_For           => Labelled_By,
        when Described_By        => Description_For,
        when Description_For     => Described_By,
        when Controlled_By       => Controller_For,
        when Controller_For      => Controlled_By,
        when Flows_To            => Flows_From,
        when Flows_From          => Flows_To,
        when Member_Of           => Member_Of,
        when Details             => Details_For,
        when Details_For         => Details,
        when Error_Message       => Error_For,
        when Error_For           => Error_Message,
        when Active_Descendant   => Active_Descendant,
        when Embedded_By         => Embeds,
        when Embeds              => Embedded_By,
        when Popup_For           => Popup_Controlled_By,
        when Popup_Controlled_By => Popup_For)
   with SPARK_Mode => On;

   function Inverse (Kind : Relation_Kind) return Relation_Kind is
     (Canonical_Inverse (Kind))
   with SPARK_Mode => On;

   function Is_Canonical_Pair
     (Left  : Relation_Kind;
      Right : Relation_Kind)
      return Boolean is
     (Canonical_Inverse (Left) = Right
      and then Canonical_Inverse (Right) = Left)
   with SPARK_Mode => On;

   function Is_Label_Relation
     (Kind : Relation_Kind)
      return Boolean is
     (Kind in Labelled_By | Label_For)
   with SPARK_Mode => On;

   function Is_Description_Relation
     (Kind : Relation_Kind)
      return Boolean is
     (Kind in Described_By | Description_For | Error_Message | Error_For)
   with SPARK_Mode => On;

   function Is_Control_Relation
     (Kind : Relation_Kind)
      return Boolean is
     (Kind in Controlled_By | Controller_For | Popup_For
      | Popup_Controlled_By | Active_Descendant)
   with SPARK_Mode => On;

   function Allows_Cycles
     (Kind : Relation_Kind)
      return Boolean is
     (Kind in Flows_To | Flows_From | Member_Of)
   with SPARK_Mode => On;

   function Find_Entry
     (Self   : Relation_Graph;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : Relation_Kind)
      return Natural
   is
   begin
      if Self.Entries.Is_Empty then
         return 0;
      end if;

      for Index in Self.Entries.First_Index .. Self.Entries.Last_Index loop
         if Self.Entries (Index).Source = Source
           and then Self.Entries (Index).Kind = Kind
         then
            return Index;
         end if;
      end loop;
      return 0;
   end Find_Entry;

   function Contains
     (Items  : Target_Vectors.Vector;
      Target : A11y.Node_Ids.Node_Id)
      return Boolean
   is
   begin
      for Item of Items loop
         if Item = Target then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   procedure Add_One_Way
     (Self   : in out Relation_Graph;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : Relation_Kind;
      Target : A11y.Node_Ids.Node_Id)
   is
      Index : constant Natural := Find_Entry (Self, Source, Kind);
      Rel : Relation_Record;
   begin
      if Index = 0 then
         Rel.Source := Source;
         Rel.Kind := Kind;
         Rel.Targets.Append (Target);
         Self.Entries.Append (Rel);
      elsif not Contains (Self.Entries (Index).Targets, Target) then
         Rel := Self.Entries (Index);
         Rel.Targets.Append (Target);
         Self.Entries.Replace_Element (Index, Rel);
      end if;
   end Add_One_Way;

   procedure Remove_One_Way
     (Self   : in out Relation_Graph;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : Relation_Kind;
      Target : A11y.Node_Ids.Node_Id)
   is
      Index : constant Natural := Find_Entry (Self, Source, Kind);
      Rel : Relation_Record;
   begin
      if Index = 0 then
         return;
      end if;

      Rel := Self.Entries (Index);
      if not Rel.Targets.Is_Empty then
         for Target_Index in Rel.Targets.First_Index .. Rel.Targets.Last_Index loop
            if Rel.Targets (Target_Index) = Target then
               Rel.Targets.Delete (Target_Index);
               exit;
            end if;
         end loop;
      end if;

      if Rel.Targets.Is_Empty then
         Self.Entries.Delete (Index);
      else
         Self.Entries.Replace_Element (Index, Rel);
      end if;
   end Remove_One_Way;

   function Targets
     (Self   : Relation_Graph;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : Relation_Kind)
      return Target_Vectors.Vector
   is
      Index : constant Natural := Find_Entry (Self, Source, Kind);
   begin
      if Index = 0 then
         return Target_Vectors.Empty_Vector;
      end if;
      return Self.Entries (Index).Targets;
   end Targets;

   function Sources_Targeting
     (Self : Relation_Graph;
      Node : A11y.Node_Ids.Node_Id)
      return Target_Vectors.Vector
   is
      Result : Target_Vectors.Vector;
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         return Result;
      end if;

      for Rel of Self.Entries loop
         if Rel.Source /= Node
           and then Contains (Rel.Targets, Node)
           and then not Contains (Result, Rel.Source)
         then
            Result.Append (Rel.Source);
         end if;
      end loop;

      return Result;
   end Sources_Targeting;

   function Sources_Targeting
     (Self : Relation_Graph;
      Node : A11y.Node_Ids.Node_Id;
      Kind : Relation_Kind)
      return Target_Vectors.Vector
   is
      Result : Target_Vectors.Vector;
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         return Result;
      end if;

      for Rel of Self.Entries loop
         if Rel.Kind = Kind
           and then Rel.Source /= Node
           and then Contains (Rel.Targets, Node)
           and then not Contains (Result, Rel.Source)
         then
            Result.Append (Rel.Source);
         end if;
      end loop;

      return Result;
   end Sources_Targeting;

   function Capacity (Self : Relation_Graph) return Natural is
     (Self.Limit);

   function Has_Cycle
     (Self : Relation_Graph;
      Kind : Relation_Kind)
      return Boolean
   is
      Visiting : Target_Vectors.Vector;
      Visited  : Target_Vectors.Vector;

      function Visit
        (Source : A11y.Node_Ids.Node_Id)
         return Boolean;

      function Visit
        (Source : A11y.Node_Ids.Node_Id)
         return Boolean
      is
         Targets_For_Source : constant Target_Vectors.Vector :=
           Targets (Self, Source, Kind);
      begin
         if Contains (Visiting, Source) then
            return True;
         elsif Contains (Visited, Source) then
            return False;
         end if;

         Visiting.Append (Source);
         for Target of Targets_For_Source loop
            if Visit (Target) then
               return True;
            end if;
         end loop;
         Visiting.Delete_Last;
         Visited.Append (Source);
         return False;
      end Visit;
   begin
      for Rel of Self.Entries loop
         if Rel.Kind = Kind and then Visit (Rel.Source) then
            return True;
         end if;
      end loop;
      return False;
   exception
      when others =>
         return True;
   end Has_Cycle;

   function Has_Any_Cycle (Self : Relation_Graph) return Boolean is
   begin
      for Kind in Relation_Kind loop
         if Has_Cycle (Self, Kind) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Any_Cycle;

   function Largest_Target_Count (Self : Relation_Graph) return Natural is
      Result : Natural := 0;
   begin
      for Item of Self.Entries loop
         Result := Natural'Max (Result, Natural (Item.Targets.Length));
      end loop;
      return Result;
   end Largest_Target_Count;

   procedure Set_Capacity
     (Self     : in out Relation_Graph;
      Capacity : Natural;
      Result   : out A11y.Results.Result)
   is
   begin
      if Capacity = 0 or else Capacity > Max_Relation_Targets then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif Capacity < Largest_Target_Count (Self) then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Self.Limit := Capacity;
         Result := A11y.Results.Ok;
      end if;
   end Set_Capacity;

   procedure Configure_Limits
     (Self   : in out Relation_Graph;
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
              (Limits, A11y.Resource_Limits.Relation_Targets_Returned)),
         Result);
   end Configure_Limits;

   procedure Can_Configure_Limits
     (Self   : Relation_Graph;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
   is
      Capacity : Natural;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Capacity := Natural
        (A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Relation_Targets_Returned));
      if Capacity = 0 or else Capacity > Max_Relation_Targets then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif Capacity < Largest_Target_Count (Self) then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Result := A11y.Results.Ok;
      end if;
   end Can_Configure_Limits;

   function Would_Exceed
     (Self   : Relation_Graph;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : Relation_Kind;
      Target : A11y.Node_Ids.Node_Id)
      return Boolean
   is
      Index : constant Natural := Find_Entry (Self, Source, Kind);
   begin
      if Index = 0 or else Contains (Self.Entries (Index).Targets, Target) then
         return False;
      end if;

      return Natural (Self.Entries (Index).Targets.Length) >= Self.Limit;
   end Would_Exceed;

   procedure Add
     (Self   : in out Relation_Graph;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : Relation_Kind;
      Target : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
      Opposite : constant Relation_Kind := Inverse (Kind);
   begin
      if not A11y.Node_Ids.Is_Valid (Source)
        or else not A11y.Node_Ids.Is_Valid (Target)
        or else Source = Target
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      if Would_Exceed (Self, Source, Kind, Target)
        or else (Opposite /= Kind
                 and then Would_Exceed (Self, Target, Opposite, Source))
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      Add_One_Way (Self, Source, Kind, Target);
      if Opposite /= Kind then
         Add_One_Way (Self, Target, Opposite, Source);
      end if;
      Result := A11y.Results.Ok;
   end Add;

   procedure Remove
     (Self   : in out Relation_Graph;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : Relation_Kind;
      Target : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
      Opposite : constant Relation_Kind := Inverse (Kind);
   begin
      Remove_One_Way (Self, Source, Kind, Target);
      if Opposite /= Kind then
         Remove_One_Way (Self, Target, Opposite, Source);
      end if;
      Result := A11y.Results.Ok;
   end Remove;

   procedure Remove_Node
     (Self : in out Relation_Graph;
      Node : A11y.Node_Ids.Node_Id)
   is
      Index : Natural;
      Rel : Relation_Record;
   begin
      if Self.Entries.Is_Empty then
         return;
      end if;

      Index := Self.Entries.First_Index;
      while Index <= Self.Entries.Last_Index loop
         Rel := Self.Entries (Index);
         if Rel.Source = Node then
            Self.Entries.Delete (Index);
         else
            if not Rel.Targets.Is_Empty then
               for Target_Index in reverse Rel.Targets.First_Index .. Rel.Targets.Last_Index loop
                  if Rel.Targets (Target_Index) = Node then
                     Rel.Targets.Delete (Target_Index);
                  end if;
               end loop;
            end if;

            if Rel.Targets.Is_Empty then
               Self.Entries.Delete (Index);
            else
               Self.Entries.Replace_Element (Index, Rel);
               Index := Index + 1;
            end if;
         end if;
      end loop;
   end Remove_Node;

   function Relation_Targets_Safely
     (Self      : Relation_Provider'Class;
      Kind      : Relation_Kind;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Result    : out A11y.Results.Result;
      Truncated : out Boolean)
      return Target_Vectors.Vector
   is
      Items : Target_Vectors.Vector;
      Limit : Natural;
   begin
      Truncated := False;
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Target_Vectors.Empty_Vector;
      end if;

      Limit := Natural
        (A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Relation_Targets_Returned));
      if Limit = 0 or else Limit > Max_Relation_Targets then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Target_Vectors.Empty_Vector;
      end if;

      Items := Self.Relation_Targets (Kind);
      if Natural (Items.Length) > Limit then
         Truncated := True;
         Result := (Status => A11y.Results.Resource_Limit);
         return Target_Vectors.Empty_Vector;
      end if;

      for Index in 1 .. Natural (Items.Length) loop
         if not A11y.Node_Ids.Is_Valid (Items.Element (Positive (Index))) then
            Result := (Status => A11y.Results.Node_Unavailable);
            return Target_Vectors.Empty_Vector;
         end if;

         for Other in Index + 1 .. Natural (Items.Length) loop
            if Items.Element (Positive (Index))
              = Items.Element (Positive (Other))
            then
               Result := (Status => A11y.Results.Invalid_State);
               return Target_Vectors.Empty_Vector;
            end if;
         end loop;
      end loop;

      Result := A11y.Results.Ok;
      return Items;
   exception
      when others =>
         Truncated := False;
         Result := (Status => A11y.Results.Internal_Error);
         return Target_Vectors.Empty_Vector;
   end Relation_Targets_Safely;

   function Relation_Targets_Safely
     (Self      : Relation_Provider'Class;
      Kind      : Relation_Kind;
      Result    : out A11y.Results.Result;
      Truncated : out Boolean)
      return Target_Vectors.Vector is
     (Relation_Targets_Safely
        (Self,
         Kind,
         A11y.Resource_Limits.Default_Config,
         Result,
         Truncated));

end A11y.Relations;
