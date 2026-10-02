package body A11y.Windows_Backend.UIA_Com_Providers is
   use type A11y.Native_Identity.Backend_Session_Id;
   use type A11y.Node_Ids.Node_Id;

   function Is_Core_Interface (Requested : Provider_Interface) return Boolean is
     (Requested in
        IUnknown_Interface |
        Raw_Element_Provider_Simple |
        Raw_Element_Provider_Fragment |
        Raw_Element_Provider_Advise_Events);

   function Interface_Available
     (Provider  : Provider_Object;
      Requested : Provider_Interface)
      return Boolean is
     (Is_Core_Interface (Requested)
      or else (Requested = Raw_Element_Provider_Fragment_Root
               and then Provider.Node = Provider.Root));

   function Empty_Call
     (Status    : A11y.Results.Status_Code;
      Requested : Provider_Interface)
      return Provider_Call_Context is
     (Active                => False,
      Status                => Status,
      Requested             => Requested,
      Session               => A11y.Native_Identity.No_Session,
      Root                  => A11y.Node_Ids.No_Node,
      Node                  => A11y.Node_Ids.No_Node,
      Native_Node_Component => 0,
      Native_Call_Token     => 0,
      Native_Call_Generation => 0,
      Defunct               => True);

   procedure Advance_Call_Generation
     (Provider : in out Provider_Object) is
   begin
      if Provider.Call_Generation < Natural'Last then
         Provider.Call_Generation := Provider.Call_Generation + 1;
      end if;
   end Advance_Call_Generation;

   procedure Admit_Call_Token
     (Provider : in out Provider_Object;
      Token    : out Natural;
      Result   : out A11y.Results.Result)
   is
      Token_Value : Long_Long_Integer;
   begin
      Token := 0;
      if Provider.Active_Calls >= Max_Tracked_Native_Calls
        or else Provider.Next_Call_Token >= Max_Tracked_Native_Calls
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      Token := Provider.Next_Call_Token;
      Token_Value := Long_Long_Integer (Token);
      Provider.Next_Call_Token := Provider.Next_Call_Token + 1;
      Provider.Active_Calls := Provider.Active_Calls + 1;
      Advance_Call_Generation (Provider);
      Provider.Active_Call_Token_Sum :=
        Provider.Active_Call_Token_Sum + Token_Value;
      Provider.Active_Call_Token_Square_Sum :=
        Provider.Active_Call_Token_Square_Sum + Token_Value * Token_Value;
      Result := A11y.Results.Ok;
   end Admit_Call_Token;

   function Token_State_Plausible
     (Provider : Provider_Object)
      return Boolean is
     (if Provider.Active_Calls = 0 then
         Provider.Active_Call_Token_Sum = 0
         and then Provider.Active_Call_Token_Square_Sum = 0
      elsif Provider.Active_Calls = 1 then
         Provider.Active_Call_Token_Sum > 0
         and then Provider.Active_Call_Token_Square_Sum =
           Provider.Active_Call_Token_Sum * Provider.Active_Call_Token_Sum
      else
         Provider.Active_Call_Token_Sum > 0
         and then Provider.Active_Call_Token_Square_Sum > 0);

   procedure Release_Call_Token
     (Provider : in out Provider_Object;
      Token    : Natural;
      Result   : out A11y.Results.Result)
   is
      Token_Value : constant Long_Long_Integer := Long_Long_Integer (Token);
      Previous_Generation : constant Natural := Provider.Call_Generation;
   begin
      if Token = 0 then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      if Provider.Active_Calls = 0
        or else Provider.Active_Call_Token_Sum < Token_Value
        or else Provider.Active_Call_Token_Square_Sum <
          Token_Value * Token_Value
      then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      Provider.Active_Calls := Provider.Active_Calls - 1;
      Advance_Call_Generation (Provider);
      Provider.Active_Call_Token_Sum :=
        Provider.Active_Call_Token_Sum - Token_Value;
      Provider.Active_Call_Token_Square_Sum :=
        Provider.Active_Call_Token_Square_Sum - Token_Value * Token_Value;

      if Token_State_Plausible (Provider) then
         Result := A11y.Results.Ok;
      else
         Provider.Active_Calls := Provider.Active_Calls + 1;
         Provider.Call_Generation := Previous_Generation;
         Provider.Active_Call_Token_Sum :=
           Provider.Active_Call_Token_Sum + Token_Value;
         Provider.Active_Call_Token_Square_Sum :=
           Provider.Active_Call_Token_Square_Sum + Token_Value * Token_Value;
         Result := (Status => A11y.Results.Invalid_State);
      end if;
   end Release_Call_Token;

   procedure Initialize
     (Provider : in out Provider_Object;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Root     : A11y.Node_Ids.Node_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Result   : out A11y.Results.Result)
   is
   begin
      if Provider.State not in Provider_Created | Provider_Destroyed then
         Result := (Status => A11y.Results.Invalid_State);
      elsif not A11y.Native_Identity.Is_Valid (Session)
        or else not A11y.Node_Ids.Is_Valid (Root)
        or else not A11y.Node_Ids.Is_Valid (Node)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Provider.State := Provider_Alive;
         Provider.Session := Session;
         Provider.Root := Root;
         Provider.Node := Node;
         Provider.References := 1;
         Provider.Active_Calls := 0;
         Provider.Call_Generation := 0;
         Provider.Next_Call_Token := 1;
         Provider.Active_Call_Token_Sum := 0;
         Provider.Active_Call_Token_Square_Sum := 0;
         Provider.Host_Window_Bound := False;
         Provider.Host_Window_Component := 0;
         Provider.Defunct := False;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Initialize;

   procedure Query_Interface
     (Provider  : in out Provider_Object;
      Requested : Provider_Interface;
      Query     : out Interface_Query)
   is
      Result : A11y.Results.Result;
      References : Natural;
   begin
      if Provider.State = Provider_Destroyed
        or else Provider.Defunct
      then
         Query :=
           (Supported => False,
            Status    => A11y.Results.Node_Unavailable,
            Kind      => Requested);
      elsif Interface_Available (Provider, Requested)
      then
         Add_Ref (Provider, References, Result);
         Query :=
           (Supported => A11y.Results.Succeeded (Result),
            Status    => Result.Status,
            Kind      => Requested);
      else
         Query :=
           (Supported => False,
            Status    => A11y.Results.Unsupported_Capability,
            Kind      => Requested);
      end if;
   exception
      when others =>
         Query :=
           (Supported => False,
            Status    => A11y.Results.Internal_Error,
            Kind      => Requested);
   end Query_Interface;

   procedure Add_Ref
     (Provider   : in out Provider_Object;
      References : out Natural;
      Result     : out A11y.Results.Result)
   is
   begin
      References := Provider.References;
      if Provider.State = Provider_Destroyed or else Provider.Defunct then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Provider.References >= Max_Reference_Count then
         Result := (Status => A11y.Results.Resource_Limit);
      elsif Provider.State /= Provider_Alive then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Provider.References := Provider.References + 1;
         References := Provider.References;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         References := 0;
         Result := (Status => A11y.Results.Internal_Error);
   end Add_Ref;

   procedure Release
     (Provider   : in out Provider_Object;
      References : out Natural;
      Result     : out A11y.Results.Result)
   is
   begin
      References := Provider.References;
      if Provider.State = Provider_Destroyed then
         References := 0;
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Provider.References = 0 then
         Provider.State := Provider_Destroyed;
         References := 0;
         Result := (Status => A11y.Results.Invalid_State);
      else
         Provider.References := Provider.References - 1;
         References := Provider.References;
         if Provider.References = 0 then
            Provider.Defunct := True;
            if Provider.Active_Calls = 0 then
               Provider.State := Provider_Destroyed;
            else
               Provider.State := Provider_Defunct;
            end if;
         end if;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         References := 0;
         Result := (Status => A11y.Results.Internal_Error);
   end Release;

   procedure Mark_Defunct
     (Provider : in out Provider_Object;
      Result   : out A11y.Results.Result)
   is
   begin
      if Provider.State = Provider_Destroyed then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Provider.State /= Provider_Alive then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Provider.Defunct := True;
         Provider.State := Provider_Defunct;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
      Result := (Status => A11y.Results.Internal_Error);
   end Mark_Defunct;

   procedure Bind_Host_Window_Root
     (Provider              : in out Provider_Object;
      Host_Window_Component : Natural;
      Result                : out A11y.Results.Result)
   is
   begin
      if Provider.State = Provider_Destroyed or else Provider.Defunct then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Provider.State /= Provider_Alive then
         Result := (Status => A11y.Results.Invalid_State);
      elsif Provider.Node /= Provider.Root then
         Result := (Status => A11y.Results.Invalid_State);
      elsif Host_Window_Component = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif Provider.Host_Window_Bound
        and then Provider.Host_Window_Component /= Host_Window_Component
      then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Provider.Host_Window_Bound := True;
         Provider.Host_Window_Component := Host_Window_Component;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Bind_Host_Window_Root;

   procedure Begin_Native_Call
     (Provider  : in out Provider_Object;
      Requested : Provider_Interface;
      Context   : out Provider_Call_Context;
      Result    : out A11y.Results.Result)
   is
      Component_Result : A11y.Results.Result;
      Component : Natural := 0;
      Token : Natural := 0;
   begin
      if Provider.State = Provider_Destroyed or else Provider.Defunct then
         Context := Empty_Call (A11y.Results.Node_Unavailable, Requested);
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Provider.State /= Provider_Alive then
         Context := Empty_Call (A11y.Results.Invalid_State, Requested);
         Result := (Status => A11y.Results.Invalid_State);
      elsif not Interface_Available (Provider, Requested) then
         Context := Empty_Call (A11y.Results.Unsupported_Capability, Requested);
         Result := (Status => A11y.Results.Unsupported_Capability);
      elsif Provider.Active_Calls >= Max_Tracked_Native_Calls then
         Context := Empty_Call (A11y.Results.Resource_Limit, Requested);
         Result := (Status => A11y.Results.Resource_Limit);
      else
         Component :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (Provider.Session, Provider.Node, Component_Result);
         if A11y.Results.Failed (Component_Result) then
            Context := Empty_Call (Component_Result.Status, Requested);
            Result := Component_Result;
         else
            Admit_Call_Token (Provider, Token, Result);
            if A11y.Results.Failed (Result) then
               Context := Empty_Call (Result.Status, Requested);
            else
               Context :=
                 (Active                => True,
                  Status                => A11y.Results.Success,
                  Requested             => Requested,
                  Session               => Provider.Session,
                  Root                  => Provider.Root,
                  Node                  => Provider.Node,
                  Native_Node_Component => Component,
                  Native_Call_Token     => Token,
                  Native_Call_Generation => Provider.Call_Generation,
                  Defunct               => False);
            end if;
         end if;
      end if;
   exception
      when others =>
         Context := Empty_Call (A11y.Results.Internal_Error, Requested);
         Result := (Status => A11y.Results.Internal_Error);
   end Begin_Native_Call;

   procedure End_Native_Call
     (Provider : in out Provider_Object;
      Context  : in out Provider_Call_Context;
      Result   : out A11y.Results.Result)
   is
   begin
      if not Context.Active then
         Result := (Status => A11y.Results.Invalid_State);
      elsif Context.Session /= Provider.Session
        or else Context.Node /= Provider.Node
        or else Context.Root /= Provider.Root
      then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Provider.Active_Calls = 0 then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Release_Call_Token (Provider, Context.Native_Call_Token, Result);
         if A11y.Results.Succeeded (Result) then
            Context.Active := False;
            Context.Status := A11y.Results.Success;
            Context.Native_Call_Token := 0;
            if Provider.Active_Calls = 0
              and then Provider.References = 0
              and then Provider.Defunct
            then
               Provider.State := Provider_Destroyed;
            end if;
         end if;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end End_Native_Call;

   function Drained (Provider : Provider_Object) return Boolean is
     (Provider.Active_Calls = 0);

   function Export_Descriptor
     (Provider : Provider_Object)
      return Provider_Export_Descriptor
   is
      Component_Result : A11y.Results.Result;
      Component : Natural := 0;
      Interfaces : Provider_Interface_Set := [others => False];
   begin
      if Provider.State = Provider_Destroyed or else Provider.Defunct then
         return
           (Exportable            => False,
            Status                => A11y.Results.Node_Unavailable,
            Session               => Provider.Session,
            Root                  => Provider.Root,
            Node                  => Provider.Node,
            Native_Node_Component => 0,
            Interfaces            => Interfaces,
            Host_Window_Bound     => Provider.Host_Window_Bound,
            Host_Window_Component => Provider.Host_Window_Component,
            Defunct               => True);
      elsif Provider.State /= Provider_Alive then
         return
           (Exportable            => False,
            Status                => A11y.Results.Invalid_State,
            Session               => Provider.Session,
            Root                  => Provider.Root,
            Node                  => Provider.Node,
            Native_Node_Component => 0,
            Interfaces            => Interfaces,
            Host_Window_Bound     => Provider.Host_Window_Bound,
            Host_Window_Component => Provider.Host_Window_Component,
            Defunct               => Provider.Defunct);
      end if;

      Component :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Provider.Session, Provider.Node, Component_Result);
      if A11y.Results.Failed (Component_Result) then
         return
           (Exportable            => False,
            Status                => Component_Result.Status,
            Session               => Provider.Session,
            Root                  => Provider.Root,
            Node                  => Provider.Node,
            Native_Node_Component => 0,
            Interfaces            => Interfaces,
            Host_Window_Bound     => Provider.Host_Window_Bound,
            Host_Window_Component => Provider.Host_Window_Component,
            Defunct               => False);
      end if;

      for Kind in Provider_Interface loop
         Interfaces (Kind) :=
           Kind /= Unsupported_Interface
           and then Interface_Available (Provider, Kind);
      end loop;

      return
        (Exportable            => True,
         Status                => A11y.Results.Success,
         Session               => Provider.Session,
         Root                  => Provider.Root,
         Node                  => Provider.Node,
         Native_Node_Component => Component,
         Interfaces            => Interfaces,
         Host_Window_Bound     => Provider.Host_Window_Bound,
         Host_Window_Component => Provider.Host_Window_Component,
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
            Interfaces            => [others => False],
            Host_Window_Bound     => False,
            Host_Window_Component => 0,
            Defunct               => True);
   end Export_Descriptor;

   function Snapshot (Provider : Provider_Object) return Provider_Snapshot is
     (State      => Provider.State,
      Session    => Provider.Session,
      Node       => Provider.Node,
      Root       => Provider.Root,
      References => Provider.References,
      Active_Calls => Provider.Active_Calls,
      Call_Generation => Provider.Call_Generation,
      Host_Window_Bound => Provider.Host_Window_Bound,
      Host_Window_Component => Provider.Host_Window_Component,
      Defunct    => Provider.Defunct);

   function Snapshot
     (Context : Provider_Call_Context)
     return Provider_Call_Snapshot is
     (Active                => Context.Active,
      Status                => Context.Status,
      Requested             => Context.Requested,
      Session               => Context.Session,
      Root                  => Context.Root,
      Node                  => Context.Node,
      Native_Node_Component => Context.Native_Node_Component,
      Native_Call_Token     => Context.Native_Call_Token,
      Native_Call_Generation => Context.Native_Call_Generation,
      Defunct               => Context.Defunct);

   function Rejected_Call_Context
     (Requested : Provider_Interface;
      Status    : A11y.Results.Status_Code)
      return Provider_Call_Context is
     (Empty_Call (Status, Requested));

end A11y.Windows_Backend.UIA_Com_Providers;
