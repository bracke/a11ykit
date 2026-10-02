with A11ykit.Tree;

with A11y.Results;

package A11ykit.Provider_Runtime is

   procedure Publish (Tree : A11ykit.Tree.Accessibility_Tree);

   procedure Record_Publish_Result
     (Status           : A11y.Results.Status_Code;
      Delivered        : Natural;
      Backend_Name     : String;
      Used_Fallback    : Boolean;
      Selection_Status : A11y.Results.Status_Code);

   function Last_Publish_Status return A11y.Results.Status_Code;

   function Last_Published_Event_Count return Natural;

   function Last_Publish_Backend_Name return String;

   function Last_Publish_Used_Fallback return Boolean;

   function Last_Publish_Selection_Status return A11y.Results.Status_Code;

end A11ykit.Provider_Runtime;
