with Handler_Client;
with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Chat_Messages;
with Ada.Command_Line;

procedure Chat_Client is
    package LLU renames Lower_Layer_UDP;
    package ASU renames Ada.Strings.Unbounded;
    package ATI renames Ada.Text_IO;
    package CM renames Chat_Messages;
    package ACL renames Ada.Command_Line;

    Usage_Error: exception;

    -- Variables
    Server_EP: LLU.End_Point_Type;
    Client_EP_Receive: LLU.End_Point_Type;
    Client_EP_Handler: LLU.End_Point_Type;
    Buffer: aliased LLU.Buffer_Type(1024);
    Nick: ASU.Unbounded_String;
    Comentario: ASU.Unbounded_String;
    Expired: Boolean;
    Acogido: Boolean;
    Fin_Mensajes: Boolean := False;
    Etiqueta: CM.Message_Type;

    -- Helper procedure to reset and send the buffer
    procedure Send_Buffer(Buffer: in out LLU.Buffer_Type; EP: LLU.End_Point_Type) is
    begin
        LLU.Reset(Buffer);
        LLU.Send(EP, Buffer'Access);
    end Send_Buffer;

    -- Read procedure for receiving messages from the server
    procedure Read_Procedure is
    begin
        LLU.Receive(Client_EP_Receive, Buffer'Access, 10.0, Expired);
        if Expired then
            ATI.Put_Line("Timeout: No response from the server.");
        else
            Etiqueta := CM.Message_Type'Input(Buffer'Access);
            Acogido := Boolean'Input(Buffer'Access);
            if Acogido then
                ATI.Put_Line("Mini-Chat: Welcome " & ASU.To_String(Nick));
            else
                ATI.Put_Line("Mini-Chat: Nickname already in use. Connection rejected.");
            end if;
        end if;
    end Read_Procedure;

    -- Write procedure for sending messages to the server
    procedure Write_Procedure is
    begin
        while not Fin_Mensajes loop
            ATI.Put(">> ");
            Comentario := ASU.To_Unbounded_String(ATI.Get_Line);
            if ASU.To_String(Comentario) = ".quit" then
                -- Sending a logout message and exit
                CM.Message_Type'Output(Buffer'Access, CM.Logout);
                ASU.Unbounded_String'Output(Buffer'Access, Nick);
                Send_Buffer(Buffer, Server_EP);
                Fin_Mensajes := True;
            else
                -- Sending a regular chat message
                CM.Message_Type'Output(Buffer'Access, CM.Writer);
                ASU.Unbounded_String'Output(Buffer'Access, Nick);
                ASU.Unbounded_String'Output(Buffer'Access, Comentario);
                Send_Buffer(Buffer, Server_EP);
            end if;
        end loop;
    end Write_Procedure;

begin
    -- Input validation
    if ACL.Argument_Count /= 3 or else ACL.Argument(3) = "server" then
        raise Usage_Error;
    else
        Nick := ASU.To_Unbounded_String(ACL.Argument(3));
        Server_EP := LLU.Build(LLU.To_IP(ACL.Argument(1)), Integer'Value(ACL.Argument(2)));
    end if;

    -- Binding the handler and receive endpoints
    LLU.Bind_Any(Client_EP_Handler, Handler_Client.Client_Handler'Access);
    LLU.Bind_Any(Client_EP_Receive);

    -- Send initialization message to the server
    CM.Message_Type'Output(Buffer'Access, CM.Init);
    ASU.Unbounded_String'Output(Buffer'Access, Nick);
    Send_Buffer(Buffer, Server_EP);

    -- Wait for server response
    Read_Procedure;

    -- If the server accepted, start the chat loop
    if Acogido then
        Write_Procedure;
    end if;

    -- Finalize the connection
    LLU.Finalize;

exception
    when Usage_Error =>
        ATI.Put_Line("Usage: " & ACL.Command_Name & " <Server IP> <Port> <Nick> (Nick should not be 'server')");
        LLU.Finalize;
    when others =>
        Ada.Text_IO.Put_Line("Unexpected error: " &
                             Ada.Exceptions.Exception_Name(others) & " - " &
                             Ada.Exceptions.Exception_Message(others));
        LLU.Finalize;
end Chat_Client;
