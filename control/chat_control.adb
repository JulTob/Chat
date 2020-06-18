package body Chat_Control is

   function AssignIP(Nick: UString) return UString is
			begin
      	return  ASU.To_Unbounded_String( LLU.To_IP( ASU.To_String( Nick ) ) );
   			end AssignIP;

   Procedure Listen(
		 		Client: in out Client_Type;
  	    Server: in out Server_Type) is
      Buffer: aliased LLU.Buffer_Type(1024);
      Message: CM.Message_Type;
   		begin
      	LLU.Reset(Buffer);
      	Message := CM.Init;
      	CM.Message_Type'Output(Buffer'Access, Message);
      	LLU.End_Point_Type'Output(Buffer'Access, Client.EP);
      	ASU.Unbounded_String'Output(Buffer'Access, Client.Nick);
      	LLU.Send(Server.EP, Buffer'Access);
   			end Listen;

	end Chat_Control;
