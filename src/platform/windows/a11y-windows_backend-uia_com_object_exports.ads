with A11y.Native_Identity;
with A11y.Results;
with A11y.Windows_Backend.UIA_COM_VTables;
with A11y.Windows_Backend.UIA_Provider_Registry;

package A11y.Windows_Backend.UIA_COM_Object_Exports is

   Max_COM_Object_Exports : constant Natural := 4_096;

   type COM_Object_Token is private;
   No_COM_Object : constant COM_Object_Token;

   function Is_Valid (Token : COM_Object_Token) return Boolean;
   function To_Natural (Token : COM_Object_Token) return Natural;
   function From_Natural (Value : Natural) return COM_Object_Token;
   function Image (Token : COM_Object_Token) return String;

   type COM_Object_Export_Table is limited private;

   type Export_Table_Snapshot is record
      Live_Count : Natural := 0;
      Tombstones : Natural := 0;
      Generation : Natural := 0;
      Capacity   : Natural := Max_COM_Object_Exports;
      Next_Token : Natural := 1;
   end record;

   type Object_Export_Report is record
      Exported  : Boolean := False;
      Token     : COM_Object_Token := No_COM_Object;
      Status    : A11y.Results.Status_Code := A11y.Results.Node_Unavailable;
      Generation_Before : Natural := 0;
      Generation_After  : Natural := 0;
      Descriptor :
        A11y.Windows_Backend.UIA_COM_VTables.COM_Object_Descriptor;
   end record;

   type Object_Resolve_Report is record
      Found     : Boolean := False;
      Token     : COM_Object_Token := No_COM_Object;
      Status    : A11y.Results.Status_Code := A11y.Results.Node_Unavailable;
      Released  : Boolean := False;
      Stale     : Boolean := False;
      Defunct   : Boolean := False;
      Descriptor :
        A11y.Windows_Backend.UIA_COM_VTables.COM_Object_Descriptor;
   end record;

   type Object_Release_Report is record
      Released  : Boolean := False;
      Token     : COM_Object_Token := No_COM_Object;
      Status    : A11y.Results.Status_Code := A11y.Results.Node_Unavailable;
      Generation_Before : Natural := 0;
      Generation_After  : Natural := 0;
      Tombstone_Added   : Boolean := False;
   end record;

   procedure Export_Object
     (Table      : in out COM_Object_Export_Table;
      Descriptor : A11y.Windows_Backend.UIA_COM_VTables.COM_Object_Descriptor;
      Report     : out Object_Export_Report);

   procedure Resolve_Object
     (Table    : COM_Object_Export_Table;
      Token    : COM_Object_Token;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Provider : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Report   : out Object_Resolve_Report);

   procedure Release_Object
     (Table  : in out COM_Object_Export_Table;
      Token  : COM_Object_Token;
      Report : out Object_Release_Report);

   function Snapshot
     (Table : COM_Object_Export_Table)
      return Export_Table_Snapshot;

private
   type COM_Object_Token is new Natural;
   No_COM_Object : constant COM_Object_Token := 0;

   type Export_Record is record
      Used       : Boolean := False;
      Released   : Boolean := False;
      Descriptor :
        A11y.Windows_Backend.UIA_COM_VTables.COM_Object_Descriptor;
   end record;

   type Export_Record_Table is array
     (Positive range 1 .. Max_COM_Object_Exports) of Export_Record;

   type COM_Object_Export_Table is limited record
      Next       : Natural := 1;
      Generation : Natural := 0;
      Records    : Export_Record_Table;
   end record;

end A11y.Windows_Backend.UIA_COM_Object_Exports;
