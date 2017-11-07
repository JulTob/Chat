with Lower_Layer_UDP;
with Client_Collections;
with Chat_Messages;
with Chat_Control;

with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;


procedure Chat_Server is
   package CC renames Client_Collections ;

   package LLU renames Lower_Layer_UDP;
   Use type LLU.End_Point_Type;

   package ASU renames Ada.Strings.Unbounded;
   use type ASU.Unbounded_String;

   package T_IO renames Ada.Text_IO;

   package CM renames Chat_Messages ;
   Use type CM.Message_Type;

   package ComL renames Ada.Command_Line;
   Input_Mismatch: exception;
   Timeout_Exception: exception;

   --Uso de funciones y tipos para chat, compartido Cliente y servidor
   package Chat renames Chat_Control;
   Use type Chat.Server_Type;
   Use type Chat.Client_Type;



      Inform: ASU.Unbounded_String;
      Server: Chat.Server_Type;
      Client: Chat.Client_Type;
      Buffer: aliased LLU.Buffer_Type(1024);
      Server_IP: ASU.Unbounded_String;
      Reader: constant ASU.Unbounded_String := ASU.To_Unbounded_String ("reader");
      Readers_C: CC.Collection_Type;
   	Clients_C: CC.Collection_Type;
      Comment: ASU.Unbounded_String;
      Port_Number: Integer;
      Expired: Boolean;
      Message : CM.Message_Type;
      Message_S: constant CM.Message_Type:= CM.Server;
      Quit: ASU.Unbounded_String := ASU.To_Unbounded_String (".quit");

begin --Chat_Server

   if not(ComL.Argument_Count=1) then
      raise Input_Mismatch;
   end if;
   Port_Number := Natural'Value(ComL.Argument(1));
   Server.Machine := ASU.To_Unbounded_String(LLU.Get_Host_Name);
   Server_IP := ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Server.Machine)));
   -- End_Point en una dirección y puerto
   Server.EP := LLU.Build (ASU.To_String(Server_IP), Port_Number);
   -- se ata al End_Point para poder recibir en él
   LLU.Bind (Server.EP);
   -- bucle infinito
   loop
      -- reinicializa (vacía) el buffer para ahora recibir en él
      LLU.Reset(Buffer);
      -- espera 1000.0 segundos a recibir algo dirigido al Server.EP
      LLU.Receive (Server.EP, Buffer'Access, 1000.0, Expired);

      if Expired then
         raise Timeout_Exception;
      else
         Message := CM.Message_Type'Input(Buffer'Access);
         case Message is
            when CM.Init =>
               Client.EP := LLU.End_Point_Type'Input (Buffer'Access);
               Client.Nick := ASU.Unbounded_String'Input (Buffer'Access);
               if Client.Nick = Reader then
               	Ada.Text_IO.Put_Line("INIT: Reader logged in.");
   					CC.Add_Client (Readers_C, Client.EP, Reader, Unique=>False);
               else
                begin
               	CC.Add_Client (Clients_C, Client.EP, Client.Nick, Unique=>True);
                  T_IO.Put_Line("INIT:" & ASU.To_String(Client.Nick) & " logged in. ");
                  LLU.Reset (Buffer);
                  CM.Message_Type'Output(Buffer'Access, Message_S);
            		ASU.Unbounded_String'Output (Buffer'Access, Server.Machine);
                  Inform := ASU.To_Unbounded_String(ASU.To_String(Client.Nick)
            																			& " joined the chat");
            		ASU.Unbounded_String'Output (Buffer'Access, Inform);

            		CC.Send_To_All(Readers_C, Buffer'Access);
                exception
                   when CC.Client_Collection_Error =>
       						 Ada.Text_IO.Put_Line("INIT IGNORED, nick already used");
                end;
               end if;
            when CM.Writer =>
               Client.EP := LLU.End_Point_Type'Input (Buffer'Access);
               Comment:= ASU.Unbounded_String'Input (Buffer'Access);
               begin
                  Client.Nick:=CC.Search_Client(Clients_C,Client.EP); --PossibleX
                  if Comment=Quit then
                     CC.Delete_Client(Clients_C,Client.Nick);
                     T_IO.Put_Line("LOGOUT:" & ASU.To_String(Client.Nick) & " logged out. ");
                  else
                     T_IO.Put(ASU.To_String(Client.Nick) & ": ");
   					         T_IO.Put_Line(ASU.To_String(Comment));
                     LLU.Reset (Buffer);
                    CM.Message_Type'Output(Buffer'Access, Message_S);
                    ASU.Unbounded_String'Output (Buffer'Access, Client.Nick);
                    ASU.Unbounded_String'Output (Buffer'Access, Comment);

                    CC.Send_To_All(Readers_C, Buffer'Access);
                  end if;

               exception
                  when CC.Client_Collection_Error =>
                     T_IO.Put_Line("IGNORED: Message received from unknown client.");--Exception: triggered by <<PossibleX>>
               end;
            when others => null;--Case is Trivial, but ready for extensions.
         end case;
      end if;
   end loop;
exception
   when Input_Mismatch =>
      T_IO.Put_Line("Error: Wrong Call.");
      T_IO.Put_Line("Correct format is");
      T_IO.Put_Line("... <#Port>");
      LLU.Finalize;
   when Timeout_Exception =>
      Ada.Text_IO.Put_Line ("Timeout. Restart Server to enable communications.");
      LLU.Finalize;

   when Ex:others =>
      Ada.Text_IO.Put_Line ("Excepción imprevista: " &
                            Ada.Exceptions.Exception_Name(Ex) & " en: " &
                            Ada.Exceptions.Exception_Message(Ex));
      LLU.Finalize;

end Chat_Server;
