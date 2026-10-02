package body A11y.Native_Object_Caches.Classification is
   pragma SPARK_Mode (On);

   function Valid_Capacity (Capacity : Natural) return Boolean is
     (Capacity in 1 .. Max_Native_Objects);

   function Allocated_Count (Next_Id : Natural) return Natural is
     (if Next_Id = 0 then 0 else Next_Id - 1);

   function Can_Set_Limits
     (Next_Id            : Natural;
      Tombstone_Count    : Natural;
      Object_Capacity    : Natural;
      Tombstone_Capacity : Natural)
      return Boolean is
     (Valid_Capacity (Object_Capacity)
      and then Valid_Capacity (Tombstone_Capacity)
      and then Object_Capacity >= Allocated_Count (Next_Id)
      and then Tombstone_Capacity >= Tombstone_Count);

   function Can_Advance_Generation
     (Generation : Natural)
      return Boolean is
     (Generation < Natural'Last);

   function Generation_Advanced
     (Before : Natural;
      After  : Natural)
      return Boolean is
     (After > Before);

   function Count_Changed
     (Before : Natural;
      After  : Natural)
      return Boolean is
     (After /= Before);

   function Object_Returned
     (Object : Native_Object_Id)
      return Boolean is
     (Object /= No_Object);

   function Active_Slot
     (Slot    : Natural;
      Next_Id : Natural)
      return Boolean is
     (Slot /= 0 and then Slot < Next_Id);

   function Live_Record
     (Used     : Boolean;
      Released : Boolean;
      Defunct  : Boolean)
      return Boolean is
     (Used and then not Released and then not Defunct);

   function Releasable_Record
     (Used     : Boolean;
      Released : Boolean)
      return Boolean is
     (Used and then not Released);

end A11y.Native_Object_Caches.Classification;
