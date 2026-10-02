package body A11y.Native_Identity is
   Next_Session : Natural := 1;
   Session_Exhausted : Boolean := False;

   function Create_Session return Backend_Session_Id is
      Result : Backend_Session_Id;
   begin
      if Session_Exhausted then
         return No_Session;
      end if;

      Result := Backend_Session_Id (Next_Session);
      if Next_Session = Natural'Last then
         Session_Exhausted := True;
      else
         Next_Session := Next_Session + 1;
      end if;

      return Result;
   end Create_Session;

   function Is_Valid (Session : Backend_Session_Id) return Boolean is
     (Session /= No_Session)
   with SPARK_Mode => On;

   function To_Natural (Session : Backend_Session_Id) return Natural is
     (Natural (Session))
   with SPARK_Mode => On;

   function From_Natural (Value : Natural) return Backend_Session_Id is
     (Backend_Session_Id (Value))
   with SPARK_Mode => On;

   function Valid_Session_Value (Session_Value : Natural) return Boolean is
     (Session_Value /= 0)
   with SPARK_Mode => On;

   function Valid_Runtime_Node_Component
     (Node_Value : Natural)
      return Boolean is
     (Node_Value in 1 .. A11y.Node_Ids.Max_Node_Ids
      and then Node_Value < Runtime_Node_Factor)
   with SPARK_Mode => On;

   function Can_Encode_Runtime_Component
     (Session_Value : Natural;
      Node_Value    : Natural)
      return Boolean is
     (Valid_Session_Value (Session_Value)
      and then Valid_Runtime_Node_Component (Node_Value)
      and then
        Session_Value <= (Natural'Last - Node_Value) / Runtime_Node_Factor)
   with SPARK_Mode => On;

   function Runtime_Component
     (Session_Value : Natural;
      Node_Value    : Natural)
      return Natural is
     (Session_Value * Runtime_Node_Factor + Node_Value)
   with SPARK_Mode => On;

   function Component_Session_Value
     (Component : Natural)
      return Natural is
     (Component / Runtime_Node_Factor)
   with SPARK_Mode => On;

   function Component_Node_Value
     (Component : Natural)
      return Natural is
     (Component mod Runtime_Node_Factor)
   with SPARK_Mode => On;

   function Component_Matches_Session
     (Session_Value : Natural;
      Component     : Natural)
      return Boolean is
     (Valid_Session_Value (Session_Value)
      and then Component /= 0
      and then Component_Session_Value (Component) = Session_Value
      and then Valid_Runtime_Node_Component (Component_Node_Value (Component)))
   with SPARK_Mode => On;

   function Trimmed_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Trimmed_Image;

   function Image (Session : Backend_Session_Id) return String is
     (if Session = No_Session
      then "none"
      else Trimmed_Image (Natural (Session)));

   function Runtime_Identifier_Component
     (Session : Backend_Session_Id;
      Node    : A11y.Node_Ids.Node_Id;
      Result  : out A11y.Results.Result)
      return Natural
   is
      Session_Value : Natural;
      Node_Value : Natural;
   begin
      if not Is_Valid (Session) or else not A11y.Node_Ids.Is_Valid (Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return 0;
      end if;

      Session_Value := Natural (Session);
      Node_Value := A11y.Node_Ids.To_Natural (Node);
      if not Can_Encode_Runtime_Component (Session_Value, Node_Value)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return 0;
      end if;

      Result := A11y.Results.Ok;
      return Runtime_Component (Session_Value, Node_Value);
   exception
      when Constraint_Error =>
         Result := (Status => A11y.Results.Resource_Limit);
         return 0;
   end Runtime_Identifier_Component;

   function Node_From_Runtime_Identifier_Component
     (Session   : Backend_Session_Id;
      Component : Natural;
      Result    : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id
   is
      Encoded_Node    : Natural;
      Node            : A11y.Node_Ids.Node_Id;
   begin
      if not Is_Valid (Session) or else Component = 0 then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      end if;

      Encoded_Node :=
        Component_Node_Value (Component);

      if not Component_Matches_Session (Natural (Session), Component)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      end if;

      Node := A11y.Node_Ids.From_Natural (Encoded_Node);
      if not A11y.Node_Ids.Is_Valid (Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      end if;

      Result := A11y.Results.Ok;
      return Node;
   exception
      when Constraint_Error =>
         Result := (Status => A11y.Results.Resource_Limit);
         return A11y.Node_Ids.No_Node;
   end Node_From_Runtime_Identifier_Component;

end A11y.Native_Identity;
