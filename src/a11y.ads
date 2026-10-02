with Ada.Calendar;

--  Platform-neutral accessibility provider model.
--
--  The A11y hierarchy is the forward-compatible public API. Existing
--  A11ykit.* packages remain as compatibility packages for current users.
package A11y is
   pragma Elaborate_Body;
   pragma SPARK_Mode (On);

   type Semantic_Revision is new Natural;
   Initial_Revision : constant Semantic_Revision := 0;

   type Event_Sequence is new Natural;
   No_Event : constant Event_Sequence := 0;
   function Event_Sequence_Image (Sequence : Event_Sequence) return String;

   subtype Timestamp is Ada.Calendar.Time;
end A11y;
