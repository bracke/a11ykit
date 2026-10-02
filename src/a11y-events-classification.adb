package body A11y.Events.Classification is
   pragma SPARK_Mode (On);

   function Is_Coalescible
     (Kind : Event_Kind)
      return Boolean is
     (A11y.Events.Is_Coalescible (Kind));

   function Is_Text_Event
     (Kind : Event_Kind)
      return Boolean is
     (A11y.Events.Is_Text_Event (Kind));

   function Is_Property_Event
     (Kind : Event_Kind)
      return Boolean is
     (A11y.Events.Is_Property_Event (Kind));

   function Is_State_Event
     (Kind : Event_Kind)
      return Boolean is
     (A11y.Events.Is_State_Event (Kind));

   function Is_Value_Event
     (Kind : Event_Kind)
      return Boolean is
     (A11y.Events.Is_Value_Event (Kind));

   function Is_Selection_Event
     (Kind : Event_Kind)
      return Boolean is
     (A11y.Events.Is_Selection_Event (Kind));

   function Is_Focus_Event
     (Kind : Event_Kind)
      return Boolean is
     (A11y.Events.Is_Focus_Event (Kind));

   function Is_Lifecycle_Event
     (Kind : Event_Kind)
      return Boolean is
     (A11y.Events.Is_Lifecycle_Event (Kind));

   function Is_Tree_Event
     (Kind : Event_Kind)
      return Boolean is
     (A11y.Events.Is_Tree_Event (Kind));

   function Is_Table_Event
     (Kind : Event_Kind)
      return Boolean is
     (A11y.Events.Is_Table_Event (Kind));

   function Is_Document_Event
     (Kind : Event_Kind)
      return Boolean is
     (A11y.Events.Is_Document_Event (Kind));

   function Is_Relation_Event
     (Kind : Event_Kind)
      return Boolean is
     (A11y.Events.Is_Relation_Event (Kind));

   function Is_Window_Event
     (Kind : Event_Kind)
      return Boolean is
     (A11y.Events.Is_Window_Event (Kind));

   function Must_Preserve_Individual_Order
     (Kind : Event_Kind)
      return Boolean is
     (A11y.Events.Must_Preserve_Individual_Order (Kind));

end A11y.Events.Classification;
