with Ada.Strings.Unbounded;

with A11y.Capabilities;
with A11y.Linux.DBus_Codec;
with A11y.Linux.ATSPi_Mappings;
with A11y.Linux.ATSPi_Objects;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Roles;

package A11y.Linux.ATSPi_Cache is

   type Interface_Set is array (A11y.Linux.ATSPi_Objects.ATSPI_Interface)
     of Boolean;

   Empty_Interface_Set : constant Interface_Set := [others => False];

   type Cache_Snapshot is record
      Id           : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Parent       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Role         : A11y.Roles.Role := A11y.Roles.Custom;
      Name         : Ada.Strings.Unbounded.Unbounded_String;
      Description  : Ada.Strings.Unbounded.Unbounded_String;
      Child_Count  : Natural := 0;
      Capabilities : A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.Empty_Capability_Set;
      Defunct      : Boolean := False;
   end record;

   type Cached_Node is record
      Path         : Ada.Strings.Unbounded.Unbounded_String;
      Parent_Path  : Ada.Strings.Unbounded.Unbounded_String;
      Role         : A11y.Linux.ATSPi_Mappings.ATSPI_Role :=
        A11y.Linux.ATSPi_Mappings.Invalid;
      Name         : Ada.Strings.Unbounded.Unbounded_String;
      Description  : Ada.Strings.Unbounded.Unbounded_String;
      Child_Count  : Natural := 0;
      Interfaces   : Interface_Set := Empty_Interface_Set;
   end record;

   function Interfaces_For
     (Capabilities : A11y.Capabilities.Capability_Set)
      return Interface_Set;

   function Interfaces_For
     (Snapshot : Cache_Snapshot)
      return Interface_Set;

   function Interface_Names
     (Interfaces : Interface_Set)
      return A11y.Linux.DBus_Codec.String_Vectors.Vector;

   function Build_Node
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Snapshot : Cache_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return Cached_Node;

   function Build_Node
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Snapshot : Cache_Snapshot;
      Result   : out A11y.Results.Result)
      return Cached_Node;

end A11y.Linux.ATSPi_Cache;
