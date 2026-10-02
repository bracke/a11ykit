package body A11y.Windows_Backend.UIA_COM_Object_Exports is

   use type A11y.Native_Identity.Backend_Session_Id;
   use type A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;

   function Trimmed_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Trimmed_Image;

   function Is_Valid (Token : COM_Object_Token) return Boolean is
     (Token /= No_COM_Object);

   function To_Natural (Token : COM_Object_Token) return Natural is
     (Natural (Token));

   function From_Natural (Value : Natural) return COM_Object_Token is
     (COM_Object_Token (Value));

   function Image (Token : COM_Object_Token) return String is
     (if Token = No_COM_Object then "none"
      else Trimmed_Image (Natural (Token)));

   procedure Advance_Generation (Table : in out COM_Object_Export_Table) is
   begin
      if Table.Generation < Natural'Last then
         Table.Generation := Table.Generation + 1;
      end if;
   end Advance_Generation;

   function Snapshot
     (Table : COM_Object_Export_Table)
      return Export_Table_Snapshot
   is
      Live : Natural := 0;
      Tombstones : Natural := 0;
   begin
      for Index in 1 .. Table.Next - 1 loop
         if Table.Records (Index).Used then
            if Table.Records (Index).Released then
               Tombstones := Tombstones + 1;
            else
               Live := Live + 1;
            end if;
         end if;
      end loop;

      return
        (Live_Count => Live,
         Tombstones => Tombstones,
         Generation => Table.Generation,
         Capacity   => Max_COM_Object_Exports,
         Next_Token => Table.Next);
   end Snapshot;

   procedure Export_Object
     (Table      : in out COM_Object_Export_Table;
      Descriptor : A11y.Windows_Backend.UIA_COM_VTables.COM_Object_Descriptor;
      Report     : out Object_Export_Report)
   is
      Before : constant Natural := Table.Generation;
      Token : COM_Object_Token := No_COM_Object;
   begin
      Report := (others => <>);
      Report.Generation_Before := Before;
      Report.Generation_After := Before;
      Report.Descriptor := Descriptor;

      if not Descriptor.Exportable
        or else not Descriptor.Controlling_IUnknown_Stable
        or else Descriptor.Defunct
        or else not A11y.Native_Identity.Is_Valid (Descriptor.Session)
        or else not A11y.Windows_Backend.UIA_Provider_Registry.Is_Valid
          (Descriptor.Provider)
      then
         Report.Status := A11y.Results.Node_Unavailable;
         return;
      elsif Table.Next > Max_COM_Object_Exports then
         Report.Status := A11y.Results.Resource_Limit;
         return;
      end if;

      Token := COM_Object_Token (Table.Next);
      Table.Records (Table.Next) :=
        (Used       => True,
         Released   => False,
         Descriptor => Descriptor);
      Table.Next := Table.Next + 1;
      Advance_Generation (Table);

      Report.Exported := True;
      Report.Token := Token;
      Report.Status := A11y.Results.Success;
      Report.Generation_After := Table.Generation;
   exception
      when others =>
         Report :=
           (Exported          => False,
            Token             => No_COM_Object,
            Status            => A11y.Results.Internal_Error,
            Generation_Before => Before,
            Generation_After  => Table.Generation,
            Descriptor        => Descriptor);
   end Export_Object;

   procedure Resolve_Object
     (Table    : COM_Object_Export_Table;
      Token    : COM_Object_Token;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Provider : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Report   : out Object_Resolve_Report)
   is
      Slot : constant Natural := Natural (Token);
      Descriptor :
        A11y.Windows_Backend.UIA_COM_VTables.COM_Object_Descriptor;
   begin
      Report := (others => <>);
      Report.Token := Token;

      if Slot = 0
        or else Slot >= Table.Next
        or else not Table.Records (Slot).Used
      then
         Report.Status := A11y.Results.Node_Unavailable;
         Report.Stale := Is_Valid (Token);
         return;
      end if;

      Descriptor := Table.Records (Slot).Descriptor;
      Report.Descriptor := Descriptor;
      Report.Released := Table.Records (Slot).Released;
      Report.Defunct := Descriptor.Defunct;
      Report.Stale :=
        Descriptor.Session /= Session or else Descriptor.Provider /= Provider;

      if Report.Released or else Report.Defunct or else Report.Stale then
         Report.Status := A11y.Results.Node_Unavailable;
      else
         Report.Found := True;
         Report.Status := A11y.Results.Success;
      end if;
   exception
      when others =>
         Report :=
           (Found      => False,
            Token      => Token,
            Status     => A11y.Results.Internal_Error,
            Released   => False,
            Stale      => True,
            Defunct    => True,
            Descriptor => <>);
   end Resolve_Object;

   procedure Release_Object
     (Table  : in out COM_Object_Export_Table;
      Token  : COM_Object_Token;
      Report : out Object_Release_Report)
   is
      Slot : constant Natural := Natural (Token);
      Before : constant Natural := Table.Generation;
   begin
      Report :=
        (Released          => False,
         Token             => Token,
         Status            => A11y.Results.Node_Unavailable,
         Generation_Before => Before,
         Generation_After  => Before,
         Tombstone_Added   => False);

      if Slot = 0
        or else Slot >= Table.Next
        or else not Table.Records (Slot).Used
        or else Table.Records (Slot).Released
      then
         return;
      end if;

      Table.Records (Slot).Released := True;
      Advance_Generation (Table);
      Report.Released := True;
      Report.Status := A11y.Results.Success;
      Report.Generation_After := Table.Generation;
      Report.Tombstone_Added := True;
   exception
      when others =>
         Report.Status := A11y.Results.Internal_Error;
         Report.Generation_After := Table.Generation;
   end Release_Object;

end A11y.Windows_Backend.UIA_COM_Object_Exports;
