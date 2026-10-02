package body A11y.Resource_Limits is
   pragma SPARK_Mode (On);

   Event_Queue_Size_Name             : aliased constant String :=
     "event-queue-size";
   Native_Object_Cache_Size_Name     : aliased constant String :=
     "native-object-cache-size";
   Tombstone_Retention_Name          : aliased constant String :=
     "tombstone-retention";
   Relation_Targets_Returned_Name    : aliased constant String :=
     "relation-targets-returned";
   Selection_Items_Materialized_Name : aliased constant String :=
     "selection-items-materialized";
   Text_Returned_Name                : aliased constant String :=
     "text-returned";
   Traversal_Depth_Name              : aliased constant String :=
     "traversal-depth";
   Native_Array_Size_Name            : aliased constant String :=
     "native-array-size";
   Native_String_Size_Name           : aliased constant String :=
     "native-string-size";
   Outstanding_Callbacks_Name        : aliased constant String :=
     "outstanding-callbacks";
   Callback_Duration_MS_Name         : aliased constant String :=
     "callback-duration-ms";
   Shutdown_Duration_MS_Name         : aliased constant String :=
     "shutdown-duration-ms";
   Diagnostic_Trace_Size_Name        : aliased constant String :=
     "diagnostic-trace-size";
   Event_Coalescing_Window_Name      : aliased constant String :=
     "event-coalescing-window";
   Virtual_Node_Realization_Name     : aliased constant String :=
     "virtual-node-realization";

   Defaults : constant Limit_Array :=
     [Event_Queue_Size              => 1_024,
      Native_Object_Cache_Size      => 65_536,
      Tombstone_Retention           => 65_536,
      Relation_Targets_Returned     => 4_096,
      Selection_Items_Materialized  => 65_536,
      Text_Returned                 => 16_384,
      Traversal_Depth               => 1_024,
      Native_Array_Size             => 4_096,
      Native_String_Size            => 65_536,
      Outstanding_Callbacks         => 1_024,
      Callback_Duration_MS          => 500,
      Shutdown_Duration_MS          => 5_000,
      Diagnostic_Trace_Size         => 1_024,
      Event_Coalescing_Window       => 1,
      Virtual_Node_Realization      => 4_096];

   function Metadata (Kind : Limit_Kind) return Limit_Metadata is
     (case Kind is
        when Event_Queue_Size =>
          (Stable_Name => Event_Queue_Size_Name'Access,
           Default_Value => Defaults (Event_Queue_Size)),
        when Native_Object_Cache_Size =>
          (Stable_Name => Native_Object_Cache_Size_Name'Access,
           Default_Value => Defaults (Native_Object_Cache_Size)),
        when Tombstone_Retention =>
          (Stable_Name => Tombstone_Retention_Name'Access,
           Default_Value => Defaults (Tombstone_Retention)),
        when Relation_Targets_Returned =>
          (Stable_Name => Relation_Targets_Returned_Name'Access,
           Default_Value => Defaults (Relation_Targets_Returned)),
        when Selection_Items_Materialized =>
          (Stable_Name => Selection_Items_Materialized_Name'Access,
           Default_Value => Defaults (Selection_Items_Materialized)),
        when Text_Returned =>
          (Stable_Name => Text_Returned_Name'Access,
           Default_Value => Defaults (Text_Returned)),
        when Traversal_Depth =>
          (Stable_Name => Traversal_Depth_Name'Access,
           Default_Value => Defaults (Traversal_Depth)),
        when Native_Array_Size =>
          (Stable_Name => Native_Array_Size_Name'Access,
           Default_Value => Defaults (Native_Array_Size)),
        when Native_String_Size =>
          (Stable_Name => Native_String_Size_Name'Access,
           Default_Value => Defaults (Native_String_Size)),
        when Outstanding_Callbacks =>
          (Stable_Name => Outstanding_Callbacks_Name'Access,
           Default_Value => Defaults (Outstanding_Callbacks)),
        when Callback_Duration_MS =>
          (Stable_Name => Callback_Duration_MS_Name'Access,
           Default_Value => Defaults (Callback_Duration_MS)),
        when Shutdown_Duration_MS =>
          (Stable_Name => Shutdown_Duration_MS_Name'Access,
           Default_Value => Defaults (Shutdown_Duration_MS)),
        when Diagnostic_Trace_Size =>
          (Stable_Name => Diagnostic_Trace_Size_Name'Access,
           Default_Value => Defaults (Diagnostic_Trace_Size)),
        when Event_Coalescing_Window =>
          (Stable_Name => Event_Coalescing_Window_Name'Access,
           Default_Value => Defaults (Event_Coalescing_Window)),
        when Virtual_Node_Realization =>
          (Stable_Name => Virtual_Node_Realization_Name'Access,
           Default_Value => Defaults (Virtual_Node_Realization)));

   function Stable_Name (Kind : Limit_Kind) return String is
     (Metadata (Kind).Stable_Name.all);

   function Default_Config return Resource_Limit_Config is
     (Limits => Defaults);

   function Value
     (Config : Resource_Limit_Config;
      Kind   : Limit_Kind)
      return Limit_Value is
     (Config.Limits (Kind));

   procedure Set_Limit
     (Config : in out Resource_Limit_Config;
      Kind   : Limit_Kind;
      Amount : Limit_Value;
      Result : out A11y.Results.Result) is
   begin
      if Amount = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      Config.Limits (Kind) := Amount;
      Result := A11y.Results.Ok;
   end Set_Limit;

   function Validate
     (Config : Resource_Limit_Config)
      return A11y.Results.Result is
   begin
      for Kind in Limit_Kind loop
         pragma Loop_Invariant
           (for all Prior in Limit_Kind'First .. Kind =>
              (if Prior /= Kind then Config.Limits (Prior) /= 0));
         if Config.Limits (Kind) = 0 then
            return (Status => A11y.Results.Invalid_Argument);
         end if;
      end loop;

      return A11y.Results.Ok;
   end Validate;

   function Exceeded
     (Config : Resource_Limit_Config;
      Kind   : Limit_Kind;
      Amount : Natural)
      return Boolean is
     (Limit_Value (Amount) > Config.Limits (Kind));

end A11y.Resource_Limits;
