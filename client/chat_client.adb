--gnatmake -I/usr/local/ll/lib chat_client.adb
--./chat_client <Machine> <Port> <Client's Nick>

with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Exceptions;

with Chat_Control;
with Chat_Messages;
with Lower_Layer_UDP;
with Handler_Client;

Procedure Chat_Client is
    package LLU renames Lower_Layer_UDP;
    package ASU renames Ada.Strings.Unbounded;
    package T_IO renames Ada.Text_IO;
    package CM renames Chat_Messages;
    package ComL renames Ada.Command_Line;

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

    -- Helper function to reset and send buffer
    procedure Send_Buffer(Buffer: in out LLU.Buffer_Type; EP: LLU.End_Point_Type) is
    begin
        LLU.Reset(Buffer);
        LLU.Send(EP, Buffer'Access);
    end Send_Buffer;

    -- Modular Read Procedure
    procedure Read_Procedure is
    begin
        LLU.Receive(Client_EP_Receive, Buffer'Access, 10.0, Expired);
        if Expired then
            T_IO.Put_Line("Timeout or no message received.");
        else
            Etiqueta := CM.Message_Type'Input(Buffer'Access);
            Acogido := Boolean'Input(Buffer'Access);
            if Acogido then
                T_IO.Put_Line("Mini-Chat: Welcome " & ASU.To_String(Nick));
            else
                T_IO.Put_Line("Nick already used, connection rejected.");
            end if;
        end if;
    end Read_Procedure;

    -- Modular Write Procedure
    procedure Write_Procedure is
    begin
        while not Fin_Mensajes loop
            T_IO.Put(">> ");
            Comentario := ASU.To_Unbounded_String(T_IO.Get_Line);
            if ASU.To_String(Comentario) = ".quit" then
                CM.Message_Type'Output(Buffer'Access, CM.Logout);
                ASU.Unbounded_String'Output(Buffer'Access, Nick);
                Send_Buffer(Buffer, Server_EP);
                Fin_Mensajes := True;
            else
                CM.Message_Type'Output(Buffer'Access, CM.Writer);
                ASU.Unbounded_String'Output(Buffer'Access, Nick);
                ASU.Unbounded_String'Output(Buffer'Access, Comentario);
                Send_Buffer(Buffer, Server_EP);
            end if;
        end loop;
    end Write_Procedure;

begin
    -- Input validation
    if ComL.Argument_Count /= 3 or else ComL.Argument(3) = "server" then
        raise Usage_Error;
    else
        Nick := ASU.To_Unbounded_String(ComL.Argument(3));
        Server_EP := LLU.Build(LLU.To_IP(ComL.Argument(1)), Integer'Value(ComL.Argument(2)));
    end if;

    -- Setup the client endpoint with handler and receiving
    LLU.Bind_Any(Client_EP_Handler, Handler_Client.Client_Handler'Access);
    LLU.Bind_Any(Client_EP_Receive);

    -- Initialize and send join message to the server
    CM.Message_Type'Output(Buffer'Access, CM.Init);
    ASU.Unbounded_String'Output(Buffer'Access, Nick);
    Send_Buffer(Buffer, Server_EP);

    -- Read and process server response
    Read_Procedure;

    -- If accepted, proceed to the chat loop
    if Acogido then
        Write_Procedure;
    end if;

    -- Finalize the connection
    LLU.Finalize;

exception
    when Usage_Error =>
        T_IO.Put_Line("Usage Error: Provide <Server IP> <Port> <Nick>.");
        LLU.Finalize;
    when others =>
        T_IO.Put_Line("Unexpected exception: " & Ada.Exceptions.Exception_Name(others) &
                      " - " & Ada.Exceptions.Exception_Message(others));
        LLU.Finalize;
end Chat_Client;
