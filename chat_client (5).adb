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
--   subtype UString is Ada.Strings.Unbounded.Unbounded_String; --Posible UString? hereda todas las propiedades, y se puede usar igual.

   --For Control Input
   package ComL renames Ada.Command_Line;
   Input_Mismatch: exception;
   Timeout_Exception: exception;


   --Uso de funciones y tipos para chat, compartido Cliente y servidor
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
           LLU.Receive (Client.EP, Buffer'Access, 900.0, Expired);
           if Expired then
             raise Timeout_Exception;
           else
	          Message_Read := CM.Message_Type'Input(Buffer'Access);
         	 Client.Nick := ASU.Unbounded_String'Input (Buffer'Access);
				 Text := ASU.Unbounded_String'Input (Buffer'Access);
   			 if Message_Read = CM.Server then
               Ada.Text_IO.Put(ASU.To_String(Client.Nick) & ": ");
					Ada.Text_IO.Put_Line(ASU.To_String(Text));
				 else
					Ada.Text_IO.Put_Line("Message with admin rights.");
				 end if;
				end if;
         end loop;
   end Read;

   procedure Write ( Buffer: in out LLU.Buffer_Type;
                     Client: in out Chat.Client_Type;
                     Server: in out Chat.Server_Type
              ) is
      Text: ASU.Unbounded_String;
      Quit: ASU.Unbounded_String := ASU.To_Unbounded_String (".quit");
      Message:CM.Message_Type:=CM.Writer;
   begin -- Write
      T_IO.New_Line(2);
      T_IO.Put_Line("You logged in, if your Nick is not in use.");
      T_IO.Put_Line("    Write to the chat room: ");
      T_IO.Put_Line("    [Write '.quit' to exit.]");
      T_IO.New_Line(2);


      loop
				T_IO.Put("Message: ");
				Text := ASU.To_Unbounded_String(T_IO.Get_Line);

					LLU.Reset(Buffer);
					CM.Message_Type'Output(Buffer'Access, Message);
					LLU.End_Point_Type'Output(Buffer'Access, Client.EP);
					ASU.Unbounded_String'Output (Buffer'Access, Text);
               -- envía el contenido del Buffer
					LLU.Send(Server.EP, Buffer'Access);
				
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
   Reader: constant ASU.Unbounded_String:= ASU.To_Unbounded_String("reader");
   Aux_EP:LLU.End_Point_Type;

begin -- ChatClient
   --Control Input
   if ComL.Argument_Count /= 3 then
      raise Input_Mismatch;
   else
      Server.Machine:= ASU.To_Unbounded_String(ComL.Argument(1));
      Input_Server_Port:= Integer'Value(ComL.Argument(2));
      Client.Nick:= ASU.To_Unbounded_String(ComL.Argument(3));

   end if;

   Server_IP := ASU.To_Unbounded_String(
               LLU.To_IP( ASU.To_String( Server.Machine)));

   -- Construye el End_Point en el que está atado el servidor
   Server.EP := LLU.Build(ASU.To_String(Server_IP), Input_Server_Port);
   -- Construye un End_Point libre cualquiera y se ata a él
   LLU.Bind_Any(Client.EP);
   -- reinicializa el buffer para empezar a utilizarlo
   LLU.Reset(Buffer);

   if Client.Nick = Reader then

      --Load Init|Client.EP|Nick into buffer
         Message:= CM.Init;
         CM.Message_Type'Output(Buffer'Access, Message);
         LLU.End_Point_Type'Output(Buffer'Access, Client.EP);
         ASU.Unbounded_String'Output(Buffer'Access, Client.Nick);
         LLU.Send(Server.EP, Buffer'Access);

      --Proceed to read messages
         Read(Buffer, Client);

   else
      --Load Init|Client.EP|Nick into buffer

         Message := CM.Init;

   		CM.Message_Type'Output(Buffer'Access, Message);
   		LLU.End_Point_Type'Output(Buffer'Access, Client.EP);
     	ASU.Unbounded_String'Output(Buffer'Access, Client.Nick);
      Aux_EP:=Server.EP;

   		LLU.Send(Aux_EP, Buffer'Access);

      --Proceed to write

         Write(Buffer,Client,Server);
   end if;

   -- terminate Lower_Layer_UDP
   LLU.Finalize;
exception
   when Input_Mismatch =>
      T_IO.Put_Line("Error: Wrong Call.");
      T_IO.Put_Line("Correct format is");
      T_IO.Put_Line("... <Machine> <Port> <Client's Nick>");
      LLU.Finalize;
  when Timeout_Exception =>
      Ada.Text_IO.Put_Line ("Timeout. Restart program to broadcast again.");
      LLU.Finalize;
   when Ex:others =>
      Ada.Text_IO.Put_Line ("Excepción imprevista: " &
                           Ada.Exceptions.Exception_Name(Ex) &
                           " en: " &
                           Ada.Exceptions.Exception_Message(Ex));
      LLU.Finalize;
end Chat_Client;
