with Ada.Text_IO;
with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Ada.Command_Line;
with Chat_Messages;
with Handlers;
with Maps_G;
with Protected_Ops;
--with Retransmissions;


procedure Chat_Client_2 is

	package LLU renames Lower_Layer_UDP;
   package ASU renames Ada.Strings.Unbounded;
   package ATIO renames Ada.Text_IO;
   package ACL renames Ada.Command_Line;
   package CM renames Chat_Messages;
   package PO renames Protected_Ops;
   	
   use type CM.Message_Type;
   
   Ussage_Error: exception;
   Error_Retardo: exception;
  	Error_Porcentaje: exception;
   	
   Mess: CM.Message_Type;

	Nick: ASU.Unbounded_String;
	Name_Server: ASU.Unbounded_String;
	Port: Integer;
	Min_Delay: Natural; 
	Max_Delay: Natural;
	Fault_pct: Natural;
	Plazo_Retransmision: Natural;
	N_Max_Retrans_Attempts: Natural;
	Retrans_Times: Natural;

--	Server_EP_Handler: LLU.End_Point_Type;
   Client_EP_Receive: LLU.End_Point_Type;
--   Client_EP_Handler: LLU.End_Point_Type;
	Buffer: aliased LLU.Buffer_Type(1024);
	Expired: Boolean;	
	Acogido: Boolean;	
	Quit: ASU.Unbounded_String := ASU.To_Unbounded_String (".quit"); 
	Comentario: ASU.Unbounded_String;

begin

	if num_argument /= 6 then
		raise Ussage_Error;
	end if;

	Name_Server := ASU.To_Unbounded_String(ACL.Argument(1));
	Port := Integer'Value(ACL.Argument(2));
	Nick := ASU.To_Unbounded_String(ACL.Argument(3));	
	Min_Delay:= Natural'Value (ACL.Argument (4));	--integer???
	Max_Delay:= Natural'Value (ACL.Argument (5));
	Fault_pct:= Natural'Value (ACL.Argument (6));
	
	if Nick = Server then
		raise Ussage_Error;
	end if;
	
	if Min_Delay > Max_Delay then
		raise Error_Retardo;
	end if;
	
	if Fault_pct < 0 or Fault_pct > 100 then
		raise Error_Porcentaje;
	end if;
 
	--Simulación de pérdida de paquetes, retardos de propagación
	LLU.Set_Faults_Percent (Fault_pct);
	LLU.Set_Random_Propagation_Delay (Min_Delay, Max_Delay);
	Plazo_Retransmision := 2 * Duration (Max_Delay) / 1000;	--Handlers.?
	
	Server_EP_Handler := LLU.Build("127.0.0.1", Port);	--_Handler?
	LLU.Bind_Any(Client_EP_Receive);		
	LLU.Bind_Any(Client_EP_Handler, Handlers.Client_Handler'Access);	

--===========================================================================================================================	
	N_Max_Retrans_Attempts := 0;
	
	loop
		------MENSAJE INIT----------------
		LLU.Reset(Buffer);
   	CM.Message_Type'Output(Buffer'Access, CM.Init);
   	LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Receive);  
   	LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler);  
   	ASU.Unbounded_String'Output(Buffer'Access, Nick);
		LLU.Send(Server_EP_Handler, Buffer'Access);	
		N_Max_Retrans_Attempts := N_Max_Retrans_Attempts + 1;
		LLU.Reset(Buffer);

		--------RECIBIR WELCOME-------------
		LLU.Receive(Client_EP_Receive, Buffer'Access, 10.0, Expired); 

		if Expired then									
    		ATIO.Put_Line ("Server unreachable");	
    		--LLU.Finalize;
    		
    		--manda el init again
    	
		end if;
		
    	exit when not Expired or N_Max_Retrans_Attempts = Retrans_Times;
	end loop;
    		
--===========================================================================================================================
  	if not Expired then
 
   	Mess := CM.Message_Type'Input(Buffer'Access);
   	Acogido := Boolean'Input(Buffer'Access);
   	if Acogido = True then
		 	ATIO.Put_Line("Mini-Chat 2.0: Welcome " & ASU.To_String(Nick));
		 	Seq_N := CM.Seq_N_T'First; 
		 	--Handlers.Header_Msg := CM.Writer;??????????????????????????
		 	
		 	loop
				LLU.Reset(Buffer);
				ATIO.Put(">> ");
				Comentario := ASU.To_Unbounded_String(ATIO.Get_Line);

				if ASU.To_String(Comentario) /= ASU.To_String(Quit) then
					--------MENSAJE WRITER--------------
					LLU.Reset(Buffer);
					CM.Message_Type'Output (Buffer'Access, CM.Writer);
 					LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler); 
 					CM.Seq_N_T'Output(Buffer'Access, Seq_N);
      			ASU.Unbounded_String'Output(Buffer'Access, Nick);					
					ASU.Unbounded_String'Output (Buffer'Access, Comentario);			
					LLU.Send(Server_EP_Handler, Buffer'Access);
					LLU.Reset(Buffer);
					
					--llamar a protected_ops.pr ??????????????????????????????
					--Handlers.Times_Retransmission
					
					Handlers.Seq_N := Handlers.Seq_N +1;	--sin handler??
					
         	end if;
       
			exit when ASU.To_String(Comentario) = ASU.To_String(Quit);
			end loop;
			
			--Handlers.Header_Msg := CM.Writer;
			---------MENSAJE LOGOUT------------
			LLU.Reset(Buffer);
      	CM.Message_Type'Output(Buffer'Access, CM.Logout);
   		LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler); 
   		CM.Seq_N_T'Output(Buffer'Access, Seq_N); 
   	  	ASU.Unbounded_String'Output(Buffer'Access, Nick);					
			LLU.Send(Server_EP_Handler, Buffer'Access);
			LLU.Reset(Buffer);
			
			--llamar a protected_ops.pr ??????????????????????????????
			--Handlers.Times_Retransmission
		
			LLU.Finalize;		
--===========================================================================================================================
		elsif Acogido = False then
         ATIO.Put_Line("Mini-Chat 2.0: IGNORED new user " & ASU.To_String(Nick) & ", nick already used");
         LLU.Finalize;
				 
		end if;
   			
	end if;

exception
	when Ussage_Error =>
		ATIO.Put_Line ("Incorrect arguments");
		LLU.Finalize;
	when Error_Retardo =>
		ATIO.Put_Line ("El tiempo de retardo no es válido");
		LLU.Finalize;
		--
	when Error_Porcentaje =>
		ATIO.Put_Line ("El porcentaje introducido no es válido");
		LLU.Finalize;
		--


end Chat_Client_2;
