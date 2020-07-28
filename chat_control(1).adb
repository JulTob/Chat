
package body Chat_Control is


   function AssignIP(Nick: UString) return UString is
   begin
      return  ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Nick)));
   end AssignIP;

   procedure Conect(
             Server: in out Server_Type;
             Client: in out Client_Type) is

   begin -- Conectar
      --Construir el End Point del servidor
      --"Build" A Link To
      Server.EP := LLU.Build("212.218.4.2",6003);

      --Contruye EP cualquiera, y lo agarra
      --Bind me to become a Node
      LLU.Bind_Any(Client.EP);
   end Conect;






   procedure Lounch_Client_Mode (Nick: UString) is
      Message: Message_Type;
      Expired: Boolean;
      Request: UString;
      Reply  : UString;
      --Buffer
      Buffer: aliased LLU.Buffer_Type(1024); --Buffer
   begin --Lounch_Client_Mode
      if ASU.To_String(Nick) = "reader" then
         LLU.Reset(Buffer);
         Message := Initial;
         Message_Type'Output(Buffer'Access, Message);
         LLU.End_Point_Type'Output(Buffer'Access, Client.EP);
         ASU.Unbounded_String'Output(Buffer'Access, Client.Nick);
         LLU.Send(Server.EP, Buffer'Access);
         loop
            LLU.Reset(Buffer);
            LLU.Receive(Client.EP, Buffer'Access, 1000.0, Expired);
               if Expired then
                T_IO.Put_Line ("Time expired");
               else
               Message := Message_Type'Input(Buffer'Access);
               Client.Nick := UString'Input(Buffer'Access);
               Reply := UString'Input(Buffer'Access);
               if ASU.To_String(Nick) = "server" then
                  T_IO.Put_Line("server: " &  ASU.To_String(Reply));
               else
                  T_IO.Put_Line(ASU.To_String(Client.Nick) & ": " & ASU.To_String(Reply));
               end if;
            end if;
         end loop;
      else
         LLU.Reset(Buffer);
         Message := Initial;
         Message_Type'Output(Buffer'Access, Message);
         LLU.End_Point_Type'Output(Buffer'Access, Client.EP);
         UString'Output(Buffer'Access, Client.Nick);
         LLU.Send(Server.EP, Buffer'Access);
         while ASU.To_String(Request) /= ".quit" loop
            LLU.Reset(Buffer);
            T_IO.Put("Message: ");
            Request := ASU.To_Unbounded_String(T_IO.Get_Line);
            Message := Writer;
            Message_Type'Output(Buffer'Access, Message);
            LLU.End_Point_Type'Output(Buffer'Access, Client.EP);
            UString'Output(Buffer'Access, Request);
            LLU.Send(Server.EP, Buffer'Access);
         end loop;
      end if;
   end Lounch_Client_Mode;

end Chat_Control;
