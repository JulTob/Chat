with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;
with Chat_Messages; 
with Handlers;
with Maps_G;
with Protected_Ops;
with Retransmissions;

procedure Chat_Server_2 is

	package LLU renames Lower_Layer_UDP;
   package ASU renames Ada.Strings.Unbounded;
   package ATIO renames Ada.Text_IO;
   package ACL renames Ada.Command_Line;
   package CM renames Chat_Messages;
   package PO renames Protected_Ops;
	
   use type CM.Message_Type;
   use type LLU.End_Point_Type;
   use type ASU.Unbounded_String;
   	
   	
   Ussage_Error: exception;
   Error_Retardo: exception;
   Error_Porcentaje: exception;
   	
   Port: Integer;
   Nmax: Integer;
   Min_Delay: Natural; 
	Max_Delay: Natural;
	Fault_pct: Natural;
	Plazo_Retransmision: Natural;
	--N_Max_Retrans_Attempts: Natural;
	--Retrans_Times: Natural;
   	
	Dir_IP: ASU.Unbounded_String;
   Server_EP_Handler: LLU.End_Point_Type;
   Nick: ASU.Unbounded_String;
   Comentario: ASU.Unbounded_String;
   Maquina: ASU.Unbounded_String;
   Quit: ASU.Unbounded_String := ASU.To_Unbounded_String(".quit");
   Texto: ASU.Unbounded_String;
   	
	--------------------------------------------------------
	L: String := "l";
	O: String := "o";
	Caracter: ASU.Unbounded_String;

begin

	if num_argument /= 5 then
		raise Ussage_Error;
	end if;

	Port := Integer'Value(ACL.Argument(1));
	Nmax := Integer'Value(ACL.Argument(2));
	Min_Delay := Natural'Value (ACL.Argument(3));	--Min retardo
	Max_Delay := Natural'Value (ACL.Argument(4));	--Max retardo
	Fault_pct := Natural'Value (ACL.Argument (5));	--Porcentage de pérdidas
	
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
	Plazo_Retransmision := 2 * Duration (Max_Delay) / 1000;
	
	if Nmax > 50 then
		ATIO.Put_Line("50 maximum clients");
		LLU.Finalize;
	elsif Nmax < 2 then
		ATIO.Put_Line("2 minimum clients");
		LLU.Finalize;
	end if;
	
	Server_EP_Handler := LLU.Build("127.0.0.1", Port);	
   LLU.Bind (Server_EP_Handler, Handlers.Server_Handler'Access);

	loop
	
		Caracter := ASU.To_Unbounded_String(ATIO.Get_Line);
		if ASU.To_String(Caracter) = "l" or ASU.To_String(Caracter) = "L" then
         ATIO.Put_Line("ACTIVE CLIENTS");
      	ATIO.Put_Line("==============");
      	--SH.PO.Protect_Call(SH.Show_Active_clients);
  			--Handlers.Print_Map(ASU.To_Unbounded_String(L));	
  			ATIO.New_Line;
                  	
		elsif ASU.To_String(Caracter) = "o" or ASU.To_String(Caracter) = "O" then
         ATIO.Put_Line("OLD CLIENTS");
       	ATIO.Put_Line("===========");
       	--SH.PO.Protect_Call(SH.Show_No_Active_clients);			
  			--Handlers.Print_Map(ASU.To_Unbounded_String(O));			
			ATIO.New_Line;
      else 
         ATIO.Put_Line("<l> or <L> for active clients, and <o> or <O> for inactive clients");
              	
		end if;
	
	end loop;

exception
	when Ussage_Error =>
		ATIO.Put_Line ("Incorrect arguments");
		LLU.Finalize;
	when Error_Retardo =>
		T_IO.Put_Line ("El tiempo de retardo no es válido");
		LLU.Finalize;
		--
	when Error_Porcentaje =>
		T_IO.Put_Line ("El porcentaje introducido no es válido");
		LLU.Finalize;
		--

end Chat_Server_2;
