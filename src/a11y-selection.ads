with Ada.Containers.Vectors;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Selection is

   Max_Selected_Items : constant Natural := 65_536;

   type Selection_Mode is
     (None,
      Single,
      Multiple,
      Contiguous_Multiple,
      Extended);

   type Selection_Direction is
     (No_Direction,
      Forward,
      Backward,
      Unknown);

   type Selection_Mode_Metadata is record
      Stable_Name        : access constant String;
      Allows_Selection   : Boolean := False;
      Allows_Multiple    : Boolean := False;
      Allows_Range       : Boolean := False;
   end record;

   package Node_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => A11y.Node_Ids.Node_Id,
      "="          => A11y.Node_Ids."=");

   type Selection_Metadata is private;
   type Selection_Set is private;

   function Metadata (Mode : Selection_Mode) return Selection_Mode_Metadata;

   function Stable_Name (Mode : Selection_Mode) return String;
   function Stable_Name (Direction : Selection_Direction) return String;

   function Allows_Selection
     (Mode : Selection_Mode)
      return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Allows_Selection'Result = (Mode /= None);

   function Allows_Multiple
     (Mode : Selection_Mode)
      return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Allows_Multiple'Result =
          (Mode in Multiple | Contiguous_Multiple | Extended);

   function Allows_Range
     (Mode : Selection_Mode)
      return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Allows_Range'Result =
          (Mode in Contiguous_Multiple | Extended);

   function Allows_Required_Selection
     (Mode : Selection_Mode)
      return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Allows_Required_Selection'Result = Allows_Selection (Mode);

   function Count_Allowed
     (Mode  : Selection_Mode;
      Count : Natural)
      return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Count_Allowed'Result =
          ((Mode = None and then Count = 0)
           or else (Mode = Single and then Count <= 1)
           or else (Mode in Multiple | Contiguous_Multiple | Extended));

   function Is_Known_Direction
     (Direction : Selection_Direction)
      return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Is_Known_Direction'Result =
          (Direction in No_Direction | Forward | Backward);

   function Is_Range_Direction
     (Direction : Selection_Direction)
      return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Is_Range_Direction'Result =
          (Direction in Forward | Backward);

   function Direction_Allowed
     (Mode      : Selection_Mode;
      Direction : Selection_Direction)
      return Standard.Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Direction_Allowed'Result =
          (if Is_Range_Direction (Direction) then Allows_Range (Mode)
           else Direction /= Unknown);

   function Empty_Metadata return Selection_Metadata
   with SPARK_Mode => On;

   function Mode (Self : Selection_Metadata) return Selection_Mode
   with SPARK_Mode => On;
   function Requires_Selection (Self : Selection_Metadata) return Boolean
   with SPARK_Mode => On;
   function Count (Self : Selection_Metadata) return Natural
   with SPARK_Mode => On;
   function Capacity (Self : Selection_Metadata) return Natural
   with SPARK_Mode => On;
   function Anchor (Self : Selection_Metadata) return A11y.Node_Ids.Node_Id
   with SPARK_Mode => On;
   function Current_Item
     (Self : Selection_Metadata)
      return A11y.Node_Ids.Node_Id
   with SPARK_Mode => On;
   function Direction (Self : Selection_Metadata) return Selection_Direction
   with SPARK_Mode => On;

   function Metadata_Of (Self : Selection_Set) return Selection_Metadata;
   function Mode (Self : Selection_Set) return Selection_Mode;
   function Requires_Selection (Self : Selection_Set) return Boolean;
   function Count (Self : Selection_Set) return Natural;
   function Capacity (Self : Selection_Set) return Natural;
   function Contains
     (Self : Selection_Set;
      Node : A11y.Node_Ids.Node_Id)
      return Boolean;
   function Selected_At
     (Self  : Selection_Set;
      Index : Positive)
      return A11y.Node_Ids.Node_Id;
   function Items (Self : Selection_Set) return Node_Vectors.Vector;
   function Anchor (Self : Selection_Set) return A11y.Node_Ids.Node_Id;
   function Current_Item (Self : Selection_Set) return A11y.Node_Ids.Node_Id;
   function Direction (Self : Selection_Set) return Selection_Direction;
   function Validate (Self : Selection_Set) return A11y.Results.Result;

   procedure Configure
     (Self               : in out Selection_Set;
      Mode               : Selection_Mode;
      Requires_Selection : Boolean := False);

   procedure Configure_Limits
     (Self   : in out Selection_Set;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result);

   procedure Set_Capacity
     (Self     : in out Selection_Set;
      Capacity : Natural;
      Result   : out A11y.Results.Result);

   procedure Select_Item
     (Self   : in out Selection_Set;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   procedure Deselect
     (Self   : in out Selection_Set;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   procedure Toggle
     (Self   : in out Selection_Set;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   procedure Select_Range
     (Self   : in out Selection_Set;
      Nodes  : Node_Vectors.Vector;
      Result : out A11y.Results.Result;
      Direction : Selection_Direction := Forward);

   procedure Select_All
     (Self   : in out Selection_Set;
      Nodes  : Node_Vectors.Vector;
      Result : out A11y.Results.Result);

   procedure Clear
     (Self   : in out Selection_Set;
      Result : out A11y.Results.Result);

   procedure Set_Current_Item
     (Self   : in out Selection_Set;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);

   procedure Clear_Current_Item
     (Self   : in out Selection_Set;
      Result : out A11y.Results.Result);

   type Selection_Provider is limited interface;

   function Current_Selection
     (Self : Selection_Provider)
      return Selection_Set is abstract;

   function Select_Node
     (Self : in out Selection_Provider;
      Node : A11y.Node_Ids.Node_Id)
      return A11y.Results.Result is abstract;

   function Deselect_Node
     (Self : in out Selection_Provider;
      Node : A11y.Node_Ids.Node_Id)
      return A11y.Results.Result is abstract;

   function Toggle_Node
     (Self : in out Selection_Provider;
      Node : A11y.Node_Ids.Node_Id)
      return A11y.Results.Result is abstract;

   function Clear_Selection
     (Self : in out Selection_Provider)
      return A11y.Results.Result is abstract;

   function Current_Selection_Safely
     (Self : Selection_Provider'Class)
      return Selection_Set;

   function Select_Node_Safely
     (Self : in out Selection_Provider'Class;
      Node : A11y.Node_Ids.Node_Id)
      return A11y.Results.Result;

   function Deselect_Node_Safely
     (Self : in out Selection_Provider'Class;
      Node : A11y.Node_Ids.Node_Id)
      return A11y.Results.Result;

   function Toggle_Node_Safely
     (Self : in out Selection_Provider'Class;
      Node : A11y.Node_Ids.Node_Id)
      return A11y.Results.Result;

   function Clear_Selection_Safely
     (Self : in out Selection_Provider'Class)
      return A11y.Results.Result;

private
   type Selection_Metadata is record
      Selection_Mode      : Selection.Selection_Mode := None;
      Selection_Required  : Boolean := False;
      Limit               : Natural := Max_Selected_Items;
      Selected_Count      : Natural := 0;
      Anchor_Node         : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Current_Node        : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Range_Direction     : Selection.Selection_Direction := No_Direction;
   end record;

   type Selection_Set is record
      Metadata : Selection_Metadata;
      Selected : Node_Vectors.Vector;
   end record;

end A11y.Selection;
