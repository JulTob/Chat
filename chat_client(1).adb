--gnatmake -I/usr/local/ll/lib chat_client.adb
--./chat_client <Machine> <Port> <Client's Nick>

with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Exceptions;

with Lower_Layer_UDP;
with Chat_Control;

procedure Chat_Client is

    package T_IO renames Ada.Text_IO;

    --Lower Layer UDP es una libreria aparte (tratamiento caja negra)
    package LLU renames Lower_Layer_UDP;

    --Uso de funciones y tipos para chat y servidor
    package Chat renames Chat_Control;

    --Control Input At Calling
    package ComL renames Ada.Command_Line;
    Input_Mismatch: exception;

    --Comodity for the use of strings:
    package ASU renames Ada.Strings.Unbounded;
    subtype UString is Ada.Strings.Unbounded.Unbounded_String;


    Server: Chat.Server_Type;
    Client: Chat.Client_Type;
    Buffer: aliased LLU.Buffer_Type(1024);
    Message: UString;
begin --Chat_Client

    --Control Input
    if ComL.Argument_Count /= 3 then
        raise Input_Mismatch;
    else
        Server.Machine:=ASU.To_Unbounded_String(ComL.Argument(1));
        Server.Port   :=Positive'Value(ComL.Argument(2));
        Client.Nick   :=ASU.To_Unbounded_String(ComL.Argument(3));
    end if;

    Chat.Conectar(Server,Client);

    --(Re)Set Buffer
    LLU.Reset(Buffer);
    --Introduce Cliente EP para el servidor
    LLU.End_Point_Type'Output(Buffer'Access, Client.EP);

    Message := ASU.To_Unbounded_String(Ada.Text_IO.Get_Line);

    -- introduce el Mensaje en el Buffer
    ASU.Unbounded_String'Output(Buffer'Access, Request);

    -- envía el contenido del Buffer
    LLU.Send(Server.EP, Buffer'Access);

    --Reset (ahora si) el buffer
    LLU.Reset(Buffer)

    -- espera 2.0 segundos a recibir algo dirigido al Client_EP
   --   . si llega antes, los datos recibidos van al Buffer
   --     y Expired queda a False
   --   . si pasados los 2.0 segundos no ha llegado nada,
   --     Expired queda a True
   LLU.Receive(Client_EP, Buffer'Access, 2.0, Expired);
   if Expired then
      Ada.Text_IO.Put_Line ("Plazo expirado");
   else
      -- saca del Buffer un Unbounded_String
      Reply := ASU.Unbounded_String'Input(Buffer'Access);
      Ada.Text_IO.Put("Respuesta: ");
      Ada.Text_IO.Put_Line(ASU.To_String(Reply));
   end if;

    Chat.Lounch_Client_Mode(Client.Nick);

    LLU.Finalize;
exception
    when Input_Mismatch =>
      T_IO.Put_Line("Error: Wrong Call.");
      T_IO.Put_Line("Correct format is");
      T_IO.Put_Line("... <Machine> <Port> <Client's Nick>");
      LLU.Finalize;
   when Ex:others =>
      Ada.Text_IO.Put_Line ("Excepción imprevista: " &
                           Ada.Exceptions.Exception_Name(Ex) &
                           " en: " &
                           Ada.Exceptions.Exception_Message(Ex));
      LLU.Finalize;

end Chat_Client;
