package A11y.Backends.Classification is
   pragma SPARK_Mode (On);

   function Accepts_Events
     (State : Backend_State)
      return Boolean
   with
      Global => null,
      Post => Accepts_Events'Result = (State = Running);

   function Is_Terminal
     (State : Backend_State)
      return Boolean
   with
      Global => null,
      Post => Is_Terminal'Result = (State in Stopped | Failed);

   function Can_Initialize
     (State : Backend_State)
      return Boolean
   with
      Global => null,
      Post => Can_Initialize'Result = (State in Created | Stopped);

   function Can_Start
     (State : Backend_State)
      return Boolean
   with
      Global => null,
      Post => Can_Start'Result = (State in Created | Initialized | Stopped);

   function Can_Stop
     (State : Backend_State)
      return Boolean
   with
      Global => null,
      Post => Can_Stop'Result = (State not in Stopped | Failed);

   function Has_Native_Transport
     (Kind : Backend_Kind)
      return Boolean
   with
      Global => null,
      Post => Has_Native_Transport'Result = (Kind = Native);

end A11y.Backends.Classification;
