package body A11y.Linux.ATSPi_Cache is
   use type A11y.Roles.Role;

   function Interfaces_For
     (Capabilities : A11y.Capabilities.Capability_Set)
      return Interface_Set
   is
      Result : Interface_Set := Empty_Interface_Set;
   begin
      Result (A11y.Linux.ATSPi_Objects.Accessible) := True;
      Result (A11y.Linux.ATSPi_Objects.Component) := True;

      if Capabilities (A11y.Capabilities.Action) then
         Result (A11y.Linux.ATSPi_Objects.Action) := True;
      end if;

      if Capabilities (A11y.Capabilities.Selection) then
         Result (A11y.Linux.ATSPi_Objects.Selection) := True;
      end if;

      if Capabilities (A11y.Capabilities.Value) then
         Result (A11y.Linux.ATSPi_Objects.Value) := True;
      end if;

      if Capabilities (A11y.Capabilities.Text) then
         Result (A11y.Linux.ATSPi_Objects.Text) := True;
      end if;

      if Capabilities (A11y.Capabilities.Editable_Text) then
         Result (A11y.Linux.ATSPi_Objects.Editable_Text) := True;
      end if;

      if Capabilities (A11y.Capabilities.Table) then
         Result (A11y.Linux.ATSPi_Objects.Table) := True;
         Result (A11y.Linux.ATSPi_Objects.Table_Cell) := True;
      end if;

      if Capabilities (A11y.Capabilities.Document) then
         Result (A11y.Linux.ATSPi_Objects.Document) := True;
      end if;

      if Capabilities (A11y.Capabilities.Image) then
         Result (A11y.Linux.ATSPi_Objects.Image) := True;
      end if;

      return Result;
   end Interfaces_For;

   function Interfaces_For
     (Snapshot : Cache_Snapshot)
      return Interface_Set
   is
      Result : Interface_Set := Interfaces_For (Snapshot.Capabilities);
   begin
      if Snapshot.Role = A11y.Roles.Application then
         Result (A11y.Linux.ATSPi_Objects.Application) := True;
      end if;

      return Result;
   end Interfaces_For;

   function Interface_Names
     (Interfaces : Interface_Set)
      return A11y.Linux.DBus_Codec.String_Vectors.Vector
   is
      Names : A11y.Linux.DBus_Codec.String_Vectors.Vector;
   begin
      for Item in Interfaces'Range loop
         if Interfaces (Item) then
            Names.Append
              (Ada.Strings.Unbounded.To_Unbounded_String
                 (A11y.Linux.ATSPi_Objects.Interface_Name (Item)));
         end if;
      end loop;

      return Names;
   end Interface_Names;

   function Build_Node
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Snapshot : Cache_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return Cached_Node
   is
      use Ada.Strings.Unbounded;

      Path        : Unbounded_String;
      Parent_Path : Unbounded_String;
      Check       : A11y.Results.Result;
      Ignored     : A11y.Linux.DBus_Codec.DBus_Value;
      Interfaces  : Interface_Set;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return (others => <>);
      end if;

      if not A11y.Native_Identity.Is_Valid (Session) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return (others => <>);
      end if;

      if not A11y.Node_Ids.Is_Valid (Snapshot.Id) or else Snapshot.Defunct then
         Result := (Status => A11y.Results.Node_Unavailable);
         return (others => <>);
      end if;

      Path := A11y.Linux.ATSPi_Objects.Object_Path
        (Session, Snapshot.Id, Check);
      if A11y.Results.Failed (Check) then
         Result := Check;
         return (others => <>);
      end if;
      Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
        (To_String (Path), Limits, Check);
      if A11y.Results.Failed (Check) then
         Result := Check;
         return (others => <>);
      end if;

      if A11y.Node_Ids.Is_Valid (Snapshot.Parent) then
         Parent_Path := A11y.Linux.ATSPi_Objects.Object_Path
           (Session, Snapshot.Parent, Check);
         if A11y.Results.Failed (Check) then
            Result := Check;
            return (others => <>);
         end if;
         Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
           (To_String (Parent_Path), Limits, Check);
         if A11y.Results.Failed (Check) then
            Result := Check;
            return (others => <>);
         end if;
      else
         Parent_Path := Null_Unbounded_String;
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Snapshot.Name), Limits, Check);
      if A11y.Results.Failed (Check) then
         Result := Check;
         return (others => <>);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Snapshot.Description), Limits, Check);
      if A11y.Results.Failed (Check) then
         Result := Check;
         return (others => <>);
      end if;

      Interfaces := Interfaces_For (Snapshot);
      Ignored := A11y.Linux.DBus_Codec.Make_String_Array
        (Interface_Names (Interfaces), Limits, Check);
      if A11y.Results.Failed (Check) then
         Result := Check;
         return (others => <>);
      end if;

      Result := A11y.Results.Ok;
      return
        (Path         => Path,
         Parent_Path  => Parent_Path,
         Role         => A11y.Linux.ATSPi_Mappings.Map_Role (Snapshot.Role),
         Name         => Snapshot.Name,
         Description  => Snapshot.Description,
         Child_Count  => Snapshot.Child_Count,
         Interfaces   => Interfaces);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return (others => <>);
   end Build_Node;

   function Build_Node
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Snapshot : Cache_Snapshot;
      Result   : out A11y.Results.Result)
      return Cached_Node is
     (Build_Node
        (Session, Snapshot, A11y.Resource_Limits.Default_Config, Result));

end A11y.Linux.ATSPi_Cache;
