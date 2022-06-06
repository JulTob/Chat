with Ada.Real_Time;

--
-- Calls to any Procedure_A, either those programmed through Program_Timer_Procedure
-- to be executed by the system in the future, or those executed through a call to
-- Protected_Call, are executed in mutual exclusion.
--

package Protected_Ops is
	type Procedure_A is access procedure;
	
	procedure Program_Timer_Procedure (H: Procedure_A; T: Ada.Real_Time.Time);
	-- Schedules H to be executed at time T by the system. When H.all is called, it
	-- will be executed in a new thread, in mutual exclusion with calls executed
	-- through Protected_Call.
	
	procedure Protected_Call (H: Procedure_A);
	-- The calling thread executes H.all, in mutual exclusion with other calls made
	-- through Protected_Call, and with calls to procedures scheduled to be executed
	-- by the system through calls to Program_Timer_Procedure
	
end Protected_Ops;
