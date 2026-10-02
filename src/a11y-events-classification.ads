package A11y.Events.Classification is
   pragma SPARK_Mode (On);

   function Is_Coalescible
     (Kind : Event_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Coalescible'Result =
        (Kind in Bounds_Changed | Value_Changed);

   function Is_Text_Event
     (Kind : Event_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Text_Event'Result =
        (Kind in Text_Inserted | Text_Removed | Text_Replaced | Caret_Moved
         | Text_Selection_Changed | Text_Attributes_Changed);

   function Is_Property_Event
     (Kind : Event_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Property_Event'Result =
        (Kind in Property_Changed | Bounds_Changed);

   function Is_State_Event
     (Kind : Event_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_State_Event'Result =
        (Kind in State_Changed | Focus_Changed
         | Active_Descendant_Changed);

   function Is_Value_Event
     (Kind : Event_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Value_Event'Result =
        (Kind in Value_Changed | Range_Changed);

   function Is_Selection_Event
     (Kind : Event_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Selection_Event'Result =
        (Kind in Selection_Changed | Current_Item_Changed
         | Text_Selection_Changed);

   function Is_Focus_Event
     (Kind : Event_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Focus_Event'Result =
        (Kind in Focus_Changed | Active_Descendant_Changed
         | Current_Item_Changed);

   function Is_Lifecycle_Event
     (Kind : Event_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Lifecycle_Event'Result =
        (Kind in Node_Created | Node_Destroyed | Node_Attached
         | Node_Detached);

   function Is_Tree_Event
     (Kind : Event_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Tree_Event'Result =
        (Kind in Node_Created | Node_Destroyed | Node_Attached
         | Node_Detached | Child_Added | Child_Removed | Children_Reordered
         | Subtree_Rebuilt);

   function Is_Table_Event
     (Kind : Event_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Table_Event'Result =
        (Kind in Row_Inserted | Row_Removed | Column_Inserted
         | Column_Removed | Cell_Changed);

   function Is_Document_Event
     (Kind : Event_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Document_Event'Result =
        (Kind in Document_Loaded | Document_Closed);

   function Is_Relation_Event
     (Kind : Event_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Relation_Event'Result =
        (Kind in Active_Descendant_Changed | Relation_Added
         | Relation_Removed | Relation_Targets_Changed);

   function Is_Window_Event
     (Kind : Event_Kind)
      return Boolean
   with
      Global => null,
      Post => Is_Window_Event'Result =
        (Kind in Window_Opened | Window_Closed | Window_Activated
         | Window_Deactivated);

   function Must_Preserve_Individual_Order
     (Kind : Event_Kind)
      return Boolean
   with
      Global => null,
      Post => Must_Preserve_Individual_Order'Result =
        (Is_Text_Event (Kind) or else Is_Lifecycle_Event (Kind)
         or else Is_Relation_Event (Kind));

end A11y.Events.Classification;
