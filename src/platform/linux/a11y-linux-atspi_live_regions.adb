with A11y.Linux.ATSPi_Objects;
with A11y.Linux.DBus_Codec;

package body A11y.Linux.ATSPi_Live_Regions is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;

   function Error (Status : A11y.Results.Status_Code) return Live_Reply is
     (Kind       => Error_Reply,
      Status     => Status,
      Error_Name => To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Error_Name (Status)));

   function String_Result
     (Text   : String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Live_Reply
   is
      Result : A11y.Results.Result;
      Encoded : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      Encoded := A11y.Linux.DBus_Codec.Make_String (Text, Limits, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Kind   => String_Reply,
         Status => A11y.Results.Success,
         Text   => Encoded.Text_Item);
   end String_Result;

   function Boolean_Result (Item : Boolean) return Live_Reply is
     (Kind         => Boolean_Reply,
      Status       => A11y.Results.Success,
      Boolean_Item => Item);

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Snapshot : Live_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Live_Reply
   is
      Result : A11y.Results.Result;
      Node : A11y.Node_Ids.Node_Id;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      Node := A11y.Linux.ATSPi_Objects.Node_From_Object_Path
        (Path, Session, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      elsif Node /= Snapshot.Id or else Snapshot.Defunct then
         return Error (A11y.Results.Node_Unavailable);
      end if;

      Result := A11y.Live_Regions.Validate (Snapshot.Metadata);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      if Method = "GetLiveSetting" then
         return String_Result
           (A11y.Live_Regions.Stable_Name (Snapshot.Metadata.Setting),
            Limits);
      elsif Method = "GetLiveRelevant" then
         return String_Result
           (A11y.Live_Regions.Relevant_Names (Snapshot.Metadata.Relevant),
            Limits);
      elsif Method = "IsLiveAtomic" then
         return Boolean_Result (Snapshot.Metadata.Atomic);
      elsif Method = "IsLiveAssertive" then
         return Boolean_Result
           (A11y.Live_Regions.Metadata
              (Snapshot.Metadata.Setting).Interruptive);
      elsif Method = "IsLiveExternallyAnnounced" then
         return Boolean_Result
           (A11y.Live_Regions.Metadata
              (Snapshot.Metadata.Setting).Externally_Announced);
      else
         return Error (A11y.Results.Unsupported_Capability);
      end if;
   exception
      when others =>
         return Error (A11y.Results.Internal_Error);
   end Handle_Method;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Snapshot : Live_Snapshot)
      return Live_Reply is
     (Handle_Method
        (Session, Path, Method, Snapshot,
         A11y.Resource_Limits.Default_Config));

end A11y.Linux.ATSPi_Live_Regions;
