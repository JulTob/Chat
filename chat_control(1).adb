
package body Chat_Control is
   use Ada.Strings.Unbounded;

   function AssignIP(Nick: UString) return UString is
   begin
      return  ASU.To_Unbounded_String( LLU.To_IP( ASU.To_String( Nick ) ) );
   end AssignIP;

   procedure Read ( Buffer: in out LLU.Buffer_Type;
                    Client: in out Client_Type) is
      Message_Read: Message_Type;
      Expired: Boolean;
      Text:    ASU.Unbounded_String;
      Timeout_Exception: exception;
   begin -- Read
      loop
       LLU.Reset(Buffer);
       LLU.Receive (Client.EP, Buffer'Access, 900.0, Expired);
       if Expired then
          raise Timeout_Exception;
       else
         Message_Read := Message_Type'Input(Buffer'Access);
         Client.Nick := ASU.Unbounded_String'Input (Buffer'Access);
         Text := ASU.Unbounded_String'Input (Buffer'Access);
         if Message_Read = Server then
            Ada.Text_IO.Put(ASU.To_String(Client.Nick) & " >> ");
         Ada.Text_IO.Put_Line(ASU.To_String(Text));
         else
          Ada.Text_IO.Put_Line("Message with admin rights.");
         end if;
        end if;
      end loop;
   end Read;

   procedure Write ( Buffer: in out LLU.Buffer_Type;
                     Client: in out Client_Type;
                     Server: in out Server_Type) is
      Text: ASU.Unbounded_String;
      Quit: ASU.Unbounded_String := ASU.To_Unbounded_String (".quit");
      Message:Message_Type:=Writer;
   begin -- Write
      T_IO.New_Line(2);
      T_IO.Put_Line("You logged in, if your Nick is not in use.");
      T_IO.Put_Line("    Write to the chat room: ");
      T_IO.Put_Line("    [Write '.quit' to exit.]");
      T_IO.New_Line(2);
      loop
        T_IO.Put("Message: ");
        Text := ASU.To_Unbounded_String(T_IO.Get_Line);
        if not (Text=Quit) then
          LLU.Reset(Buffer);
          Message_Type'Output(Buffer'Access, Message);
          LLU.End_Point_Type'Output(Buffer'Access, Client.EP);
          ASU.Unbounded_String'Output (Buffer'Access, Text);
               -- envía el contenido del Buffer
          LLU.Send(Server.EP, Buffer'Access);
        end if;
        exit when Text = Quit;
      end loop;
   end Write;

   --   procedure Read (
   --             Buffer: in out LLU.Buffer_Type;
   --             Client: in out Chat.Client_Type
   --              ) is
   --      Message_Read: CM.Message_Type;
   --      Expired: Boolean;
   --      Text: ASU.Unbounded_String;
   --   begin -- Read
   --      loop
   --			  LLU.Reset(Buffer);
   --           LLU.Receive (Client.EP, Buffer'Access, 900.0, Expired);
   --           if Expired then
   --             raise Timeout_Exception;
   --           else
   --	          Message_Read := CM.Message_Type'Input(Buffer'Access);
   --         	 Client.Nick := ASU.Unbounded_String'Input (Buffer'Access);
   --				 Text := ASU.Unbounded_String'Input (Buffer'Access);
   --   			 if Message_Read = CM.Server then
   --               T_IO.Put(ASU.To_String(Client.Nick) & ": ");
   --					T_IO.Put_Line(ASU.To_String(Text));
   --				 else
   --					T_IO.Put_Line("Message with admin rights.");
   --				 end if;
   --				end if;
   --         end loop;
   --   end Read;

   --   procedure Write ( Buffer: in out LLU.Buffer_Type;
   --                     Client: in out Chat.Client_Type;
   --                     Server: in out Chat.Server_Type
   --              ) is
   --      Text: ASU.Unbounded_String;
   --      Quit: ASU.Unbounded_String := ASU.To_Unbounded_String (".quit");
   --      Message:CM.Message_Type:=CM.Writer;
   --   begin -- Write
   --      T_IO.New_Line(2);
   --      T_IO.Put("Mini Chat 2.0. Welcome :");
   --      T_IO.Put_Line(ASU.To_String(Client.Nick));
   --      T_IO.Put_Line("    [Write '.quit' to exit.]");
   --      T_IO.New_Line(2);
   --
   --      loop
   --				T_IO.Put("Message: ");
   --				Text := ASU.To_Unbounded_String(T_IO.Get_Line);
   --
   --					LLU.Reset(Buffer);
   --					CM.Message_Type'Output(Buffer'Access, Message);
   --					LLU.End_Point_Type'Output(Buffer'Access, Client.EP);
   --					ASU.Unbounded_String'Output (Buffer'Access, Text);
                  -- envía el contenido del Buffer
   --					LLU.Send(Server.EP, Buffer'Access);

   --				exit when Text = Quit;
   --			end loop;
   --   end Write;


end Chat_Control;
