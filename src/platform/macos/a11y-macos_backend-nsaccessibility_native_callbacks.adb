with System.Address_To_Access_Conversions;

with Ada.Strings.Unbounded;
with Interfaces.C;

with A11y.MacOS_Backend.NSAccessibility_Actions;
with A11y.MacOS_Backend.NSAccessibility_Hierarchy;
with A11y.MacOS_Backend.NSAccessibility_Mappings;
with A11y.MacOS_Backend.NSAccessibility_Properties;
with A11y.MacOS_Backend.NSAccessibility_Provider_Boundary;
with A11y.Geometry;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Relations;
with A11y.Trees;

package body A11y.MacOS_Backend.NSAccessibility_Native_Callbacks is

   package ABI renames A11y.MacOS_Backend.NSAccessibility_ABI_Surface;
   package Native renames A11y.MacOS_Backend.NSAccessibility_Native_Bridge;
   package Router renames A11y.MacOS_Backend.NSAccessibility_Request_Router;
   package Properties renames
     A11y.MacOS_Backend.NSAccessibility_Properties;
   package Actions renames A11y.MacOS_Backend.NSAccessibility_Actions;

   Native_Value_None : constant Native.Native_UInt32 := 0;
   Native_Value_Attribute_Array : constant Native.Native_UInt32 := 1;
   Native_Value_Action_Array : constant Native.Native_UInt32 := 2;
   Native_Value_UTF8_String : constant Native.Native_UInt32 := 3;
   Native_Value_Boolean : constant Native.Native_UInt32 := 4;
   Native_Value_Integer : constant Native.Native_UInt32 := 5;
   Native_Value_Role : constant Native.Native_UInt32 := 6;
   Native_Value_Rectangle : constant Native.Native_UInt32 := 7;

   Max_Item_Copy : constant Natural := 128;
   Max_UTF8_Copy : constant Natural := 65_536;
   Max_Object_Copy : constant Natural := 128;

   type UInt32_Buffer is array (Natural range 0 .. Max_Item_Copy - 1)
     of aliased Native.Native_UInt32
   with Convention => C;

   type UTF8_Buffer is array (Natural range 0 .. Max_UTF8_Copy - 1)
     of aliased Interfaces.C.char
   with Convention => C;

   type UInt64_Buffer is array (Natural range 0 .. Max_Object_Copy - 1)
     of aliased Native.Native_UInt64
   with Convention => C;

   package UInt32_Buffer_Conversions is
     new System.Address_To_Access_Conversions (UInt32_Buffer);
   package UTF8_Buffer_Conversions is
     new System.Address_To_Access_Conversions (UTF8_Buffer);
   package UInt64_Buffer_Conversions is
     new System.Address_To_Access_Conversions (UInt64_Buffer);
   package Context_Conversions is
     new System.Address_To_Access_Conversions (Callback_Context);

   use type System.Address;
   use type Native.Native_UInt64;
   use type Native.Native_UInt32;
   use type Context_Conversions.Object_Pointer;
   use type UInt32_Buffer_Conversions.Object_Pointer;
   use type UTF8_Buffer_Conversions.Object_Pointer;
   use type UInt64_Buffer_Conversions.Object_Pointer;
   use type A11y.Results.Status_Code;
   use type Router.Routed_Reply_Kind;

   function Success return Native.Native_Status is
     (Native.Native_Status (1));

   function Failure return Native.Native_Status is
     (Native.Native_Status (0));

   function Action_Code (Action : Actions.NSAX_Action)
      return Native.Native_UInt32 is
     (case Action is
        when Actions.Press => 2,
        when Actions.Expand => 4,
        when Actions.Collapse => 5,
        when Actions.Show_Menu => 6,
        when Actions.Confirm => 15,
        when Actions.Cancel => 7,
        when Actions.Increment => 8,
        when Actions.Decrement => 9,
        when Actions.Pick => 10,
        when Actions.Raise_Item => 14,
        when Actions.Scroll_To_Visible => 13);

   function Role_Code
     (Role : A11y.MacOS_Backend.NSAccessibility_Mappings.NSAX_Role)
      return Native.Native_UInt32 is
     (Native.Native_UInt32
        (A11y.MacOS_Backend.NSAccessibility_Mappings.NSAX_Role'Pos (Role)
         + 1));

   function Context_View
     (Context : System.Address)
      return Context_Conversions.Object_Pointer
   is
   begin
      if Context = System.Null_Address then
         return null;
      end if;

      return Context_Conversions.To_Pointer (Context);
   exception
      when others =>
         return null;
   end Context_View;

   procedure Reset_Out_Parameters
     (Value_Kind  : access Native.Native_UInt32;
      Item_Count  : access Native.Native_UInt64;
      UTF8_Used   : access Native.Native_UInt64)
   is
   begin
      if Value_Kind /= null then
         Value_Kind.all := Native_Value_None;
      end if;
      if Item_Count /= null then
         Item_Count.all := 0;
      end if;
      if UTF8_Used /= null then
         UTF8_Used.all := 0;
      end if;
   end Reset_Out_Parameters;

   function Dispatch
     (Session  : Native.Native_UInt64;
      Node     : Native.Native_UInt64;
      Selector : Native.Native_UInt32;
      Operand  : Native.Native_UInt32;
      Context  : System.Address;
      Routed   : out Router.Routed_Reply)
      return Boolean
   is
      View : constant Context_Conversions.Object_Pointer :=
        Context_View (Context);
      Reply :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Reply;
   begin
      Routed := (Kind => Router.Routed_Error,
                 Status => A11y.Results.Invalid_Argument);

      if View = null
        or else View.Registry = null
        or else View.Snapshots = null
      then
         return False;
      end if;

      Reply :=
        ABI.Dispatch_Callback
          (View.Registry.all,
           Session,
           Node,
           Selector,
           Operand,
           View.Snapshots.all,
           View.Last_Report);

      View.Dispatched := True;
      View.Last_Status := Reply.Status;
      Routed := Reply.Payload;
      return Reply.Status = A11y.Results.Success;
   exception
      when others =>
         return False;
   end Dispatch;

   function Copy_Items
     (Items         : System.Address;
      Item_Capacity : Native.Native_UInt64;
      Item_Count    : access Native.Native_UInt64;
      Values        : UInt32_Buffer;
      Value_Count   : Natural)
      return Boolean
   is
      Buffer : constant UInt32_Buffer_Conversions.Object_Pointer :=
        UInt32_Buffer_Conversions.To_Pointer (Items);
   begin
      if Item_Count = null
        or else Items = System.Null_Address
        or else Buffer = null
        or else Value_Count > Values'Length
      then
         return False;
      end if;

      if Native.Native_UInt64 (Value_Count) > Item_Capacity then
         return False;
      end if;

      for Index in 0 .. Value_Count - 1 loop
         Buffer (Index) := Values (Index);
      end loop;
      Item_Count.all := Native.Native_UInt64 (Value_Count);
      return True;
   exception
      when others =>
         return False;
   end Copy_Items;

   function Copy_Items
     (Items         : System.Address;
      Item_Capacity : Native.Native_UInt64;
      Item_Count    : access Native.Native_UInt64;
      Values        : UInt32_Buffer)
      return Boolean
   is
      Count : Natural := 0;
   begin
      for Value of Values loop
         exit when Value = 0;
         Count := Count + 1;
      end loop;

      return Copy_Items
        (Items, Item_Capacity, Item_Count, Values, Count);
   end Copy_Items;

   function Encode_Signed_32
     (Value   : Long_Integer;
      Encoded : out Native.Native_UInt32)
      return Boolean
   is
      Min_Int32 : constant Long_Integer := -2_147_483_648;
      Max_Int32 : constant Long_Integer := 2_147_483_647;
   begin
      if Value < Min_Int32 or else Value > Max_Int32 then
         Encoded := 0;
         return False;
      end if;

      if Value < 0 then
         Encoded :=
           Native.Native_UInt32
             (4_294_967_296 + Long_Long_Integer (Value));
      else
         Encoded := Native.Native_UInt32 (Value);
      end if;
      return True;
   exception
      when others =>
         Encoded := 0;
         return False;
   end Encode_Signed_32;

   function Copy_UTF8
     (Text          : String;
      UTF8_Buffer   : System.Address;
      UTF8_Capacity : Native.Native_UInt64;
      UTF8_Used     : access Native.Native_UInt64)
      return Boolean
   is
      Buffer : constant UTF8_Buffer_Conversions.Object_Pointer :=
        UTF8_Buffer_Conversions.To_Pointer (UTF8_Buffer);
      Capacity : constant Natural :=
        Natural'Min (Natural (UTF8_Capacity), Max_UTF8_Copy);
   begin
      if UTF8_Used = null
        or else UTF8_Buffer = System.Null_Address
        or else Buffer = null
        or else Text'Length > Capacity
      then
         return False;
      end if;

      for Index in 0 .. Text'Length - 1 loop
         Buffer (Index) :=
           Interfaces.C.char'Val (Character'Pos (Text (Text'First + Index)));
      end loop;
      UTF8_Used.all := Native.Native_UInt64 (Text'Length);
      return True;
   exception
      when others =>
         return False;
   end Copy_UTF8;

   function Append_Relation_Attributes
     (Context : System.Address;
      Values  : in out UInt32_Buffer;
      Count   : in out Natural)
      return Boolean
   is
      View : constant Context_Conversions.Object_Pointer :=
        Context_View (Context);

      function Contains (Code : Native.Native_UInt32) return Boolean is
      begin
         if Count = 0 then
            return False;
         end if;

         for Index in 0 .. Count - 1 loop
            if Values (Index) = Code then
               return True;
            end if;
         end loop;
         return False;
      end Contains;
   begin
      if View = null or else View.Snapshots = null then
         return True;
      end if;

      for Relation in A11y.Relations.Relation_Kind loop
         declare
            Reply : constant Router.Routed_Reply :=
              Router.Dispatch
                ((Kind     => Router.Relation_Query,
                  Relation => Relation,
                  others   => <>),
                 View.Snapshots.all);
            Code : constant Native.Native_UInt32 :=
              ABI.Relation_Code (Relation);
         begin
            case Reply.Kind is
               when Router.Relation_Targets =>
                  if not Contains (Code) then
                     if Count = Values'Length then
                        return False;
                     end if;
                     Values (Count) := Code;
                     Count := Count + 1;
                  end if;
               when Router.Relation_Empty | Router.Relation_Not_Supported =>
                  null;
               when Router.Routed_Error =>
                  if Reply.Status = A11y.Results.Node_Unavailable then
                     null;
                  else
                     return False;
                  end if;
               when others =>
                  null;
            end case;
         end;
      end loop;

      return True;
   exception
      when others =>
         return False;
   end Append_Relation_Attributes;

   function Dispatch_Selector_Callback
     (Session  : Native.Native_UInt64;
      Node     : Native.Native_UInt64;
      Selector : Native.Native_UInt32;
      Operand  : Native.Native_UInt32;
      Context  : System.Address)
      return Native.Native_Status
   is
      Routed : Router.Routed_Reply;
   begin
      return
        (if Dispatch (Session, Node, Selector, Operand, Context, Routed)
         then Success
         else Failure);
   exception
      when others =>
         return Failure;
   end Dispatch_Selector_Callback;

   function Copy_Value_Callback
     (Session       : Native.Native_UInt64;
      Node          : Native.Native_UInt64;
      Selector      : Native.Native_UInt32;
      Operand       : Native.Native_UInt32;
      Value_Kind    : access Native.Native_UInt32;
      Items         : System.Address;
      Item_Capacity : Native.Native_UInt64;
      Item_Count    : access Native.Native_UInt64;
      UTF8_Buffer   : System.Address;
      UTF8_Capacity : Native.Native_UInt64;
      UTF8_Used     : access Native.Native_UInt64;
      Context       : System.Address)
      return Native.Native_Status
   is
      Routed : Router.Routed_Reply;
      Values : UInt32_Buffer := [others => 0];
      Count  : Natural := 0;
   begin
      Reset_Out_Parameters (Value_Kind, Item_Count, UTF8_Used);

      if Value_Kind = null
        or else not Dispatch
          (Session, Node, Selector, Operand, Context, Routed)
      then
         return Failure;
      end if;

      case Routed.Kind is
         when Router.Attribute_Set =>
            for Attribute in Properties.Core_Attribute loop
               if Routed.Attributes (Attribute) then
                  if Count = Values'Length then
                     return Failure;
                  end if;
                  Values (Count) := ABI.Attribute_Code (Attribute);
                  Count := Count + 1;
               end if;
            end loop;
            if not Append_Relation_Attributes (Context, Values, Count) then
               return Failure;
            end if;
            if not Copy_Items (Items, Item_Capacity, Item_Count, Values) then
               return Failure;
            end if;
            Value_Kind.all := Native_Value_Attribute_Array;
            return Success;

         when Router.Action_Set =>
            for Action in Actions.NSAX_Action loop
               if Routed.Actions (Action) then
                  if Count = Values'Length then
                     return Failure;
                  end if;
                  Values (Count) := Action_Code (Action);
                  Count := Count + 1;
               end if;
            end loop;
            if not Copy_Items (Items, Item_Capacity, Item_Count, Values) then
               return Failure;
            end if;
            Value_Kind.all := Native_Value_Action_Array;
            return Success;

         when Router.Attribute_String =>
            if not Copy_UTF8
              (Ada.Strings.Unbounded.To_String (Routed.Text),
               UTF8_Buffer,
               UTF8_Capacity,
               UTF8_Used)
            then
               return Failure;
            end if;
            Value_Kind.all := Native_Value_UTF8_String;
            return Success;

         when Router.Attribute_Empty_String =>
            if UTF8_Used = null then
               return Failure;
            end if;
            UTF8_Used.all := 0;
            Value_Kind.all := Native_Value_UTF8_String;
            return Success;

         when Router.Attribute_Boolean =>
            if UTF8_Used = null then
               return Failure;
            end if;
            UTF8_Used.all := (if Routed.Boolean_Item then 1 else 0);
            Value_Kind.all := Native_Value_Boolean;
            return Success;

         when Router.Attribute_Integer =>
            if UTF8_Used = null or else Routed.Integer_Item < 0 then
               return Failure;
            end if;
            UTF8_Used.all := Native.Native_UInt64 (Routed.Integer_Item);
            Value_Kind.all := Native_Value_Integer;
            return Success;

         when Router.Attribute_Role =>
            if UTF8_Used = null then
               return Failure;
            end if;
            UTF8_Used.all := Native.Native_UInt64 (Role_Code (Routed.Role));
            Value_Kind.all := Native_Value_Role;
            return Success;

         when Router.Attribute_Rectangle =>
            if not Encode_Signed_32
              (Long_Integer (Routed.Bounds.Origin.X), Values (0))
              or else not Encode_Signed_32
                (Long_Integer (Routed.Bounds.Origin.Y), Values (1))
              or else not Encode_Signed_32
                (Long_Integer (Routed.Bounds.Extent.Width), Values (2))
              or else not Encode_Signed_32
                (Long_Integer (Routed.Bounds.Extent.Height), Values (3))
              or else not Copy_Items
                (Items, Item_Capacity, Item_Count, Values, 4)
            then
               return Failure;
            end if;
            Value_Kind.all := Native_Value_Rectangle;
            return Success;

         when others =>
            return Failure;
      end case;
   exception
      when others =>
         Reset_Out_Parameters (Value_Kind, Item_Count, UTF8_Used);
         return Failure;
   end Copy_Value_Callback;

   function Copy_Object_Callback
     (Session       : Native.Native_UInt64;
      Node          : Native.Native_UInt64;
      Selector      : Native.Native_UInt32;
      Operand       : Native.Native_UInt32;
      Point_X       : Native.Native_Int64;
      Point_Y       : Native.Native_Int64;
      Items         : System.Address;
      Item_Capacity : Native.Native_UInt64;
      Item_Count    : access Native.Native_UInt64;
      Context       : System.Address)
      return Native.Native_Status
   is
      View : constant Context_Conversions.Object_Pointer :=
        Context_View (Context);
      Buffer : constant UInt64_Buffer_Conversions.Object_Pointer :=
        UInt64_Buffer_Conversions.To_Pointer (Items);
      Routed : Router.Routed_Reply;
      Backend_Session : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Result : A11y.Results.Result;
      Count : Natural := 0;
      Is_Hit_Test : constant Boolean :=
        Selector =
          ABI.Selector_Code (ABI.Accessibility_Hit_Test);
      Is_Focused_Element : constant Boolean :=
        Selector =
          ABI.Selector_Code (ABI.Accessibility_Focused_UI_Element);

      function Add_Node
        (Target : A11y.Node_Ids.Node_Id)
         return Boolean
      is
         Element : A11y.MacOS_Backend.NSAccessibility_Element_Registry
           .Element_Id := A11y.MacOS_Backend.NSAccessibility_Element_Registry
             .No_Element;
      begin
         if not A11y.Node_Ids.Is_Valid (Target)
           or else View = null
           or else View.Registry = null
           or else View.Snapshots = null
           or else Count >= Max_Object_Copy
           or else Native.Native_UInt64 (Count + 1) > Item_Capacity
         then
            return False;
         end if;

         A11y.MacOS_Backend.NSAccessibility_Element_Registry.Ensure_Element
           (View.Registry.all,
            Backend_Session,
            View.Snapshots.Hierarchy.Root,
            Target,
            Element,
            Result);
         if A11y.Results.Failed (Result) then
            return False;
         end if;

         A11y.MacOS_Backend.NSAccessibility_Element_Registry.Bind_Main_Thread
           (View.Registry.all, Backend_Session, Element, Result);
         if A11y.Results.Failed (Result) then
            return False;
         end if;

         Buffer (Count) :=
           Native.Native_UInt64
             (A11y.MacOS_Backend.NSAccessibility_Element_Registry
                .To_Natural (Element));
         Count := Count + 1;
         return True;
      exception
         when others =>
            return False;
      end Add_Node;

      function Hit_Test_Point return A11y.Geometry.Point is
        ((X => A11y.Geometry.Coordinate (Point_X),
          Y => A11y.Geometry.Coordinate (Point_Y)));

      function Add_Hit_Test_Node return Boolean is
         Reply : constant
           A11y.MacOS_Backend.NSAccessibility_Hierarchy.Node_Reply :=
             A11y.MacOS_Backend.NSAccessibility_Hierarchy.Hit_Test
               (View.Snapshots.Hierarchy,
                Hit_Test_Point,
                View.Snapshots.Limits);
      begin
         if Reply.Found then
            return Add_Node (Reply.Node);
         elsif Reply.Status = A11y.Results.Success then
            return True;
         end if;

         return False;
      exception
         when others =>
            return False;
      end Add_Hit_Test_Node;

      function Add_Focused_Node return Boolean is
         Reply : constant
           A11y.MacOS_Backend.NSAccessibility_Hierarchy.Node_Reply :=
             A11y.MacOS_Backend.NSAccessibility_Hierarchy.Focused
               (View.Snapshots.Hierarchy,
                View.Snapshots.Limits);
      begin
         if Reply.Found then
            return Add_Node (Reply.Node);
         elsif Reply.Status = A11y.Results.Success then
            return True;
         end if;

         return False;
      exception
         when others =>
            return False;
      end Add_Focused_Node;

   begin
      if Item_Count /= null then
         Item_Count.all := 0;
      end if;

      if Item_Count = null
        or else Items = System.Null_Address
        or else Buffer = null
        or else View = null
        or else View.Registry = null
        or else View.Snapshots = null
        or else Item_Capacity = 0
        or else Session = 0
      then
         return Failure;
      end if;

      Backend_Session := A11y.Native_Identity.From_Natural
        (Natural (Session));
      if not A11y.Native_Identity.Is_Valid (Backend_Session) then
         return Failure;
      end if;

      if not Dispatch (Session, Node, Selector, Operand, Context, Routed) then
         return Failure;
      end if;

      case Routed.Kind is
         when Router.Hierarchy_Node =>
            if not Add_Node (Routed.Node) then
               return Failure;
            end if;
         when Router.Hierarchy_Children =>
            declare
               Children : constant A11y.Trees.Child_Vectors.Vector :=
                 Routed.Children;
            begin
               for Child of Children loop
                  if not Add_Node (Child) then
                     return Failure;
                  end if;
               end loop;
            end;
         when Router.Hierarchy_Empty =>
            null;
         when Router.Element_Id =>
            if Is_Hit_Test then
               if not Add_Hit_Test_Node then
                  return Failure;
               end if;
            elsif Is_Focused_Element then
               if not Add_Focused_Node then
                  return Failure;
               end if;
            elsif not Add_Node (View.Snapshots.Hierarchy.Node) then
               return Failure;
            end if;
         when Router.Relation_Targets =>
            declare
               Targets : constant A11y.Relations.Target_Vectors.Vector :=
                 Routed.Relation_Target_Nodes;
            begin
               for Target of Targets loop
                  if not Add_Node (Target) then
                     return Failure;
                  end if;
               end loop;
            end;
         when Router.Relation_Empty =>
            null;
         when others =>
            return Failure;
      end case;

      Item_Count.all := Native.Native_UInt64 (Count);
      return Success;
   exception
      when others =>
         if Item_Count /= null then
            Item_Count.all := 0;
         end if;
         return Failure;
   end Copy_Object_Callback;

end A11y.MacOS_Backend.NSAccessibility_Native_Callbacks;
