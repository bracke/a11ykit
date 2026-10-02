package body A11y.Windows_Backend.UIA_Live_Regions is
   use Ada.Strings.Unbounded;

   function Error (Status : A11y.Results.Status_Code) return Live_Reply is
     (Kind => Error_Reply, Status => Status);

   function String_Result
     (Text   : String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Live_Reply
   is
   begin
      if A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_String_Size, Text'Length)
      then
         return Error (A11y.Results.Resource_Limit);
      end if;

      return
        (Kind   => String_Reply,
         Status => A11y.Results.Success,
         Text   => To_Unbounded_String (Text));
   end String_Result;

   function Boolean_Result (Item : Boolean) return Live_Reply is
     (Kind         => Boolean_Reply,
      Status       => A11y.Results.Success,
      Boolean_Item => Item);

   function Query_Live_Region
     (Snapshot : Live_Snapshot;
      Query    : Live_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Live_Reply
   is
      Result : A11y.Results.Result;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif Snapshot.Defunct then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      Result := A11y.Live_Regions.Validate (Snapshot.Metadata);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      case Query is
         when Setting_Name =>
            return String_Result
              (A11y.Live_Regions.Stable_Name (Snapshot.Metadata.Setting),
               Limits);
         when Relevant_Names =>
            return String_Result
              (A11y.Live_Regions.Relevant_Names
                 (Snapshot.Metadata.Relevant),
               Limits);
         when Is_Atomic =>
            return Boolean_Result (Snapshot.Metadata.Atomic);
         when Is_Assertive =>
            return Boolean_Result
              (A11y.Live_Regions.Metadata
                 (Snapshot.Metadata.Setting).Interruptive);
         when Is_Externally_Announced =>
            return Boolean_Result
              (A11y.Live_Regions.Metadata
                 (Snapshot.Metadata.Setting).Externally_Announced);
      end case;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Query_Live_Region;

   function Query_Live_Region
     (Snapshot : Live_Snapshot;
      Query    : Live_Query)
      return Live_Reply is
     (Query_Live_Region
        (Snapshot, Query, A11y.Resource_Limits.Default_Config));

end A11y.Windows_Backend.UIA_Live_Regions;
