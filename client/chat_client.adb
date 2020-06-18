--gnatmake -I/usr/local/ll/lib chat_client.adb
--./chat_client <Machine> <Port> <Client's Nick>

with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Exceptions;

with Chat_Control;
with Chat_Messages;
with Lower_Layer_UDP;

Procedure Chat_Client is

   package CM renames Chat_Messages ;
   Use type CM.Message_Type;

   package T_IO renames Ada.Text_IO;

   package LLU renames Lower_Layer_UDP;
   Use type LLU.End_Point_Type;

   --Comodity for the use of strings:
   package ASU renames Ada.Strings.Unbounded;
   use type ASU.Unbounded_String;
	 --   subtype UString is Ada.Strings.Unbounded.Unbounded_String; 
	 		---- Posible UString? hereda todas las propiedades, y se puede usar igual.

   -- For Control Input
   package ComL renames Ada.Command_Line;
   Input_Mismatch: exception;

   -- Uso de funciones y tipos para chat, compartido Cliente y servidor
   package Chat renames Chat_Control;

   procedure Read (
	 		Buffer: in out LLU.Buffer_Type;
			Client: in out Chat.Client_Type
     ) is
     	Message_Read: CM.Message_Type;
      Expired: Boolean;
      Text: ASU.Unbounded_String;
   	begin -- Read
			loop
				LLU.Reset(Buffer);
				LLU.Receive (Client.EP, Buffer'Access, 120.0, Expired);
				if Expired then
						Ada.Text_IO.Put_Line ("Timeout");
         else
	         Message_Read := CM.Message_Type'Input(Buffer'Access);
         	 Client.Nick := ASU.Unbounded_String'Input (Buffer'Access);
				 	 Text := ASU.Unbounded_String'Input (Buffer'Access);
   			 		if Message_Read /= CM.Server then
							Ada.Text_IO.Put(ASU.To_String(Client.Nick) & ": ");
							Ada.Text_IO.Put_Line(ASU.To_String(Text));
				 		else
							Ada.Text_IO.Put_Line("Message with admin rights.");
				 			end if;
						end if;
         	end loop;
   	end Read;

   procedure Write ( 
	 			Buffer: in out LLU.Buffer_Type;
				Client: in out Chat.Client_Type;
				Server: in out Chat.Server_Type
			) is
      Text: ASU.Unbounded_String;
      Quit: ASU.Unbounded_String := ASU.To_Unbounded_String (".quit");
      Message: CM.Message_Type := CM.Writer;
   		begin -- Write
      	T_IO.Put_Line("You logged in, write to the chat room: ");
      	T_IO.Put_Line("[Write '.quit' to exit.]");
      	loop
					T_IO.Put("Message: ");
					Text := ASU.To_Unbounded_String(T_IO.Get_Line);
					if not (Text=Quit) then
						LLU.Reset(Buffer);
						CM.Message_Type'Output(Buffer'Access, Message);
						LLU.End_Point_Type'Output(Buffer'Access, Client.EP);
						ASU.Unbounded_String'Output (Buffer'Access, Text);
              -- envía el contenido del Buffer
						LLU.Send(Server.EP, Buffer'Access);
						end if;
					exit when Text = Quit;
					end loop;
   			end Write;

   --Variables y Elementos
   Server: Chat.Server_Type;
   Client: Chat.Client_Type;
   Input_Server_Port:  Integer;
   Server_IP: ASU.Unbounded_String;
   Buffer:    aliased LLU.Buffer_Type(1024);
   Request:   ASU.Unbounded_String;
   Reply:     ASU.Unbounded_String;
   Message: CM.Message_Type;
   Reader: 	constant ASU.Unbounded_String:= ASU.To_Unbounded_String("reader");
   Aux_EP:	LLU.End_Point_Type;

	begin -- ChatClient
  	--Control Input
   	if ComL.Argument_Count /= 3 then
    	raise Input_Mismatch;
   	else
    	T_IO.Put_Line("1");
      Server.Machine:= ASU.To_Unbounded_String(ComL.Argument(1));
      Input_Server_Port:= Integer'Value(ComL.Argument(2));
      Client.Nick:= ASU.To_Unbounded_String(ComL.Argument(3));
      T_IO.Put_Line("2");
	   end if;
   	T_IO.Put_Line("3");
	  Server_IP := 
			ASU.To_Unbounded_String(
				LLU.To_IP( 
					ASU.To_String( Server.Machine)));

		-- Construye el End_Point en el que está atado el servidor
		Server.EP := LLU.Build(ASU.To_String(Server_IP), Input_Server_Port);
		-- Construye un End_Point libre cualquiera y se ata a él
   	LLU.Bind_Any(Client.EP);
   	-- reinicializa el buffer para empezar a utilizarlo
   	LLU.Reset(Buffer);
   	T_IO.Put_Line("4");

  	if Client.Nick = Reader then
    	T_IO.Put_Line("5");
			--Load Init|Client.EP|Nick into buffer
      Message:= CM.Init;
      T_IO.Put_Line("5.2");

      CM.Message_Type'Output(Buffer'Access, Message);
      T_IO.Put_Line("5.3");

      LLU.End_Point_Type'Output(Buffer'Access, Client.EP);
      T_IO.Put_Line("5.4");

      ASU.Unbounded_String'Output(Buffer'Access, Client.Nick);
      T_IO.Put_Line("5.5");

      LLU.Send(Server.EP, Buffer'Access);
      T_IO.Put_Line("5.1");

      --Proceed to read messages
      Read(Buffer, Client);
      T_IO.Put_Line("6");

   	else
    	--Load Init|Client.EP|Nick into buffer
      T_IO.Put_Line("7");

      Message := CM.Init;
   		CM.Message_Type'Output(Buffer'Access, Message);
   		LLU.End_Point_Type'Output(Buffer'Access, Client.EP);
     	ASU.Unbounded_String'Output(Buffer'Access, Client.Nick);
   		LLU.Send(Server.EP, Buffer'Access);
      T_IO.Put_Line("8");

      -- Proceed to write
      T_IO.Put_Line("9");

      Write(Buffer,Client,Server);
   		end if;

		T_IO.Put_Line("10");

   -- terminate Lower_Layer_UDP
   LLU.Finalize;
	exception
   		when Input_Mismatch =>
      	T_IO.Put_Line("Error: Wrong Call.");
      	T_IO.Put_Line("Correct format is");
      	T_IO.Put_Line("... <Machine> <Port> <Client's Nick>");
      	LLU.Finalize;
   		when Ex:others =>
      	Ada.Text_IO.Put_Line (
						"Excepción imprevista: " &
            Ada.Exceptions.Exception_Name(Ex) &
            " en: " &
            Ada.Exceptions.Exception_Message(Ex));
      	LLU.Finalize;
		end Chat_Client;
