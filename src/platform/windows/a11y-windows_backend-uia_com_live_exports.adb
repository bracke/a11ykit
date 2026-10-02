with A11y.Native_Object_Caches;

package body A11y.Windows_Backend.UIA_COM_Live_Exports is

   package ABI renames A11y.Windows_Backend.UIA_ABI_Surface;
   package Boundary renames A11y.Windows_Backend.UIA_Provider_Boundary;
   package COM renames A11y.Windows_Backend.UIA_Com_Providers;
   package Exports renames A11y.Windows_Backend.UIA_COM_Exports;
   package Object_Exports renames A11y.Windows_Backend.UIA_COM_Object_Exports;
   package Reg_API renames A11y.Windows_Backend.UIA_Provider_Registry;
   package VTables renames A11y.Windows_Backend.UIA_COM_VTables;

   use type COM.Provider_Interface;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Results.Status_Code;
   use type Reg_API.Provider_Id;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use type A11y.Geometry.Coordinate;
   use type A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;

   function Error_Reply
     (Status : A11y.Results.Status_Code)
      return Boundary.Boundary_Reply
   is
      HResult : constant Boundary.HRESULT_Status :=
        Boundary.HResult_For (Status);
      Kind : constant Boundary.Boundary_Reply_Kind :=
        (if Status in
           A11y.Results.Unsupported_Property |
           A11y.Results.Unsupported_Capability |
           A11y.Results.Unsupported_Action
         then Boundary.Provider_Not_Supported
         else Boundary.Provider_Error);
   begin
      return
        (Kind          => Kind,
         HResult       => HResult,
         Status        => Status,
         Routed        =>
           A11y.Windows_Backend.UIA_Request_Router.Routed_Error,
         Payload       =>
           (Kind   => A11y.Windows_Backend.UIA_Request_Router.Routed_Error,
            Status => Status),
         Native_Object => A11y.Native_Object_Caches.No_Object);
   end Error_Reply;

   function Table_From
     (Object : VTables.COM_Object_Descriptor)
      return Exports.COM_Export_Table
   is
      Dispatchable : Natural := 0;
   begin
      for Method in ABI.UIA_ABI_Method loop
         if Object.Provider_Frame_Methods (Method) then
            Dispatchable := Dispatchable + 1;
         end if;
      end loop;

      return
        (Exportable            => Object.Exportable,
         Status                => Object.Status,
         Provider              => Object.Provider,
         Session               => Object.Session,
         Root                  => Object.Root,
         Node                  => Object.Node,
         Native_Node_Component => Object.Native_Node_Component,
         Callbacks             =>
           [Exports.Query_Interface_Slot => True,
            Exports.Add_Ref_Slot => True,
            Exports.Release_Slot => True,
            Exports.Provider_Method_Slot => True],
         Methods               => Object.Provider_Frame_Methods,
         Dispatchable_Methods  => Dispatchable,
         Host_Window_Bound     => Object.Host_Window_Bound,
         Host_Window_Component => Object.Host_Window_Component,
         Defunct               => Object.Defunct);
   end Table_From;

   function Method_Belongs_To_Interface
     (Reference : UIA_Interface_Reference;
      Method    : ABI.UIA_ABI_Method)
      return Boolean
   is
      Info : constant ABI.ABI_Method_Descriptor := ABI.Descriptor (Method);
   begin
      if not Reference.Present then
         return False;
      elsif Reference.Kind = COM.IUnknown_Interface then
         return Info.Is_Lifetime_Method;
      else
         return not Info.Is_Lifetime_Method
           and then Info.Provider_Interface_Kind = Reference.Kind;
      end if;
   exception
      when others =>
         return False;
   end Method_Belongs_To_Interface;

   function Interface_Code
     (Kind : A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface)
      return Interfaces.Unsigned_32 is
     (case Kind is
        when COM.IUnknown_Interface => 1,
        when COM.Raw_Element_Provider_Simple => 2,
        when COM.Raw_Element_Provider_Fragment => 3,
        when COM.Raw_Element_Provider_Fragment_Root => 4,
        when COM.Raw_Element_Provider_Advise_Events => 5,
        when COM.Unsupported_Interface => 0);

   function Interface_From_Code
     (Code   : Interfaces.Unsigned_32;
      Result : out A11y.Results.Result)
      return A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface
   is
   begin
      Result := A11y.Results.Ok;
      case Code is
         when 1 => return COM.IUnknown_Interface;
         when 2 => return COM.Raw_Element_Provider_Simple;
         when 3 => return COM.Raw_Element_Provider_Fragment;
         when 4 => return COM.Raw_Element_Provider_Fragment_Root;
         when 5 => return COM.Raw_Element_Provider_Advise_Events;
         when others =>
            Result := (Status => A11y.Results.Invalid_Argument);
            return COM.Unsupported_Interface;
      end case;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return COM.Unsupported_Interface;
   end Interface_From_Code;

   function Direction_Code
     (Direction : A11y.Windows_Backend.UIA_Fragments.Navigate_Direction)
      return Interfaces.Unsigned_32 is
     (case Direction is
        when A11y.Windows_Backend.UIA_Fragments.Parent => 0,
        when A11y.Windows_Backend.UIA_Fragments.First_Child => 1,
        when A11y.Windows_Backend.UIA_Fragments.Last_Child => 2,
        when A11y.Windows_Backend.UIA_Fragments.Next_Sibling => 3,
        when A11y.Windows_Backend.UIA_Fragments.Previous_Sibling => 4);

   function Direction_From_Code
     (Code   : Interfaces.Unsigned_32;
      Result : out A11y.Results.Result)
      return A11y.Windows_Backend.UIA_Fragments.Navigate_Direction
   is
   begin
      Result := A11y.Results.Ok;
      case Code is
         when 0 => return A11y.Windows_Backend.UIA_Fragments.Parent;
         when 1 => return A11y.Windows_Backend.UIA_Fragments.First_Child;
         when 2 => return A11y.Windows_Backend.UIA_Fragments.Last_Child;
         when 3 => return A11y.Windows_Backend.UIA_Fragments.Next_Sibling;
         when 4 => return A11y.Windows_Backend.UIA_Fragments.Previous_Sibling;
         when others =>
            Result := (Status => A11y.Results.Invalid_Argument);
            return A11y.Windows_Backend.UIA_Fragments.Parent;
      end case;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Windows_Backend.UIA_Fragments.Parent;
   end Direction_From_Code;

   function Fits_Natural (Code : Interfaces.Unsigned_64) return Boolean is
     (Code <= Interfaces.Unsigned_64 (Natural'Last));

   function Build_Interface_Frame
     (Reference : UIA_Interface_Reference;
      Method    : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return ABI_Interface_Frame is
     (Session_Code =>
        Interfaces.Unsigned_64
          (A11y.Native_Identity.To_Natural (Reference.Session)),
      Provider_Code =>
        Interfaces.Unsigned_64
          (Reg_API.To_Natural (Reference.Provider)),
      Object_Token_Code =>
        Interfaces.Unsigned_64
          (Object_Exports.To_Natural (Reference.Token)),
      Interface_Code => Interface_Code (Reference.Kind),
      Method_Code    => ABI.Method_Code (Method),
      Direction_Code => Direction_Code (Direction),
      Point_X        => Point.X,
      Point_Y        => Point.Y);

   procedure Add_Ref
     (Reference : in out UIA_Interface_Reference;
      Report    : out Interface_Lifetime_Report)
   is
   begin
      Report := (others => <>);
      Report.Reference_Present := Reference.Present;
      Report.Reference_Released_Before := Reference.Released;
      Report.Count_Before := Reference.Reference_Count;

      if not Reference.Present or else Reference.Released then
         Report.Status := A11y.Results.Node_Unavailable;
         Report.ABI_HResult_Code :=
           Exports.HRESULT_Code (Boundary.HResult_For (Report.Status));
         Report.Count_After := Reference.Reference_Count;
         Report.Reference_Released_After := Reference.Released;
         return;
      elsif Reference.Reference_Count = Natural'Last then
         Report.Status := A11y.Results.Resource_Limit;
         Report.ABI_HResult_Code :=
           Exports.HRESULT_Code (Boundary.HResult_For (Report.Status));
         Report.Count_After := Reference.Reference_Count;
         Report.Reference_Released_After := Reference.Released;
         return;
      end if;

      Reference.Reference_Count := Reference.Reference_Count + 1;
      Report.Count_After := Reference.Reference_Count;
      Report.Reference_Released_After := Reference.Released;
      Report.Status := A11y.Results.Success;
      Report.ABI_HResult_Code := Exports.HRESULT_Code (Boundary.S_OK);
   exception
      when others =>
         Report.Status := A11y.Results.Internal_Error;
         Report.ABI_HResult_Code := Exports.HRESULT_Code (Boundary.E_FAIL);
   end Add_Ref;

   procedure Release
     (Reference : in out UIA_Interface_Reference;
      Report    : out Interface_Lifetime_Report)
   is
   begin
      Report := (others => <>);
      Report.Reference_Present := Reference.Present;
      Report.Reference_Released_Before := Reference.Released;
      Report.Count_Before := Reference.Reference_Count;

      if not Reference.Present or else Reference.Released then
         Report.Status := A11y.Results.Node_Unavailable;
         Report.ABI_HResult_Code :=
           Exports.HRESULT_Code (Boundary.HResult_For (Report.Status));
         Report.Count_After := Reference.Reference_Count;
         Report.Reference_Released_After := Reference.Released;
         return;
      elsif Reference.Reference_Count = 0 then
         Report.Status := A11y.Results.Invalid_State;
         Report.ABI_HResult_Code :=
           Exports.HRESULT_Code (Boundary.HResult_For (Report.Status));
         Report.Count_After := Reference.Reference_Count;
         Report.Reference_Released_After := Reference.Released;
         return;
      end if;

      Reference.Reference_Count := Reference.Reference_Count - 1;
      Reference.Released := Reference.Reference_Count = 0;
      Report.Count_After := Reference.Reference_Count;
      Report.Reference_Released_After := Reference.Released;
      Report.Status := A11y.Results.Success;
      Report.ABI_HResult_Code := Exports.HRESULT_Code (Boundary.S_OK);
   exception
      when others =>
         Report.Status := A11y.Results.Internal_Error;
         Report.ABI_HResult_Code := Exports.HRESULT_Code (Boundary.E_FAIL);
   end Release;

   procedure Query_Interface
     (Object_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Token     : A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Token;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Provider  : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Requested : A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Report    : out Interface_Query_Report)
   is
      Slot : VTables.Interface_Slot_Descriptor;
   begin
      Report := (others => <>);
      Object_Exports.Resolve_Object
        (Object_Table, Token, Session, Provider, Report.Object_Report);
      Report.Object_Resolved := Report.Object_Report.Found;

      if not Report.Object_Resolved then
         Report.Status := Report.Object_Report.Status;
         Report.ABI_HResult_Code :=
           Exports.HRESULT_Code (Boundary.HResult_For (Report.Status));
         return;
      end if;

      Report.Query :=
        VTables.Query_Interface
          (Report.Object_Report.Descriptor, Requested);
      if not Report.Query.Supported then
         Report.Status := Report.Query.Status;
         Report.ABI_HResult_Code := Report.Query.ABI_HResult_Code;
         return;
      end if;

      Slot :=
        VTables.Interface_Slot
          (Report.Object_Report.Descriptor, Requested);
      Report.Reference :=
        (Present           => True,
         Token             => Token,
         Kind              => Requested,
         Session           => Session,
         Provider          => Provider,
         Node              => Report.Object_Report.Descriptor.Node,
         Method_Count      => Slot.Method_Count,
         Reference_Count   => 1,
         Released          => False,
         Status            => A11y.Results.Success,
         ABI_HResult_Code  => Report.Query.ABI_HResult_Code);
      Report.Status := A11y.Results.Success;
      Report.ABI_HResult_Code := Report.Query.ABI_HResult_Code;
   exception
      when others =>
         Report :=
           (Object_Resolved  => False,
            Object_Report    => <>,
            Query            => <>,
            Reference        => <>,
            Status           => A11y.Results.Internal_Error,
            ABI_HResult_Code => Exports.HRESULT_Code (Boundary.E_FAIL));
   end Query_Interface;

   function Dispatch_Interface_Method
     (Object_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Reference : UIA_Interface_Reference;
      Method    : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : out Interface_Dispatch_Report;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply
   is
      Snapshot_Copy :
        aliased A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle :=
          Snapshots;
   begin
      return Dispatch_Interface_Method_Access
        (Object_Table, Reference, Method, Registry, Snapshot_Copy'Access,
         Report, Direction, Point);
   end Dispatch_Interface_Method;

   function Dispatch_Interface_Method_Access
     (Object_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Reference : UIA_Interface_Reference;
      Method    : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : in out Interface_Dispatch_Report;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply
   is
      Report_Copy : aliased Interface_Dispatch_Report := Report;
      Reply : Boundary.Boundary_Reply;
   begin
      Reply :=
        Dispatch_Interface_Method_Report_Access
          (Object_Table, Reference, Method, Registry, Snapshots,
           Report_Copy'Unchecked_Access, Direction, Point);
      Report := Report_Copy;
      return Reply;
   end Dispatch_Interface_Method_Access;

   function Dispatch_Interface_Method_Report_Access
     (Object_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Reference : UIA_Interface_Reference;
      Method    : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : not null Interface_Dispatch_Report_Access;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply
   is
      Table : Exports.COM_Export_Table;
      Reply : Boundary.Boundary_Reply;
   begin
      Report.all := (others => <>);

      if not Reference.Present or else Reference.Released then
         Reply := Error_Reply (A11y.Results.Node_Unavailable);
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;

      Object_Exports.Resolve_Object
        (Object_Table,
         Reference.Token,
         Reference.Session,
         Reference.Provider,
         Report.all.Object_Report);

      if not Report.all.Object_Report.Found then
         Reply := Error_Reply (Report.all.Object_Report.Status);
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;

      Report.all.Object_Resolved := True;
      Report.all.Interface_Accepted :=
        VTables.Interface_Supported
          (Report.all.Object_Report.Descriptor, Reference.Kind)
        and then Report.all.Object_Report.Descriptor.Provider =
          Reference.Provider
        and then Report.all.Object_Report.Descriptor.Node = Reference.Node;

      if not Report.all.Interface_Accepted then
         Reply := Error_Reply (A11y.Results.Unsupported_Capability);
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;

      Report.all.Method_Allowed_For_Interface :=
        Method_Belongs_To_Interface (Reference, Method);
      if not Report.all.Method_Allowed_For_Interface then
         Reply := Error_Reply (A11y.Results.Unsupported_Capability);
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;

      Report.all.Frame :=
        VTables.Frame_For (Report.all.Object_Report.Descriptor, Method);
      Report.all.Frame_Prepared := Report.all.Frame.Supported;
      if not Report.all.Frame_Prepared then
         Reply := Error_Reply (Report.all.Frame.Status);
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;

      Table := Table_From (Report.all.Object_Report.Descriptor);
      Reply :=
        Exports.Invoke_Callback_Frame_Report_Access
          (Table,
           Report.all.Frame.Frame,
           Registry,
           Snapshots,
           Report.all.Callback'Unchecked_Access,
           Direction,
           Point);
      Report.all.Callback_Dispatched :=
        Report.all.Callback.Frame_Matches_Export
        and then Report.all.Callback.Method_Code_Valid;
      Report.all.Status := Reply.Status;
      Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
      return Reply;
   exception
      when others =>
         Report.all.Status := A11y.Results.Internal_Error;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Boundary.E_FAIL);
         return Error_Reply (A11y.Results.Internal_Error);
   end Dispatch_Interface_Method_Report_Access;

   function Dispatch_Interface_Frame
     (Object_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Frame     : ABI_Interface_Frame;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : out ABI_Interface_Frame_Report)
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply
   is
      Snapshot_Copy :
        aliased A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle :=
          Snapshots;
   begin
      return Dispatch_Interface_Frame_Access
        (Object_Table, Frame, Registry, Snapshot_Copy'Access, Report);
   end Dispatch_Interface_Frame;

   function Dispatch_Interface_Frame_Access
     (Object_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Frame     : ABI_Interface_Frame;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : in out ABI_Interface_Frame_Report)
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply
   is
      Report_Copy : aliased ABI_Interface_Frame_Report := Report;
      Reply : Boundary.Boundary_Reply;
   begin
      Reply :=
        Dispatch_Interface_Frame_Report_Access
          (Object_Table, Frame, Registry, Snapshots,
           Report_Copy'Unchecked_Access);
      Report := Report_Copy;
      return Reply;
   end Dispatch_Interface_Frame_Access;

   function Dispatch_Interface_Frame_Report_Access
     (Object_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Frame     : ABI_Interface_Frame;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : not null ABI_Interface_Frame_Report_Access)
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply
   is
      Session : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Provider : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id :=
        Reg_API.No_Provider;
      Token : A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Token :=
        Object_Exports.No_COM_Object;
      Requested : COM.Provider_Interface := COM.Unsupported_Interface;
      Method : ABI.UIA_ABI_Method := ABI.IUnknown_Query_Interface;
      Direction : A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
        A11y.Windows_Backend.UIA_Fragments.Parent;
      Decode_Result : A11y.Results.Result;
      Query_Report : Interface_Query_Report;
      Reply : Boundary.Boundary_Reply;
   begin
      Report.all := (others => <>);

      if not Fits_Natural (Frame.Session_Code) then
         Reply := Error_Reply (A11y.Results.Invalid_Argument);
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;
      Session :=
        A11y.Native_Identity.From_Natural
          (Natural (Frame.Session_Code));
      Report.all.Session_Code_Valid := A11y.Native_Identity.Is_Valid (Session);
      if not Report.all.Session_Code_Valid then
         Reply := Error_Reply (A11y.Results.Node_Unavailable);
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;

      if not Fits_Natural (Frame.Provider_Code) then
         Reply := Error_Reply (A11y.Results.Invalid_Argument);
         Report.all.Session_Code_Valid := True;
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;
      Provider := Reg_API.From_Natural (Natural (Frame.Provider_Code));
      Report.all.Provider_Code_Valid := Reg_API.Is_Valid (Provider);
      if not Report.all.Provider_Code_Valid then
         Reply := Error_Reply (A11y.Results.Node_Unavailable);
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;

      if not Fits_Natural (Frame.Object_Token_Code) then
         Reply := Error_Reply (A11y.Results.Invalid_Argument);
         Report.all.Session_Code_Valid := True;
         Report.all.Provider_Code_Valid := True;
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;
      Token := Object_Exports.From_Natural
        (Natural (Frame.Object_Token_Code));
      Report.all.Object_Token_Valid := Object_Exports.Is_Valid (Token);
      if not Report.all.Object_Token_Valid then
         Reply := Error_Reply (A11y.Results.Node_Unavailable);
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;

      Requested := Interface_From_Code (Frame.Interface_Code, Decode_Result);
      Report.all.Interface_Code_Valid := A11y.Results.Succeeded (Decode_Result);
      if not Report.all.Interface_Code_Valid then
         Reply := Error_Reply (Decode_Result.Status);
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;

      Method := ABI.Method_From_Code (Frame.Method_Code, Decode_Result);
      Report.all.Method_Code_Valid := A11y.Results.Succeeded (Decode_Result);
      if not Report.all.Method_Code_Valid then
         Reply := Error_Reply (Decode_Result.Status);
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;

      if Method = ABI.Fragment_Navigate then
         Direction := Direction_From_Code (Frame.Direction_Code, Decode_Result);
         Report.all.Direction_Code_Valid :=
           A11y.Results.Succeeded (Decode_Result);
         if not Report.all.Direction_Code_Valid then
            Reply := Error_Reply (Decode_Result.Status);
            Report.all.Status := Reply.Status;
            Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
            return Reply;
         end if;
      else
         Report.all.Direction_Code_Valid := Frame.Direction_Code = 0;
         if not Report.all.Direction_Code_Valid then
            Reply := Error_Reply (A11y.Results.Invalid_Argument);
            Report.all.Status := Reply.Status;
            Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
            return Reply;
         end if;
      end if;

      if Method /= ABI.Fragment_Root_Element_Provider_From_Point
        and then (Frame.Point_X /= 0 or else Frame.Point_Y /= 0)
      then
         Reply := Error_Reply (A11y.Results.Invalid_Argument);
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;

      Query_Interface
        (Object_Table,
         Token,
         Session,
         Provider,
         Requested,
         Query_Report);
      Report.all.Reference_Queried :=
        Query_Report.Object_Resolved
        and then Query_Report.Query.Supported
        and then Query_Report.Reference.Present;
      if not Report.all.Reference_Queried then
         Reply := Error_Reply (Query_Report.Status);
         Report.all.Status := Reply.Status;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
         return Reply;
      end if;

      Reply :=
        Dispatch_Interface_Method_Report_Access
          (Object_Table,
           Query_Report.Reference,
           Method,
           Registry,
           Snapshots,
           Report.all.Dispatch'Unchecked_Access,
           Direction,
           (X => Frame.Point_X, Y => Frame.Point_Y));
      Report.all.Status := Reply.Status;
      Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Reply.HResult);
      return Reply;
   exception
      when others =>
         Report.all.Status := A11y.Results.Internal_Error;
         Report.all.ABI_HResult_Code := Exports.HRESULT_Code (Boundary.E_FAIL);
         return Error_Reply (A11y.Results.Internal_Error);
   end Dispatch_Interface_Frame_Report_Access;

end A11y.Windows_Backend.UIA_COM_Live_Exports;
