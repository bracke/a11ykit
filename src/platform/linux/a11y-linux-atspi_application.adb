with A11y.Linux.ATSPi_Objects;
with A11y.Linux.DBus_Codec;

package body A11y.Linux.ATSPi_Application is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;

   function Error (Status : A11y.Results.Status_Code) return Application_Reply is
     (Kind       => Error_Reply,
      Status     => Status,
      Error_Name => To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Error_Name (Status)));

   function String_Result
     (Text   : Unbounded_String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Application_Reply
   is
      Result : A11y.Results.Result;
      Encoded : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      Encoded := A11y.Linux.DBus_Codec.Make_String
        (To_String (Text), Limits, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Kind   => String_Reply,
         Status => A11y.Results.Success,
         Text   => Encoded.Text_Item);
   end String_Result;

   function UInt32_Result (Value : Natural) return Application_Reply is
      Result : A11y.Results.Result;
      Encoded : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      Encoded := A11y.Linux.DBus_Codec.Make_UInt32 (Value, Result);
      if A11y.Results.Failed (Result) then
         return Error (Result.Status);
      end if;

      return
        (Kind   => UInt32_Reply,
         Status => A11y.Results.Success,
         UInt32 => Encoded.UInt32_Item);
   end UInt32_Result;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Snapshot : Application_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Application_Reply
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

      if Method = "GetApplicationId" or else Method = "GetID" then
         return UInt32_Result (Snapshot.Application_Id);
      elsif Method = "GetToolkitName" then
         return String_Result (Snapshot.Toolkit_Name, Limits);
      elsif Method = "GetVersion" then
         return String_Result (Snapshot.Version, Limits);
      elsif Method = "GetLocale" then
         return String_Result (Snapshot.Locale, Limits);
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
      Snapshot : Application_Snapshot)
      return Application_Reply is
     (Handle_Method
        (Session, Path, Method, Snapshot, A11y.Resource_Limits.Default_Config));

end A11y.Linux.ATSPi_Application;
