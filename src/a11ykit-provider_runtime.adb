with Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;

with A11ykit.Compatibility;

with A11y.Backends.Default;
with A11y.Backends.Event_Pumps;
with A11y.Backends.Selection;
with A11y.Sessions;

package body A11ykit.Provider_Runtime is

   use Ada.Strings.Unbounded;

   type Session_Access is access A11y.Sessions.Semantic_Session;
   type Backend_Access is access A11y.Backends.Backend'Class;
   procedure Free is new Ada.Unchecked_Deallocation
     (Object => A11y.Sessions.Semantic_Session,
      Name   => Session_Access);
   procedure Free is new Ada.Unchecked_Deallocation
     (Object => A11y.Backends.Backend'Class,
      Name   => Backend_Access);

   protected Publication_State is
      procedure Store
        (Status    : A11y.Results.Status_Code;
         Delivered : Natural;
         Backend_Name : String;
         Used_Fallback : Boolean;
         Selection_Status : A11y.Results.Status_Code);
      function Status return A11y.Results.Status_Code;
      function Delivered return Natural;
      function Backend_Name return String;
      function Used_Fallback return Boolean;
      function Selection_Status return A11y.Results.Status_Code;
   private
      Last_Status : A11y.Results.Status_Code := A11y.Results.Success;
      Last_Delivered : Natural := 0;
      Last_Backend_Name : Unbounded_String := To_Unbounded_String ("");
      Last_Used_Fallback : Boolean := False;
      Last_Selection_Status : A11y.Results.Status_Code := A11y.Results.Success;
   end Publication_State;

   protected body Publication_State is
      procedure Store
        (Status    : A11y.Results.Status_Code;
         Delivered : Natural;
         Backend_Name : String;
         Used_Fallback : Boolean;
         Selection_Status : A11y.Results.Status_Code) is
      begin
         Last_Status := Status;
         Last_Delivered := Delivered;
         Last_Backend_Name := To_Unbounded_String (Backend_Name);
         Last_Used_Fallback := Used_Fallback;
         Last_Selection_Status := Selection_Status;
      end Store;

      function Status return A11y.Results.Status_Code is
        (Last_Status);

      function Delivered return Natural is
        (Last_Delivered);

      function Backend_Name return String is
        (To_String (Last_Backend_Name));

      function Used_Fallback return Boolean is
        (Last_Used_Fallback);

      function Selection_Status return A11y.Results.Status_Code is
        (Last_Selection_Status);
   end Publication_State;

   procedure Publish (Tree : A11ykit.Tree.Accessibility_Tree) is
      Session : Session_Access := new A11y.Sessions.Semantic_Session;
      Selection : constant A11y.Backends.Selection.Selection_Result :=
        A11y.Backends.Selection.Resolve ("default");
      Backend : Backend_Access := null;
      Pump_Report : A11y.Backends.Event_Pumps.Pump_All_Report;
      Result : A11y.Results.Result;
      Pump_Result : A11y.Results.Result;
      Stop_Result : A11y.Results.Result;
   begin
      --  Native and validating backends carry bounded node-state tables. Keep
      --  them off callers' task stacks for the same reason as the semantic
      --  session: provider publication is valid from a GUI task with a small
      --  configured stack.
      Backend := new A11y.Backends.Backend'Class'
        (A11y.Backends.Default.Create_Default);
      A11ykit.Compatibility.Populate_Session (Tree, Session.all, Result);
      if A11y.Results.Failed (Result) then
         Publication_State.Store
           (Result.Status, 0, "", Selection.Fallback, Selection.Status);
         Free (Session);
         Free (Backend);
         return;
      end if;

      Result := Backend.all.Start;
      if A11y.Results.Failed (Result) then
         Publication_State.Store
           (Result.Status, 0, Backend.all.Name, Selection.Fallback,
            Selection.Status);
         Free (Session);
         Free (Backend);
         return;
      end if;

      A11y.Backends.Event_Pumps.Pump_All_With_Report
        (Session.all, Backend.all, Pump_Report, Pump_Result);
      Stop_Result := Backend.all.Stop;

      if A11y.Results.Failed (Pump_Result) then
         Publication_State.Store
           (Pump_Result.Status, Pump_Report.Delivered, Backend.all.Name,
            Selection.Fallback, Selection.Status);
         Free (Session);
         Free (Backend);
         return;
      elsif A11y.Results.Failed (Stop_Result) then
         Publication_State.Store
           (Stop_Result.Status, Pump_Report.Delivered, Backend.all.Name,
            Selection.Fallback, Selection.Status);
         Free (Session);
         Free (Backend);
         return;
      end if;

      Publication_State.Store
        (A11y.Results.Success, Pump_Report.Delivered, Backend.all.Name,
         Selection.Fallback, Selection.Status);
      Free (Session);
      Free (Backend);
   exception
      when others =>
         if Session /= null then
            Free (Session);
         end if;
         if Backend /= null then
            Free (Backend);
         end if;
         Publication_State.Store
           (A11y.Results.Internal_Error, 0, "", False,
            A11y.Results.Internal_Error);
   end Publish;

   function Last_Publish_Status return A11y.Results.Status_Code is
     (Publication_State.Status);

   procedure Record_Publish_Result
     (Status           : A11y.Results.Status_Code;
      Delivered        : Natural;
      Backend_Name     : String;
      Used_Fallback    : Boolean;
      Selection_Status : A11y.Results.Status_Code) is
   begin
      Publication_State.Store
        (Status, Delivered, Backend_Name, Used_Fallback, Selection_Status);
   end Record_Publish_Result;

   function Last_Published_Event_Count return Natural is
     (Publication_State.Delivered);

   function Last_Publish_Backend_Name return String is
     (Publication_State.Backend_Name);

   function Last_Publish_Used_Fallback return Boolean is
     (Publication_State.Used_Fallback);

   function Last_Publish_Selection_Status return A11y.Results.Status_Code is
     (Publication_State.Selection_Status);

end A11ykit.Provider_Runtime;
