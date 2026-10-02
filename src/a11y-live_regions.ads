with Ada.Strings.Unbounded;

with A11y.Resource_Limits;
with A11y.Results;

package A11y.Live_Regions is

   subtype UString is Ada.Strings.Unbounded.Unbounded_String;

   type Live_Setting is
     (Off,
      Polite,
      Assertive);

   type Relevant_Change is
     (Additions,
      Removals,
      Text);

   type Relevant_Change_Set is array (Relevant_Change) of Boolean;

   Empty_Relevant_Change_Set : constant Relevant_Change_Set :=
     [others => False];

   type Live_Setting_Metadata is record
      Stable_Name : access constant String;
      Externally_Announced : Boolean := False;
      Interruptive : Boolean := False;
   end record;

   type Relevant_Change_Metadata is record
      Stable_Name : access constant String;
   end record;

   type Live_Region_Metadata is record
      Setting  : Live_Setting := Off;
      Atomic   : Boolean := False;
      Relevant : Relevant_Change_Set := Empty_Relevant_Change_Set;
   end record;

   type Announcement is record
      Text : UString;
   end record;

   function Metadata
     (Setting : Live_Setting)
      return Live_Setting_Metadata;

   function Stable_Name (Setting : Live_Setting) return String;

   function Metadata
     (Change : Relevant_Change)
      return Relevant_Change_Metadata;

   function Stable_Name (Change : Relevant_Change) return String;

   function Is_Externally_Announced
     (Setting : Live_Setting)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Is_Externally_Announced'Result =
         (Setting in Polite | Assertive);

   function Is_Interruptive
     (Setting : Live_Setting)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Interruptive'Result = (Setting = Assertive);

   function Has_Relevant_Changes
     (Set : Relevant_Change_Set)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Has_Relevant_Changes'Result =
         (Set (Additions) or else Set (Removals) or else Set (Text));

   function Relevant_Count
     (Set : Relevant_Change_Set)
      return Natural
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Relevant_Count'Result =
         (0
          + (if Set (Additions) then 1 else 0)
          + (if Set (Removals) then 1 else 0)
          + (if Set (Text) then 1 else 0));

   function Relevant_Names
     (Set : Relevant_Change_Set)
      return String;

   function With_Change
     (Set    : Relevant_Change_Set;
      Change : Relevant_Change)
      return Relevant_Change_Set
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       With_Change'Result (Change)
       and then
         (for all Item in Relevant_Change =>
            (if Item /= Change then With_Change'Result (Item) = Set (Item)));

   function Validate
     (Item : Live_Region_Metadata)
      return A11y.Results.Result
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       A11y.Results.Succeeded (Validate'Result) =
         ((Item.Setting = Off
           and then not Has_Relevant_Changes (Item.Relevant))
          or else
            (Item.Setting /= Off
             and then Has_Relevant_Changes (Item.Relevant)));

   function Metadata_Is_Coherent
     (Item : Live_Region_Metadata)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Metadata_Is_Coherent'Result =
         ((Item.Setting = Off
           and then not Has_Relevant_Changes (Item.Relevant))
          or else
            (Item.Setting /= Off
             and then Has_Relevant_Changes (Item.Relevant)));

   type Live_Region_Provider is limited interface;

   function Current_Metadata
     (Self : Live_Region_Provider)
      return Live_Region_Metadata is abstract;

   function Current_Metadata_Safely
     (Self   : Live_Region_Provider'Class;
      Result : out A11y.Results.Result)
      return Live_Region_Metadata;

   procedure Create_Announcement
     (Text       : String;
      Is_Protected : Boolean;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config;
      Item       : out Announcement;
      Result     : out A11y.Results.Result);

end A11y.Live_Regions;
