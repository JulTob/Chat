with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Chat_Messages;
with Ada.Calendar;
with Gnat.Calendar;
with Gnat.Calendar.Time_IO;

package body Handler_server is

	package CM renames Chat_Messages;

	use type Ada.Calendar.Time;
	use type ASU.Unbounded_String;
	use type CM.Message_Type;
	use type LLU.End_Point_Type;

	function Time_Image (T:in Ada.Calendar.Time) return String is
	begin
		return Gnat.Calendar.Time_IO.Image(T, "%d-%b-%y %T.%i");
	end Time_Image;
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
	function Trocear_Direccion(D_IP_Puerto:in ASU.Unbounded_String) return String is 	
	Posicion:Natural;
	Dir_IP:ASU.Unbounded_String;
	Puerto:ASU.Unbounded_String;
	Dir_Total:ASU.Unbounded_String;
	begin
		Posicion:=ASU.Index(D_IP_Puerto,":" );
		Dir_IP:=ASU.Tail(D_IP_Puerto,ASU.Length(D_IP_Puerto)-Posicion);
		Posicion:=ASU.Index(Dir_IP,",");
		Dir_IP:=ASU.Head(Dir_IP,Posicion-1);
		--Estas tres sentencias sirven para saltarse el espacio que va delante de la dirección ip 
		Posicion:=ASU.Index(Dir_IP," ");
		Dir_IP:=ASU.Tail(Dir_IP,ASU.Length(Dir_IP)-Posicion);				
		--Vuevo a hacer algo parecido para trocear el número del puerto
		Posicion:=ASU.Index(D_IP_Puerto,"," );
		Puerto:=ASU.Tail(D_IP_Puerto,ASU.Length(D_IP_Puerto)-Posicion);
		--Puerto:=(" Port:  51942")
		Posicion:=ASU.Index(Puerto," ");
		Puerto:=ASU.Tail(Puerto,ASU.Length(Puerto)-Posicion);
		--Puerto:=("Port:  51942")							
		Posicion:=ASU.Index(Puerto," ");
		Puerto:=ASU.Tail(Puerto,ASU.Length(Puerto)-(Posicion+1));
		--Puerto:=("51942")
		Dir_Total:= Dir_IP & ":" & Puerto;
		return ASU.To_String(Dir_Total);
	end Trocear_Direccion;

	procedure Print_Map_Activos (M : in Map1.Map) is
		C: Map1.Cursor := Map1.First(M);
	begin
	ATI.Put_Line ("Active Clients");
	ATI.Put_Line ("==============");
	while Map1.Has_Element(C) loop
		ATI.Put_Line(ASU.To_String(Map1.Element(C).Key) & " " &
		Trocear_Direccion(ASU.To_Unbounded_String(LLU.Image(Map1.Element(C).Value.EP)))& " " &
		Time_Image((Map1.Element(C).Value.H)));
		Map1.Next(C);
	end loop;
	end Print_Map_Activos;

	procedure Print_Map_Antiguos (M : in Map2.Map) is
		C: Map2.Cursor := Map2.First(M);
	begin
	ATI.Put_Line ("Old Clients");
	ATI.Put_Line ("===========");
	while Map2.Has_Element(C) loop
		ATI.Put_Line(ASU.To_String(Map2.Element(C).Key) & " " &
		Time_Image((Map2.Element(C).Value)));
		Map2.Next(C);
	end loop;
	end Print_Map_Antiguos;


	procedure Send_To_All (M : in Map1.Map;	
						   Nick: in out ASU.Unbounded_String;
						   Comentario: in out ASU.Unbounded_String;
						   P_Buffer: access LLU.Buffer_Type) is
		C: Map1.Cursor := Map1.First(M);
	begin 	
	while Map1.Has_Element(C) loop
		if Map1.Element(C).Key /= Nick then 
			if ASU.To_String(Comentario) = " joins the chat" or 
			   ASU.To_String(Comentario) = " banned for being idle to long" or
			   ASU.To_String(Comentario) = " leaves the chat" then
				Comentario := Nick & Comentario;
				CM.Message_Type'Output(P_Buffer,CM.Server);
				ASU.Unbounded_String'Output(P_Buffer, ASU.To_Unbounded_String("server"));
				ASU.Unbounded_String'Output(P_Buffer, Comentario);
				LLU.Send(Map1.Element(C).Value.EP, P_Buffer);
			else 
				CM.Message_Type'Output(P_Buffer,CM.Server);
				ASU.Unbounded_String'Output(P_Buffer, Nick);
				ASU.Unbounded_String'Output(P_Buffer, Comentario);
				LLU.Send(Map1.Element(C).Value.EP, P_Buffer);
			end if;
		end if;
		Map1.Next(C);
	end loop;
	end Send_To_All;

	function Mas_Antiguo(M : in Map1.Map) return ASU.Unbounded_String is 
		C: Map1.Cursor := Map1.First(M);
		H:Ada.Calendar.Time;
		Nick:ASU.Unbounded_String;
	begin 	
		H:=Ada.Calendar.Clock;
		while Map1.Has_Element(C) loop
			if Map1.Element(C).Value.H < H then 
				H:=Map1.Element(C).Value.H;
				Nick:=Map1.Element(C).Key;
			end if;
			Map1.Next(C);
		end loop;
		return Nick;
	end Mas_Antiguo;



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	procedure Server_Handler (From: in LLU.End_Point_Type;
                             To:in LLU.End_Point_Type;
                             P_Buffer: access LLU.Buffer_Type) is
	
	Etiqueta:CM.Message_Type;
	Client_EP_Receive:LLU.End_Point_Type;
	Client_EP_Handler:LLU.End_Point_Type;
	Nick:ASU.Unbounded_String;
	Nick_Inactivo:ASU.Unbounded_String;
	Client_Value_Aux: Client_Value;
	Esta:Boolean;
	Success:Boolean;
	Comentario:ASU.Unbounded_String:= ASU.To_Unbounded_String(" joins the chat");
	H:Ada.Calendar.Time;
	begin
	H:=Ada.Calendar.Clock;
	Etiqueta:=CM.Message_Type'Input(P_Buffer);
	
	case Etiqueta is 
		when CM.Init=>  
			Client_EP_Receive := LLU.End_Point_Type'Input (P_Buffer);
			Client_EP_Handler := LLU.End_Point_Type'Input (P_Buffer);
			Nick:=ASU.Unbounded_String'Input (P_Buffer);
			Map1.Get(Clientes_En_Linea,Nick,Client_Value_Aux,Esta);
			if not Esta then 
				begin 
					ATI.Put_Line(CM.Message_Type'Image(Etiqueta)& " recived from " & ASU.To_String(Nick) & ": ACCEPTED");
					Map1.Put(Clientes_En_Linea,Nick,(Client_EP_Handler,H));
					LLU.Reset(P_Buffer.all);
					CM.Message_Type'Output(P_Buffer,CM.Welcome);
					Boolean'Output(P_Buffer,True);
					LLU.Send(Client_EP_Receive, P_Buffer);
					LLU.Reset(P_Buffer.all);
					Send_To_All(Clientes_En_Linea,Nick,Comentario,P_Buffer);
				exception 
					when Map1.Full_Map =>
						Nick_Inactivo := Mas_Antiguo(Clientes_En_Linea);
						-- Guardo la ip para luego mandar el mesaje de baneo
						Map1.Get(Clientes_En_Linea,Nick_Inactivo,Client_Value_Aux,Esta);
						-- lo borro de la lista de activos
						Map1.Delete(Clientes_En_Linea,Nick_Inactivo,Success);
						-- lo meto en la de antiguos
						Map2.Put(Clientes_Antiguos,Nick_Inactivo,Ada.Calendar.Clock);
						-- meto al que intenta entrar en la de activos
						Map1.Put(Clientes_En_Linea,Nick,(Client_EP_Handler,H));
						--- envio el mensaje de baneo a todos
						LLU.Reset(P_Buffer.all);
						Comentario:=ASU.To_Unbounded_String(" banned for being idle to long");
						Send_To_All(Clientes_En_Linea,Nick_Inactivo,Comentario,P_Buffer);
						LLU.Send (Client_Value_Aux.Ep, P_Buffer);
						-- envio el welcome al que intentaba entrar 
						Map1.Get(Clientes_En_Linea,Nick,Client_Value_Aux,Esta);
						LLU.Reset(P_Buffer.all);
						CM.Message_Type'Output(P_Buffer,CM.Welcome);
						Boolean'Output(P_Buffer,True);
						LLU.Send(Client_EP_Receive, P_Buffer);
						--informo de que ha entrado en el chat 
						Comentario:=ASU.To_Unbounded_String(" joins the chat");
						LLU.Reset(P_Buffer.all);
						Send_To_All(Clientes_En_Linea,Nick,Comentario,P_Buffer);		
				end;
			else 
				ATI.Put_Line(CM.Message_Type'Image(Etiqueta)& " recived from " & ASU.To_String(Nick) & ": IGNORED, nick alredy used");
				LLU.Reset(P_Buffer.all);
				CM.Message_Type'Output(P_Buffer,CM.Welcome);
				Boolean'Output(P_Buffer,False);
				LLU.Send (Client_EP_Receive, P_Buffer);
			end if;
		when CM.Writer=>
			Client_EP_Handler := LLU.End_Point_Type'Input (P_Buffer);
			Nick:=ASU.Unbounded_String'Input (P_Buffer);
			Comentario:=ASU.Unbounded_String'Input (P_Buffer);
			Map1.Get(Clientes_En_Linea,Nick,Client_Value_Aux,Esta);
			if Esta and then Client_Value_Aux.EP = Client_EP_Handler then
				Map1.Put(Clientes_En_Linea,Nick,(Client_EP_Handler,H)); 
				ATI.Put_Line(CM.Message_Type'Image(Etiqueta)& " recived from " & ASU.To_String(Nick) & ": " & ASU.To_String(Comentario)); 
				LLU.Reset(P_Buffer.all);
				Send_To_All(Clientes_En_Linea,Nick,Comentario,P_Buffer);
			else 
				ATI.Put_Line(CM.Message_Type'Image(Etiqueta)& " recived from unknown client. IGNORED");	
			end if;
		when CM.Logout=>
			Client_EP_Handler := LLU.End_Point_Type'Input (P_Buffer);
			Nick:=ASU.Unbounded_String'Input (P_Buffer);
			Map1.Get(Clientes_En_Linea,Nick,Client_Value_Aux,Esta);
			if Esta and then Client_Value_Aux.Ep = Client_EP_Handler then
				ATI.Put_Line(CM.Message_Type'Image(Etiqueta)& " recived from " & ASU.To_String(Nick));
				Map1.Delete(Clientes_En_Linea,Nick,Success);
				Map2.Put(Clientes_Antiguos,Nick,Client_Value_Aux.H); 
				LLU.Reset(P_Buffer.all);
				Comentario:=ASU.To_Unbounded_String(" leaves the chat");
				Send_To_All(Clientes_En_Linea,Nick,Comentario,P_Buffer);	
			else 
				ATI.Put_Line(CM.Message_Type'Image(Etiqueta)& " recived from unknown client. IGNORED");	
			end if;
		when others =>
			ATI.Put_Line("Type of message not found");
	end case;
	
	end Server_Handler;

end Handler_Server;
