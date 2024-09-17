with Lower_Layer_UDP;
with Handler_Server;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;

procedure Chat_Server is
    package LLU renames Lower_Layer_UDP;
    package ASU renames Ada.Strings.Unbounded;
    package ATI renames Ada.Text_IO;
    package ACL renames Ada.Command_Line;

    use type ASU.Unbounded_String;

    -- Exception for incorrect usage
    Usage_Error: exception;

    -- Variables
    Maquina: ASU.Unbounded_String;
    Server_EP: LLU.End_Point_Type;
    C: Character;
    Port: Integer;

begin
    -- Get the server machine's host name and IP
    Maquina := ASU.To_Unbounded_String(LLU.Get_Host_Name);
    
    -- Check for correct argument count
    if ACL.Argument_Count /= 2 then
        raise Usage_Error;
    else
        Port := Integer'Value(ACL.Argument(1));
        Server_EP := LLU.Build(LLU.To_IP(ASU.To_String(Maquina)), Port);
    end if;
    
    -- Bind the server to the endpoint and link it with the handler
    LLU.Bind(Server_EP, Handler_Server.Server_Handler'Access);

    -- Main loop: process commands for viewing active or old clients
    loop
        -- Get user input
        ATI.Get_Immediate(C);

        -- Check the user input and act accordingly
        if C = 'L' or C = 'l' then
            Handler_Server.Print_Map_Activos(Handler_Server.Clientes_En_Linea);
        elsif C = 'O' or C = 'o' then
            Handler_Server.Print_Map_Antiguos(Handler_Server.Clientes_Antiguos);
        else
            Ada.Text_IO.Put_Line("Press 'L' or 'l' to view active clients, 'O' or 'o' to view inactive clients.");
        end if;
    end loop;

exception
    -- Handle incorrect command-line arguments
    when Usage_Error =>
        ATI.Put_Line("Command Error: Use " & ACL.Command_Name & " <Port Number>");
        LLU.Finalize;

    -- Handle any other exceptions and finalize the UDP connection
    when Ex: others =>
        Ada.Text_IO.Put_Line("Unexpected error: " &
                             Ada.Exceptions.Exception_Name(Ex) & " - " &
                             Ada.Exceptions.Exception_Message(Ex));
        LLU.Finalize;

end Chat_Server;
