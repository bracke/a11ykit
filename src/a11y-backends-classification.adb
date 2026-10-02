package body A11y.Backends.Classification is
   pragma SPARK_Mode (On);

   function Accepts_Events
     (State : Backend_State)
      return Boolean is
     (State = Running);

   function Is_Terminal
     (State : Backend_State)
      return Boolean is
     (State in Stopped | Failed);

   function Can_Initialize
     (State : Backend_State)
      return Boolean is
     (State in Created | Stopped);

   function Can_Start
     (State : Backend_State)
      return Boolean is
     (State in Created | Initialized | Stopped);

   function Can_Stop
     (State : Backend_State)
      return Boolean is
     (State not in Stopped | Failed);

   function Has_Native_Transport
     (Kind : Backend_Kind)
      return Boolean is
     (Kind = Native);

end A11y.Backends.Classification;
