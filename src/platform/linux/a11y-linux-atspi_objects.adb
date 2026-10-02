package body A11y.Linux.ATSPi_Objects is
   use Ada.Strings.Unbounded;

   Linux_Path_Prefix : constant String := "/org/a11y/ada/session/";
   Linux_Path_Node_Sep : constant String := "/node/";

   function Trimmed_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Trimmed_Image;

   function Interface_Name (Item : ATSPI_Interface) return String is
     (case Item is
        when Accessible => "org.a11y.atspi.Accessible",
        when Application => "org.a11y.atspi.Application",
        when Component => "org.a11y.atspi.Component",
        when Action => "org.a11y.atspi.Action",
        when Selection => "org.a11y.atspi.Selection",
        when Value => "org.a11y.atspi.Value",
        when Text => "org.a11y.atspi.Text",
        when Editable_Text => "org.a11y.atspi.EditableText",
        when Table => "org.a11y.atspi.Table",
        when Table_Cell => "org.a11y.atspi.TableCell",
        when Document => "org.a11y.atspi.Document",
        when Image => "org.a11y.atspi.Image",
        when Live_Region => "org.a11y.atspi.LiveRegion",
        when Surface => "org.a11y.atspi.Surface");

   function Error_Name (Status : A11y.Results.Status_Code) return String is
     (case Status is
        when A11y.Results.Success | A11y.Results.Accepted_Asynchronous =>
           "org.a11y.atspi.Success",
        when A11y.Results.Node_Unavailable =>
           "org.a11y.atspi.Error.NoSuchObject",
        when A11y.Results.Unsupported_Property |
             A11y.Results.Unsupported_Capability |
             A11y.Results.Unsupported_Action =>
           "org.a11y.atspi.Error.NotSupported",
        when A11y.Results.Invalid_Argument | A11y.Results.Invalid_Range =>
           "org.freedesktop.DBus.Error.InvalidArgs",
        when A11y.Results.Invalid_State =>
           "org.a11y.atspi.Error.InvalidState",
        when A11y.Results.Read_Only =>
           "org.a11y.atspi.Error.ReadOnly",
        when A11y.Results.Disabled =>
           "org.a11y.atspi.Error.Disabled",
        when A11y.Results.Busy =>
           "org.a11y.atspi.Error.Busy",
        when A11y.Results.Timed_Out =>
           "org.a11y.atspi.Error.Timeout",
        when A11y.Results.Cancelled =>
           "org.a11y.atspi.Error.Cancelled",
        when A11y.Results.Shutting_Down =>
           "org.a11y.atspi.Error.ShuttingDown",
        when A11y.Results.Permission_Denied =>
           "org.freedesktop.DBus.Error.AccessDenied",
        when A11y.Results.Resource_Limit | A11y.Results.Out_Of_Resources =>
           "org.a11y.atspi.Error.ResourceLimit",
        when A11y.Results.Backend_Unavailable |
             A11y.Results.Accessibility_Service_Unavailable =>
           "org.a11y.atspi.Error.BackendUnavailable",
        when A11y.Results.Protocol_Failure =>
           "org.a11y.atspi.Error.ProtocolFailure",
        when A11y.Results.Native_Failure =>
           "org.a11y.atspi.Error.NativeFailure",
        when A11y.Results.Internal_Error =>
           "org.a11y.atspi.Error.Internal");

   function Is_Known_Error_Name (Name : String) return Boolean is
     (Name = "org.a11y.atspi.Success"
      or else Name = "org.a11y.atspi.Error.NoSuchObject"
      or else Name = "org.a11y.atspi.Error.NotSupported"
      or else Name = "org.freedesktop.DBus.Error.InvalidArgs"
      or else Name = "org.a11y.atspi.Error.InvalidState"
      or else Name = "org.a11y.atspi.Error.ReadOnly"
      or else Name = "org.a11y.atspi.Error.Disabled"
      or else Name = "org.a11y.atspi.Error.Busy"
      or else Name = "org.a11y.atspi.Error.Timeout"
      or else Name = "org.a11y.atspi.Error.Cancelled"
      or else Name = "org.a11y.atspi.Error.ShuttingDown"
      or else Name = "org.freedesktop.DBus.Error.AccessDenied"
      or else Name = "org.a11y.atspi.Error.ResourceLimit"
      or else Name = "org.a11y.atspi.Error.BackendUnavailable"
      or else Name = "org.a11y.atspi.Error.ProtocolFailure"
      or else Name = "org.a11y.atspi.Error.NativeFailure"
      or else Name = "org.a11y.atspi.Error.Internal");

   function Status_For_Error_Name (Name : String)
      return A11y.Results.Status_Code
   is
   begin
      if Name = "org.a11y.atspi.Success" then
         return A11y.Results.Success;
      elsif Name = "org.a11y.atspi.Error.NoSuchObject" then
         return A11y.Results.Node_Unavailable;
      elsif Name = "org.a11y.atspi.Error.NotSupported" then
         return A11y.Results.Unsupported_Capability;
      elsif Name = "org.freedesktop.DBus.Error.InvalidArgs" then
         return A11y.Results.Invalid_Argument;
      elsif Name = "org.a11y.atspi.Error.InvalidState" then
         return A11y.Results.Invalid_State;
      elsif Name = "org.a11y.atspi.Error.ReadOnly" then
         return A11y.Results.Read_Only;
      elsif Name = "org.a11y.atspi.Error.Disabled" then
         return A11y.Results.Disabled;
      elsif Name = "org.a11y.atspi.Error.Busy" then
         return A11y.Results.Busy;
      elsif Name = "org.a11y.atspi.Error.Timeout" then
         return A11y.Results.Timed_Out;
      elsif Name = "org.a11y.atspi.Error.Cancelled" then
         return A11y.Results.Cancelled;
      elsif Name = "org.a11y.atspi.Error.ShuttingDown" then
         return A11y.Results.Shutting_Down;
      elsif Name = "org.freedesktop.DBus.Error.AccessDenied" then
         return A11y.Results.Permission_Denied;
      elsif Name = "org.a11y.atspi.Error.ResourceLimit" then
         return A11y.Results.Resource_Limit;
      elsif Name = "org.a11y.atspi.Error.BackendUnavailable" then
         return A11y.Results.Backend_Unavailable;
      elsif Name = "org.a11y.atspi.Error.ProtocolFailure" then
         return A11y.Results.Protocol_Failure;
      elsif Name = "org.a11y.atspi.Error.NativeFailure" then
         return A11y.Results.Native_Failure;
      elsif Name = "org.a11y.atspi.Error.Internal" then
         return A11y.Results.Internal_Error;
      else
         return A11y.Results.Protocol_Failure;
      end if;
   end Status_For_Error_Name;

   function Diagnostic_For_Error_Name
     (Name   : String;
      Result : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic
   is
   begin
      return Diagnostic_For_Error_Name
        (Name, A11y.Resource_Limits.Default_Config, Result);
   end Diagnostic_For_Error_Name;

   function Diagnostic_For_Error_Name
     (Name   : String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic
   is
      Item : A11y.Diagnostics.Diagnostic;
      Semantic_Status : constant A11y.Results.Status_Code :=
        Status_For_Error_Name (Name);
   begin
      if Name'Length = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Item;
      end if;

      A11y.Diagnostics.Create_For_Status
        (Identifier => "linux.atspi.error_name",
         Status     => Semantic_Status,
         Item       => Item,
         Result     => Result,
         Feature    => "linux.atspi.error_name_diagnostic",
         Redacted   => True);
      if A11y.Results.Failed (Result) then
         return Item;
      end if;

      A11y.Diagnostics.Add_Field
        (Item, "error_name", Name, Limits, Result, Redacted => False);
      if A11y.Results.Failed (Result) then
         return Item;
      end if;

      A11y.Diagnostics.Add_Field
        (Item,
         "known",
         (if Is_Known_Error_Name (Name) then "true" else "false"),
         Limits,
         Result,
         Redacted => False);
      if A11y.Results.Failed (Result) then
         return Item;
      end if;

      A11y.Diagnostics.Add_Field
        (Item,
         "structured_status",
         A11y.Results.Stable_Name (Semantic_Status),
         Limits,
         Result,
         Redacted => False);
      if A11y.Results.Failed (Result) then
         return Item;
      end if;

      Result := A11y.Results.Ok;
      return Item;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Item;
   end Diagnostic_For_Error_Name;

   function Object_Path
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Node    : A11y.Node_Ids.Node_Id;
      Result  : out A11y.Results.Result)
      return Ada.Strings.Unbounded.Unbounded_String
   is
   begin
      if not A11y.Native_Identity.Is_Valid (Session)
        or else not A11y.Node_Ids.Is_Valid (Node)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return Null_Unbounded_String;
      end if;

      Result := A11y.Results.Ok;
      return To_Unbounded_String
        (Linux_Path_Prefix
         & A11y.Native_Identity.Image (Session)
         & Linux_Path_Node_Sep
         & Trimmed_Image (A11y.Node_Ids.To_Natural (Node)));
   end Object_Path;

   function Parse_Natural
     (Text   : String;
      Result : out A11y.Results.Result)
      return Natural
   is
      Value : Natural := 0;
   begin
      if Text'Length = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return 0;
      end if;

      for Ch of Text loop
         if Ch not in '0' .. '9' then
            Result := (Status => A11y.Results.Invalid_Argument);
            return 0;
         end if;
         Value := Value * 10 + Character'Pos (Ch) - Character'Pos ('0');
      end loop;

      Result := A11y.Results.Ok;
      return Value;
   exception
      when Constraint_Error =>
         Result := (Status => A11y.Results.Resource_Limit);
         return 0;
   end Parse_Natural;

   function Node_From_Object_Path
     (Path    : String;
      Session : A11y.Native_Identity.Backend_Session_Id;
      Result  : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id
   is
      Session_Start : constant Natural := Path'First + Linux_Path_Prefix'Length;
      Sep_Start : Natural := 0;
      Parsed_Session : Natural;
      Parsed_Node : Natural;
      Node : A11y.Node_Ids.Node_Id;
   begin
      if not A11y.Native_Identity.Is_Valid (Session) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      end if;

      if Path'Length <= Linux_Path_Prefix'Length + Linux_Path_Node_Sep'Length
        or else Path (Path'First .. Path'First + Linux_Path_Prefix'Length - 1)
          /= Linux_Path_Prefix
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Node_Ids.No_Node;
      end if;

      for Index in Session_Start .. Path'Last - Linux_Path_Node_Sep'Length + 1 loop
         if Path (Index .. Index + Linux_Path_Node_Sep'Length - 1)
           = Linux_Path_Node_Sep
         then
            Sep_Start := Index;
            exit;
         end if;
      end loop;

      if Sep_Start = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Node_Ids.No_Node;
      end if;

      Parsed_Session :=
        Parse_Natural (Path (Session_Start .. Sep_Start - 1), Result);
      if A11y.Results.Failed (Result) then
         return A11y.Node_Ids.No_Node;
      end if;

      if Parsed_Session /= A11y.Native_Identity.To_Natural (Session) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      end if;

      Parsed_Node :=
        Parse_Natural
          (Path (Sep_Start + Linux_Path_Node_Sep'Length .. Path'Last),
           Result);
      if A11y.Results.Failed (Result) then
         return A11y.Node_Ids.No_Node;
      end if;

      Node := A11y.Node_Ids.From_Natural (Parsed_Node);
      if not A11y.Node_Ids.Is_Valid (Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      end if;

      Result := A11y.Results.Ok;
      return Node;
   exception
      when Constraint_Error =>
         Result := (Status => A11y.Results.Resource_Limit);
         return A11y.Node_Ids.No_Node;
   end Node_From_Object_Path;

   function Node_From_Object_Path
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Path    : String;
      Result  : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id is
     (Node_From_Object_Path (Path, Session, Result));

end A11y.Linux.ATSPi_Objects;
