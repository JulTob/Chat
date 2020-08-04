--gnatmake -I./maps_g_array -I/usr/local/ll/lib chat_client_3.adb
--./chat_client <Port> <Port> <Client's Nick>

with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Exceptions;

with Handlers;

with Chat_Control;
with Lower_Layer_UDP;

Procedure Chat_Client_3 is
	package CM renames Chat_Control ;
		Use type CM.Message_Type;
	package T_IO renames Ada.Text_IO;
	package LLU renames Lower_Layer_UDP;
		Use type LLU.End_Point_Type;
	--Comodity for the use of strings:
	package ASU renames Ada.Strings.Unbounded;
		use type ASU.Unbounded_String;
	--subtype UString is Ada.Strings.Unbounded.Unbounded_String; --Posible UString? hereda todas las propiedades, y se puede usar igual.
	--For Control Input
	package ComL renames Ada.Command_Line;
	--Error Control--
	Input_Mismatch: exception;
	Timeout_Exception: exception;
	Unreachable_Exception: exception;
	Wrong_Nick_Use: Exception;
	Terminate_Program: Exception;
	--Uso de funciones y tipos para chat, compartido Cliente y servidor
	package Chat renames Chat_Control;



	procedure Check_In(Port: out ASU.Unbounded_String;
							Server_Port: out Port_N;
							Nick: out ASU.Unbounded_String) is
	begin -- Check_In
	 if ComL.Argument_Count /= 3  or else ComL.Argument(3)="server" then
		  raise Input_Mismatch;
		  LLU.Finalize;
	 else
		 Port:= ASU.To_Unbounded_String(ComL.Argument(1));
		 Server_Port:= Integer'Value(ComL.Argument(2));
		 Nick:= ASU.To_Unbounded_String(ComL.Argument(3));
	 end if;
	exception
	 when others =>
		raise Input_Mismatch;
		LLU.Finalize; --UNREACHABLE, but solves a no-stop problem (?)
	end Check_In;




	procedure Set_Server (Server: in out Chat.Server_Type;
								Input_Server_Port: in Natural) is
	 Server_IP: ASU.Unbounded_String;
	begin -- Set_Server
	 Server_IP := ASU.To_Unbounded_String( LLU.To_IP( ASU.To_String( Server.Port)));
	 -- Construye el End_Point en el que está atado el servidor
	 Server.EP := LLU.Build(ASU.To_String(Server_IP), Input_Server_Port);
	end Set_Server;




	procedure Log_In(Server: in out Chat.Server_Type;
						 Client: in out Chat.Client_Type;
						 Buffer: in out LLU.Buffer_Type) is
	 Message: Chat.Message_Type;
	 Expired: Boolean;
	 Loged_In: Boolean;
	begin -- Log_In
	 Message:=CM.Init;
	 --Load Init|Client.EP|Handly|Nick into buffer
	 CM.Message_Type'Output(Buffer'Access, Message);
	 LLU.End_Point_Type'Output(Buffer'Access, Client.EP);
	 LLU.End_Point_Type'Output(Buffer'Access, Client.Handly);
	 ASU.Unbounded_String'Output(Buffer'Access, Client.Nick);
	 LLU.Send(Server.EP, Buffer'Access);
	 LLU.Reset(Buffer);
	 LLU.Receive (Client.EP, Buffer'Access, 20.0, Expired);
	 if Expired then
		 raise Unreachable_Exception;
	 end if;
	 --Receive Welcome|Loged_In? into buffer
	 Message:=CM.Message_Type'Input(Buffer'Access);
	 Loged_In:=Boolean'Input(Buffer'Access);
	 if Loged_In and then Message=CM.Welcome then
		 T_IO.Put_Line("Chat v2.0 Loged In");
		 T_IO.Put_Line("Write '.quit' to Log Out");
		 T_IO.Put(ASU.To_String(Client.Nick) & " >> ");
	 else
		 T_IO.Put_Line("Chat v2.0 NOT Loged In");
		 T_IO.Put_Line(ASU.To_String(Client.Nick) & " is already in use. ");
		 raise Wrong_Nick_Use;
	 end if;
	end Log_In;





	procedure Chat_Room ( Client: in Chat.Client_Type;
								Server: in out Chat.Server_Type;
								Buffer: in out LLU.Buffer_Type) is
	  Broadcast: ASU.Unbounded_String;
	  Quit: constant ASU.Unbounded_String := ASU.To_Unbounded_String (".quit");
	begin -- Chat_Room
	 loop
		Broadcast:=ASU.To_Unbounded_String(T_IO.Get_Line);
	  if Broadcast=Quit then
		  LLU.Reset(Buffer);
		  --Logout|Handly|Nick
		  CM.Message_Type'Output(Buffer'Access,CM.Logout);
		  LLU.End_Point_Type'Output(Buffer'Access, Client.Handly);
		  ASU.Unbounded_String'Output(Buffer'Access, Client.Nick);
		  LLU.Send (Server.EP, Buffer'Access);
		  raise Terminate_Program;
	  else
		  LLU.Reset(Buffer);
		  --Writer|Handly|Nick|Broadcast
		  CM.Message_Type'Output(Buffer'Access,CM.Writer);
		  LLU.End_Point_Type'Output(Buffer'Access, Client.Handly);
		  ASU.Unbounded_String'Output(Buffer'Access, Client.Nick);
		  ASU.Unbounded_String'Output(Buffer'Access, Broadcast);
		  LLU.Send (Server.EP, Buffer'Access);
		  T_IO.Put(">> ");
	  end if;
	end loop;
	end Chat_Room;




	-------------------------
	--Variables y Elementos--
	Server:  Chat.Server_Type;
	Client:  Chat.Client_Type;
	Input_Server_Port:  Natural;
	Buffer:  aliased LLU.Buffer_Type(1024);
	Request: ASU.Unbounded_String;
	Reply:   ASU.Unbounded_String;
	Reader:  constant ASU.Unbounded_String:= ASU.To_Unbounded_String("reader");
	--------------------------


	
	begin -- ChatClient

	Check_In(Server.Port, Input_Server_Port, Client.Nick);

	Set_Server(Server,Input_Server_Port);

	-- Construye un End_Point libre cualquiera y se ata a él con Handly
	LLU.Bind_Any (Client.Handly, Handler.Client_Handler'Access);
	LLU.Bind_Any(Client.EP);
	-- reinicializa el buffer para empezar a utilizarlo
	LLU.Reset(Buffer);
	Log_In(Server,Client,Buffer);
	Chat_Room(Client,Server,Buffer);
	-- UNREACHABLE terminate Lower_Layer_UDP
	LLU.Finalize;
	exception
	when Input_Mismatch =>
		T_IO.Put_Line("Error: Wrong Call.");
		T_IO.Put_Line("Correct format is");
		T_IO.Put_Line("... <Port> <Port> <Client's Nick>");
		T_IO.Put_Line("<Client's Nick> not allowed to be 'server'");
		LLU.Finalize;
	when Unreachable_Exception =>
			 Ada.Text_IO.Put_Line ("Server unreachable.");
			 LLU.Finalize;
	when Timeout_Exception =>
		Ada.Text_IO.Put_Line ("Timeout. Restart program to broadcast again.");
		LLU.Finalize;
	when Wrong_Nick_Use =>
		Ada.Text_IO.Put_Line ("Restart program with different Nick.");
		LLU.Finalize;
	when Terminate_Program =>
	LLU.Finalize;
	when Ex:others =>
		Ada.Text_IO.Put_Line ("Excepción imprevista: " &
									Ada.Exceptions.Exception_Name(Ex) &
									" en: " &
									Ada.Exceptions.Exception_Message(Ex));
		LLU.Finalize;
end Chat_Client_3;
