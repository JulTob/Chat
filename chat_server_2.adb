--gnatmake -I./maps_g_array -I/usr/local/ll/lib chat_server_2.adb
--gnatmake -I./maps_g_dyn   -I/usr/local/ll/lib chat_server_2.adb

with Lower_Layer_UDP;
--with Client_Collections;
with Chat_Control;
with Handler;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions; use Ada.Exceptions;
with Ada.Command_Line;

procedure Chat_Server_2 is
   --Facilities--
--   package CC renames Client_Collections ;
   package LLU renames Lower_Layer_UDP;
      Use type LLU.End_Point_Type;
   package ASU renames Ada.Strings.Unbounded;
      use type ASU.Unbounded_String;
   package T_IO renames Ada.Text_IO;
   package CM renames Chat_Control ;
      Use type CM.Message_Type;
   package ComL renames Ada.Command_Line;
   package Chat renames Chat_Control;
      Use type Chat.Server_Type;
      Use type Chat.Client_Type;
   --Error Calls--
   Input_Mismatch: exception;
   --Variables--
   Server: Chat.Server_Type;
   C: Character;
  --Procedures & Functions--
  procedure Set_Server(Server: in out Chat.Server_Type) is
    Port_Number: Integer;
    Server_IP: ASU.Unbounded_String;
  begin -- Set_Server
    if (ComL.Argument_Count/=2) then
      LLU.Finalize;
      raise Input_Mismatch;
   else
       Port_Number := Natural'Value(ComL.Argument(1));
       Server.Machine := ASU.To_Unbounded_String(LLU.Get_Host_Name);
       Server_IP := ASU.To_Unbounded_String( LLU.To_IP( ASU.To_String( Server.Machine)));
       -- End_Point en una dirección y puerto
       Server.EP := LLU.Build (ASU.To_String(Server_IP), Port_Number);
       -- se ata al End_Point para poder recibir en él
       LLU.Bind (Server.EP, Handler.Server_Handler'Access);
    end if;
  exception
     when others =>
      LLU.Finalize;
      raise Input_Mismatch;
  end Set_Server;

begin --Chat_Server_2
   if (ComL.Argument_Count/=2) then
      LLU.Finalize;
      raise Input_Mismatch;
   end if;
   Set_Server(Server);
   loop -- bucle infinito
     T_IO.Get_Immediate (C);
     case C is
       when 'L'|'l' =>
         Handler.Print_Actives( Handler.Online_Clients);
       when 'O'|'o' =>
         Handler.Print_Unactives( Handler.Outline_Clients);
       when others =>
         T_IO.Put_Line ("Print Clients with key [L]");
         T_IO.Put_Line ("Print past clients with key [O]");
     end case;
   end loop;
exception
   when Input_Mismatch =>
      T_IO.Put_Line("Error: Wrong Call.");
      T_IO.Put_Line( ComL.Command_Name & "Correct format is");
      T_IO.Put_Line("... <#Port> <ClientNumber>");
      LLU.Finalize;
   when Ex:others =>
      T_IO.Put_Line ("Excepción imprevista: " &
                     Ada.Exceptions.Exception_Name(Ex) & " en: " &
                     Ada.Exceptions.Exception_Message(Ex));
      LLU.Finalize;

end Chat_Server_2;
