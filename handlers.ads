with Lower_Layer_UDP;
with Maps_G;
with Ada.Strings.Unbounded;
with Retransmissions;
with Protected_Ops;

package Handlers is

	package ASU renames Ada.Strings.Unbounded;
   package LLU renames Lower_Layer_UDP;
	
	procedure Print_Map (A : in ASU.Unbounded_String);

   procedure Server_Handler (From    : in     LLU.End_Point_Type;
                             To      : in     LLU.End_Point_Type;
                             P_Buffer: access LLU.Buffer_Type);

   procedure Client_Handler (From    : in     LLU.End_Point_Type;
                             To      : in     LLU.End_Point_Type;
                             P_Buffer: access LLU.Buffer_Type);
                             
   --procedure Time_Retransmission(Plazo_Retransmision: in Natural);
   
  -- Plazo_Retransmision: in Natural
   
   Server_EP_Handler: LLU.End_Point_Type;
   Client_EP_Handler: LLU.End_Point_Type;
   N_Max_Retrans_Attempts: Natural;
   --Retrans_Times: Retransmissions.rtp.list/type;
   Seq_N: Seq_N_T;

end Handlers;
