package body A11y.MacOS_Backend.NSAccessibility_Elements is
   use type A11y.Native_Identity.Backend_Session_Id;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Results.Status_Code;

   function Empty_Call
     (Status : A11y.Results.Status_Code)
      return Element_Call_Context is
     (Active                => False,
      Status                => Status,
      Session               => A11y.Native_Identity.No_Session,
      Root                  => A11y.Node_Ids.No_Node,
      Node                  => A11y.Node_Ids.No_Node,
      Native_Node_Component => 0,
      Native_Call_Token     => 0,
      Native_Call_Generation => 0,
      Main_Thread_Bound     => False,
      Defunct               => True);

   procedure Advance_Call_Generation
     (Element : in out Element_Object) is
   begin
      if Element.Call_Generation < Natural'Last then
         Element.Call_Generation := Element.Call_Generation + 1;
      end if;
   end Advance_Call_Generation;

   procedure Admit_Call_Token
     (Element : in out Element_Object;
      Token   : out Natural;
      Result  : out A11y.Results.Result)
   is
      Token_Value : Long_Long_Integer;
   begin
      Token := 0;
      if Element.Active_Calls >= Max_Tracked_Native_Calls
        or else Element.Next_Call_Token >= Max_Tracked_Native_Calls
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      Token := Element.Next_Call_Token;
      Token_Value := Long_Long_Integer (Token);
      Element.Next_Call_Token := Element.Next_Call_Token + 1;
      Element.Active_Calls := Element.Active_Calls + 1;
      Element.Active_Tokens.Append (Token);
      Advance_Call_Generation (Element);
      Element.Active_Call_Token_Sum :=
        Element.Active_Call_Token_Sum + Token_Value;
      Element.Active_Call_Token_Square_Sum :=
        Element.Active_Call_Token_Square_Sum + Token_Value * Token_Value;
      Result := A11y.Results.Ok;
   end Admit_Call_Token;

   function Token_State_Plausible
     (Element : Element_Object)
      return Boolean is
     (Natural (Element.Active_Tokens.Length) = Element.Active_Calls
      and then
      (if Element.Active_Calls = 0 then
         Element.Active_Call_Token_Sum = 0
         and then Element.Active_Call_Token_Square_Sum = 0
      elsif Element.Active_Calls = 1 then
         Element.Active_Call_Token_Sum > 0
         and then Element.Active_Call_Token_Square_Sum =
           Element.Active_Call_Token_Sum * Element.Active_Call_Token_Sum
      else
         Element.Active_Call_Token_Sum > 0
         and then Element.Active_Call_Token_Square_Sum > 0));

   function Has_Active_Token
     (Element : Element_Object;
      Token   : Natural)
      return Boolean
   is
   begin
      for Active of Element.Active_Tokens loop
         if Active = Token then
            return True;
         end if;
      end loop;
      return False;
   end Has_Active_Token;

   procedure Remove_Active_Token
     (Element : in out Element_Object;
      Token   : Natural;
      Result  : out A11y.Results.Result)
   is
   begin
      for Index in Element.Active_Tokens.First_Index ..
        Element.Active_Tokens.Last_Index
      loop
         if Element.Active_Tokens.Element (Index) = Token then
            Element.Active_Tokens.Delete (Index);
            Result := A11y.Results.Ok;
            return;
         end if;
      end loop;
      Result := (Status => A11y.Results.Invalid_State);
   end Remove_Active_Token;

   procedure Release_Call_Token
     (Element : in out Element_Object;
      Token   : Natural;
      Result  : out A11y.Results.Result)
   is
      Token_Value : constant Long_Long_Integer := Long_Long_Integer (Token);
      Previous_Generation : constant Natural := Element.Call_Generation;
   begin
      if Token = 0 then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      if Element.Active_Calls = 0
        or else not Has_Active_Token (Element, Token)
        or else Element.Active_Call_Token_Sum < Token_Value
        or else Element.Active_Call_Token_Square_Sum <
          Token_Value * Token_Value
      then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      Element.Active_Calls := Element.Active_Calls - 1;
      Remove_Active_Token (Element, Token, Result);
      if A11y.Results.Failed (Result) then
         Element.Active_Calls := Element.Active_Calls + 1;
         return;
      end if;
      Advance_Call_Generation (Element);
      Element.Active_Call_Token_Sum :=
        Element.Active_Call_Token_Sum - Token_Value;
      Element.Active_Call_Token_Square_Sum :=
        Element.Active_Call_Token_Square_Sum - Token_Value * Token_Value;

      if Token_State_Plausible (Element) then
         Result := A11y.Results.Ok;
      else
         Element.Active_Calls := Element.Active_Calls + 1;
         Element.Active_Tokens.Append (Token);
         Element.Call_Generation := Previous_Generation;
         Element.Active_Call_Token_Sum :=
           Element.Active_Call_Token_Sum + Token_Value;
         Element.Active_Call_Token_Square_Sum :=
           Element.Active_Call_Token_Square_Sum + Token_Value * Token_Value;
         Result := (Status => A11y.Results.Invalid_State);
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Release_Call_Token;

   procedure Initialize
     (Element : in out Element_Object;
      Session : A11y.Native_Identity.Backend_Session_Id;
      Root    : A11y.Node_Ids.Node_Id;
      Node    : A11y.Node_Ids.Node_Id;
      Result  : out A11y.Results.Result)
   is
   begin
      if Element.State not in Element_Created | Element_Destroyed then
         Result := (Status => A11y.Results.Invalid_State);
      elsif not A11y.Native_Identity.Is_Valid (Session)
        or else not A11y.Node_Ids.Is_Valid (Root)
        or else not A11y.Node_Ids.Is_Valid (Node)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Element.State := Element_Live;
         Element.Session := Session;
         Element.Root := Root;
         Element.Node := Node;
         Element.Retains := 1;
         Element.Active_Calls := 0;
         Element.Call_Generation := 0;
         Element.Next_Call_Token := 1;
         Element.Active_Call_Token_Sum := 0;
         Element.Active_Call_Token_Square_Sum := 0;
         Element.Active_Tokens.Clear;
         Element.Main_Thread_Bound := False;
         Element.Native_View_Bound := False;
         Element.Native_View_Component := 0;
         Element.Defunct := False;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Initialize;

   procedure Bind_Main_Thread
     (Element : in out Element_Object;
      Result  : out A11y.Results.Result)
   is
   begin
      if Element.State = Element_Destroyed or else Element.Defunct then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Element.State /= Element_Live then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Element.Main_Thread_Bound := True;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Bind_Main_Thread;

   procedure Retain
     (Element : in out Element_Object;
      Retains : out Natural;
      Result  : out A11y.Results.Result)
   is
   begin
      Retains := Element.Retains;
      if Element.State = Element_Destroyed or else Element.Defunct then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Element.Retains >= Max_Retain_Count then
         Result := (Status => A11y.Results.Resource_Limit);
      elsif Element.State /= Element_Live then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Element.Retains := Element.Retains + 1;
         Retains := Element.Retains;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Retains := 0;
         Result := (Status => A11y.Results.Internal_Error);
   end Retain;

   procedure Release
     (Element : in out Element_Object;
      Retains : out Natural;
      Result  : out A11y.Results.Result)
   is
   begin
      Retains := Element.Retains;
      if Element.State = Element_Destroyed then
         Retains := 0;
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Element.Retains = 0 then
         Element.State := Element_Destroyed;
         Element.Defunct := True;
         Retains := 0;
         Result := (Status => A11y.Results.Invalid_State);
      else
         Element.Retains := Element.Retains - 1;
         Retains := Element.Retains;
         if Element.Retains = 0 then
            Element.Defunct := True;
            if Element.Active_Calls = 0 then
               Element.State := Element_Destroyed;
            else
               Element.State := Element_Defunct;
            end if;
         end if;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Retains := 0;
         Result := (Status => A11y.Results.Internal_Error);
   end Release;

   procedure Mark_Defunct
     (Element : in out Element_Object;
      Result  : out A11y.Results.Result)
   is
   begin
      if Element.State = Element_Destroyed then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Element.State /= Element_Live then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Element.Defunct := True;
         Element.State := Element_Defunct;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
      Result := (Status => A11y.Results.Internal_Error);
   end Mark_Defunct;

   procedure Bind_Native_View
     (Element               : in out Element_Object;
      Native_View_Component : Natural;
      Result                : out A11y.Results.Result)
   is
   begin
      if Element.State = Element_Destroyed or else Element.Defunct then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Element.State /= Element_Live then
         Result := (Status => A11y.Results.Invalid_State);
      elsif not Element.Main_Thread_Bound then
         Result := (Status => A11y.Results.Invalid_State);
      elsif Native_View_Component = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif Element.Native_View_Bound
        and then Element.Native_View_Component /= Native_View_Component
      then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Element.Native_View_Bound := True;
         Element.Native_View_Component := Native_View_Component;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Bind_Native_View;

   procedure Begin_Native_Call
     (Element             : in out Element_Object;
      Context             : out Element_Call_Context;
      Result              : out A11y.Results.Result;
      Require_Main_Thread : Boolean := False)
   is
      Component_Result : A11y.Results.Result;
      Component : Natural := 0;
      Token : Natural := 0;
   begin
      if Element.State = Element_Destroyed or else Element.Defunct then
         Context := Empty_Call (A11y.Results.Node_Unavailable);
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Element.State /= Element_Live then
         Context := Empty_Call (A11y.Results.Invalid_State);
         Result := (Status => A11y.Results.Invalid_State);
      elsif Require_Main_Thread and then not Element.Main_Thread_Bound then
         Context := Empty_Call (A11y.Results.Invalid_State);
         Result := (Status => A11y.Results.Invalid_State);
      elsif Element.Active_Calls >= Max_Tracked_Native_Calls then
         Context := Empty_Call (A11y.Results.Resource_Limit);
         Result := (Status => A11y.Results.Resource_Limit);
      else
         Component :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (Element.Session, Element.Node, Component_Result);
         if A11y.Results.Failed (Component_Result) then
            Context := Empty_Call (Component_Result.Status);
            Result := Component_Result;
         else
            Admit_Call_Token (Element, Token, Result);
            if A11y.Results.Failed (Result) then
               Context := Empty_Call (Result.Status);
            else
               Context :=
                 (Active                => True,
                  Status                => A11y.Results.Success,
                  Session               => Element.Session,
                  Root                  => Element.Root,
                  Node                  => Element.Node,
                  Native_Node_Component => Component,
                  Native_Call_Token     => Token,
                  Native_Call_Generation => Element.Call_Generation,
                  Main_Thread_Bound     => Element.Main_Thread_Bound,
                  Defunct               => False);
            end if;
         end if;
      end if;
   exception
      when others =>
         Context := Empty_Call (A11y.Results.Internal_Error);
         Result := (Status => A11y.Results.Internal_Error);
   end Begin_Native_Call;

   procedure End_Native_Call
     (Element : in out Element_Object;
      Context : in out Element_Call_Context;
      Result  : out A11y.Results.Result)
   is
   begin
      if not Context.Active then
         Result := (Status => A11y.Results.Invalid_State);
      elsif Context.Session /= Element.Session
        or else Context.Root /= Element.Root
        or else Context.Node /= Element.Node
      then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Element.Active_Calls = 0 then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Release_Call_Token (Element, Context.Native_Call_Token, Result);
         if A11y.Results.Succeeded (Result) then
            Context.Active := False;
            Context.Status := A11y.Results.Success;
            Context.Native_Call_Token := 0;
            if Element.Active_Calls = 0
              and then Element.Retains = 0
              and then Element.Defunct
            then
               Element.State := Element_Destroyed;
            end if;
         elsif Result.Status = A11y.Results.Invalid_State then
            Context.Active := False;
            Context.Status := A11y.Results.Invalid_State;
            Context.Native_Call_Token := 0;
         end if;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end End_Native_Call;

   function Drained (Element : Element_Object) return Boolean is
     (Element.Active_Calls = 0);

   function Export_Descriptor
     (Element : Element_Object)
      return Element_Export_Descriptor
   is
      Component_Result : A11y.Results.Result;
      Component : Natural := 0;
   begin
      if Element.State = Element_Destroyed or else Element.Defunct then
         return
           (Exportable            => False,
            Status                => A11y.Results.Node_Unavailable,
            Session               => Element.Session,
            Root                  => Element.Root,
            Node                  => Element.Node,
            Native_Node_Component => 0,
            Main_Thread_Bound     => Element.Main_Thread_Bound,
            Native_View_Bound     => Element.Native_View_Bound,
            Native_View_Component => Element.Native_View_Component,
            Defunct               => True);
      elsif Element.State /= Element_Live then
         return
           (Exportable            => False,
            Status                => A11y.Results.Invalid_State,
            Session               => Element.Session,
            Root                  => Element.Root,
            Node                  => Element.Node,
            Native_Node_Component => 0,
            Main_Thread_Bound     => Element.Main_Thread_Bound,
            Native_View_Bound     => Element.Native_View_Bound,
            Native_View_Component => Element.Native_View_Component,
            Defunct               => Element.Defunct);
      end if;

      Component :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Element.Session, Element.Node, Component_Result);
      if A11y.Results.Failed (Component_Result) then
         return
           (Exportable            => False,
            Status                => Component_Result.Status,
            Session               => Element.Session,
            Root                  => Element.Root,
            Node                  => Element.Node,
            Native_Node_Component => 0,
            Main_Thread_Bound     => Element.Main_Thread_Bound,
            Native_View_Bound     => Element.Native_View_Bound,
            Native_View_Component => Element.Native_View_Component,
            Defunct               => False);
      end if;

      return
        (Exportable            => True,
         Status                => A11y.Results.Success,
         Session               => Element.Session,
         Root                  => Element.Root,
         Node                  => Element.Node,
         Native_Node_Component => Component,
         Main_Thread_Bound     => Element.Main_Thread_Bound,
         Native_View_Bound     => Element.Native_View_Bound,
         Native_View_Component => Element.Native_View_Component,
         Defunct               => False);
   exception
      when others =>
         return
           (Exportable            => False,
            Status                => A11y.Results.Internal_Error,
            Session               => A11y.Native_Identity.No_Session,
            Root                  => A11y.Node_Ids.No_Node,
            Node                  => A11y.Node_Ids.No_Node,
            Native_Node_Component => 0,
            Main_Thread_Bound     => False,
            Native_View_Bound     => False,
            Native_View_Component => 0,
            Defunct               => True);
   end Export_Descriptor;

   function Snapshot (Element : Element_Object) return Element_Snapshot is
     (State             => Element.State,
      Session           => Element.Session,
      Root              => Element.Root,
      Node              => Element.Node,
      Retains           => Element.Retains,
      Active_Calls      => Element.Active_Calls,
      Call_Generation   => Element.Call_Generation,
      Main_Thread_Bound => Element.Main_Thread_Bound,
      Native_View_Bound => Element.Native_View_Bound,
      Native_View_Component => Element.Native_View_Component,
      Defunct           => Element.Defunct);

   function Snapshot
     (Context : Element_Call_Context)
      return Element_Call_Snapshot is
     (Active                => Context.Active,
      Status                => Context.Status,
      Session               => Context.Session,
      Root                  => Context.Root,
      Node                  => Context.Node,
      Native_Node_Component => Context.Native_Node_Component,
      Native_Call_Token     => Context.Native_Call_Token,
      Native_Call_Generation => Context.Native_Call_Generation,
      Main_Thread_Bound     => Context.Main_Thread_Bound,
      Defunct               => Context.Defunct);

   function Rejected_Call_Context
     (Status : A11y.Results.Status_Code)
      return Element_Call_Context is
     (Empty_Call (Status));

end A11y.MacOS_Backend.NSAccessibility_Elements;
