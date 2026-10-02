with A11y.Results;

package A11y.Resource_Limits is
   pragma SPARK_Mode (On);

   type Limit_Kind is
     (Event_Queue_Size,
      Native_Object_Cache_Size,
      Tombstone_Retention,
      Relation_Targets_Returned,
      Selection_Items_Materialized,
      Text_Returned,
      Traversal_Depth,
      Native_Array_Size,
      Native_String_Size,
      Outstanding_Callbacks,
      Callback_Duration_MS,
      Shutdown_Duration_MS,
      Diagnostic_Trace_Size,
      Event_Coalescing_Window,
      Virtual_Node_Realization);

   type Limit_Value is new Natural;

   type Limit_Array is array (Limit_Kind) of Limit_Value;

   type Stable_Name_Access is access constant String;

   type Limit_Metadata is record
      Stable_Name   : Stable_Name_Access;
      Default_Value : Limit_Value := 1;
   end record;

   type Resource_Limit_Config is record
      Limits : Limit_Array;
   end record;

   function Metadata (Kind : Limit_Kind) return Limit_Metadata
   with
      Global => null,
      Post =>
        (case Kind is
           when Event_Queue_Size =>
             Metadata'Result.Default_Value = 1_024,
           when Native_Object_Cache_Size =>
             Metadata'Result.Default_Value = 65_536,
           when Tombstone_Retention =>
             Metadata'Result.Default_Value = 65_536,
           when Relation_Targets_Returned =>
             Metadata'Result.Default_Value = 4_096,
           when Selection_Items_Materialized =>
             Metadata'Result.Default_Value = 65_536,
           when Text_Returned =>
             Metadata'Result.Default_Value = 16_384,
           when Traversal_Depth =>
             Metadata'Result.Default_Value = 1_024,
           when Native_Array_Size =>
             Metadata'Result.Default_Value = 4_096,
           when Native_String_Size =>
             Metadata'Result.Default_Value = 65_536,
           when Outstanding_Callbacks =>
             Metadata'Result.Default_Value = 1_024,
           when Callback_Duration_MS =>
             Metadata'Result.Default_Value = 500,
           when Shutdown_Duration_MS =>
             Metadata'Result.Default_Value = 5_000,
           when Diagnostic_Trace_Size =>
             Metadata'Result.Default_Value = 1_024,
           when Event_Coalescing_Window =>
             Metadata'Result.Default_Value = 1,
           when Virtual_Node_Realization =>
             Metadata'Result.Default_Value = 4_096);

   function Stable_Name (Kind : Limit_Kind) return String;

   function Default_Config return Resource_Limit_Config
     with
       Global => null,
       Post =>
         (for all Kind in Limit_Kind =>
            Default_Config'Result.Limits (Kind) = Metadata (Kind).Default_Value);

   function Value
     (Config : Resource_Limit_Config;
      Kind   : Limit_Kind)
      return Limit_Value
     with
       Global => null,
       Post => Value'Result = Config.Limits (Kind);

   procedure Set_Limit
     (Config : in out Resource_Limit_Config;
      Kind   : Limit_Kind;
      Amount : Limit_Value;
     Result : out A11y.Results.Result)
     with
       Global => null,
       Post =>
         (if Amount = 0 then
            A11y.Results.Failed (Result)
            and then Config.Limits (Kind) = Config'Old.Limits (Kind)
          else
            A11y.Results.Succeeded (Result)
            and then Config.Limits (Kind) = Amount);

   function Validate
     (Config : Resource_Limit_Config)
      return A11y.Results.Result
     with
       Global => null,
       Post =>
         A11y.Results.Succeeded (Validate'Result) =
           (for all Kind in Limit_Kind => Config.Limits (Kind) /= 0);

   function Exceeded
     (Config : Resource_Limit_Config;
      Kind   : Limit_Kind;
      Amount : Natural)
      return Boolean
     with
       Global => null,
       Post => Exceeded'Result = (Limit_Value (Amount) > Config.Limits (Kind));

end A11y.Resource_Limits;
