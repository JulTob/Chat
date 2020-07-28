with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Exceptions;

with Lower_Layer_UDP;
with Chat_Control;
with Client_Collections;

procedure Chat_Server is

   package LLU renames Lower_Layer_UDP;
   package T_IO renames Ada.Text_IO;

   package ComL renames Ada.Command_Line;
   Input_Mismatch: exception;

   package ASU renames Ada.Strings.Unbounded;
   subtype UString is Ada.Strings.Unbounded.Unbounded_String;

   package Chat renames Chat_Control;
   package CC  renames Client_Collections;

   Server: Chat.Server_Type;
   Client: Chat.Client_Type;
   Buffer: aliased LLU.Buffer_Type(1024);
   Recived: UString;
   Reply: UString :=ASU.To_Unbounded_String("Welcome!");
   Expired : Boolean;

begin --Chat_Server
   if ComL.Argument_Count /= 1 then
      raise Input_Mismatch;
   else
      Server.Machine := ASU.To_Unbounded_String(ComL.Argument(1));
   end if;


--   Server.Machine:= ASU.To_Unbounded_String(LLU.Get_Host_Name);
--   Dir_IP := AssignIP(Server.Machine);
--   Server_EP := LLU.Build(ASU.To_String(Dir_IP), Server_Port);
--   LLU.Bind (Server_EP);

   -- construye un End_Point en una dirección y puerto concretos
   Server.EP := LLU.Build ("427.0.0.1", 6123);
   -- se ata al End_Point para poder recibir en él
   LLU.Bind (Server.EP);

   --Bucle infinito
   loop
      -- reinicializa (vacía) el buffer para ahora recibir en él
   	LLU.Reset(Buffer);
      --Escucha
   	LLU.Receive(Server.EP, Buffer'Access, 1000.0, Expired);

   	if Expired then
   		Ada.Text_IO.Put_Line ("Time expired.");
   	else
         --Saca
         Client.Ep := LLU.End_Point_Type'Input (Buffer'Access);

   		Recived := ASU.Unbounded_String'Input(Buffer'Access);
         Ada.Text_IO.Put ("Received: ");
         Ada.Text_IO.Put_Line (ASU.To_String(Recived));

         -- reinicializa (vacía) el buffer
         LLU.Reset (Buffer);

         --  introduce el Unbounded_String en el Buffer
         ASU.Unbounded_String'Output (Buffer'Access, Reply);

         -- envía el contenido del Buffer
         LLU.Send (Client.EP, Buffer'Access);
      end if;
   end loop;

--LLU.Finalize; -- Ponerlo da un warning



exception

   when Input_Mismatch =>
     T_IO.Put_Line("Error: Wrong Call.");
     T_IO.Put_Line("Correct format is");
     T_IO.Put_Line("... <Machine>");
      LLU.Finalize;

   when Ex:others =>
      Ada.Text_IO.Put_Line ("Excepción imprevista: " &
                            Ada.Exceptions.Exception_Name(Ex) &
                            " en: " &
                            Ada.Exceptions.Exception_Message(Ex));
      LLU.Finalize;

end Chat_Server;
