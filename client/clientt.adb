with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;

procedure Client is
   package LLU renames Lower_Layer_UDP;
   package ASU renames Ada.Strings.Unbounded;

   Server_EP: LLU.End_Point_Type;
   Client_EP: LLU.End_Point_Type;
   Buffer:    aliased LLU.Buffer_Type(1024);
   Request:   ASU.Unbounded_String;
   Reply:     ASU.Unbounded_String;
   Expired : Boolean;

  begin
   -- Construye el End_Point en el que está atado el servidor
   Server_EP := LLU.Build("127.0.0.1", 6123);

   -- Construye un End_Point libre cualquiera y se ata a él
   LLU.Bind_Any(Client_EP);

   -- reinicializa el buffer para empezar a utilizarlo
   LLU.Reset(Buffer);

   -- introduce el End_Point del cliente en el Buffer
   -- para que el servidor sepa dónde responder
   LLU.End_Point_Type'Output(Buffer'Access, Client_EP);

   Ada.Text_IO.Put("Introduce una cadena caracteres: ");
   Request := ASU.To_Unbounded_String(Ada.Text_IO.Get_Line);

   -- introduce el Unbounded_String en el Buffer
   -- (se coloca detrás del End_Point introducido antes)
   ASU.Unbounded_String'Output(Buffer'Access, Request);
   -- envía el contenido del Buffer
   LLU.Send(Server_EP, Buffer'Access);

   -- reinicializa (vacía) el buffer para ahora recibir en él
   LLU.Reset(Buffer);

   -- espera 2.0 segundos a recibir algo dirigido al Client_EP
   --   . si llega antes, los datos recibidos van al Buffer
   --     y Expired queda a False
   --   . si pasados los 2.0 segundos no ha llegado nada, se abandona la
   --     espera y Expired queda a True
   LLU.Receive(Client_EP, Buffer'Access, 2.0, Expired);
   if Expired then
      Ada.Text_IO.Put_Line ("Plazo expirado");
   else
      -- saca del Buffer un Unbounded_String
      Reply := ASU.Unbounded_String'Input(Buffer'Access);
      Ada.Text_IO.Put("Respuesta: ");
      Ada.Text_IO.Put_Line(ASU.To_String(Reply));
   end if;

   -- termina Lower_Layer_UDP
   LLU.Finalize;

exception
   when Ex:others =>
      Ada.Text_IO.Put_Line ("Excepción imprevista: " &
                            Ada.Exceptions.Exception_Name(Ex) & " en: " &
                            Ada.Exceptions.Exception_Message(Ex));
      LLU.Finalize;

end Client;
