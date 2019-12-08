with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Chat_Control;
with Ada.Calendar;
with Gnat.Calendar;
with Gnat.Calendar.Time_IO;

package body Handler is

	use type Ada.Calendar.Time;
	use type ASU.Unbounded_String;
	use type CM.Message_Type;
	use type LLU.End_Point_Type;

		procedure Client_Handler (
					From:	in LLU.End_Point_Type;
			      To:	in LLU.End_Point_Type;
			    	From_Buffer: access LLU.Buffer_Type)
		is
			Message:	 CM.Message_Type;
			Nick:		 ASU.Unbounded_String;
			Broadcast:ASU.Unbounded_String;
		begin
			T_IO.Put(ASCII.LF);
			Message:=CM.Message_Type'Input(From_Buffer);
			Nick:=ASU.Unbounded_String'Input (From_Buffer);
			Broadcast:=ASU.Unbounded_String'Input (From_Buffer);
			T_IO.Put_Line(ASU.To_String(Nick)& ">> " & ASU.To_String(Broadcast));
			T_IO.Put(">> ");
		end Client_Handler;


	function Time_Image (T:in Date.Time) return String is
	begin
		return Gnat.Calendar.Time_IO.Image(T, "%d-%b-%y %T.%i");
	end Time_Image;

	function EP_Image(EP:in LLU.End_Point_Type) return String is
		Aux_Index:Natural;
		IP:ASU.Unbounded_String;
		Port:ASU.Unbounded_String;
		End_Point_Image:ASU.Unbounded_String;
	begin
		End_Point_Image:= ASU.To_Unbounded_String( LLU.Image(EP));
		--LOWER_LAYER.INET.UDP.UNI.ADDRESS IP: 193.147.49.72, Port:  1025
      Aux_Index:=ASU.Index(End_Point_Image,":");
      End_Point_Image:=ASU.Tail (End_Point_Image,  ASU.Length(End_Point_Image)-Aux_Index);-- 193.147.49.72, Port:  1025
		Aux_Index := ASU.Index(End_Point_Image, " ");
		End_Point_Image := ASU.Tail (End_Point_Image, ASU.Length(End_Point_Image)-Aux_Index);--193.147.49.72, Port:  1025

		Aux_Index := ASU.Index(End_Point_Image, ",");

		IP := ASU.Head (End_Point_Image, Aux_Index-1);--193.147.49.72

		Aux_Index := ASU.Index(End_Point_Image, ":");
		Port := ASU.Tail (End_Point_Image, ASU.Length(End_Point_Image)-Aux_Index);--  1025
      Aux_Index:=ASU.Index(Port, " ",Going => Ada.Strings.Backward);
      Port:=ASU.Tail (Port, ASU.Length(Port)-Aux_Index);--1025
		return ASU.To_String(IP & ":" &  Port);
	end EP_Image;

	procedure Print_Actives (M : in MapIn.Map) is
		C: MapIn.Cursor := MapIn.First(M);
	begin
	T_IO.Put_Line ("     Active Clients:");
	while MapIn.Has_Element(C) loop
		T_IO.Put_Line(ASU.To_String(MapIn.Element(C).Key) & " " & EP_Image(MapIn.Element(C).Value.EP)& " " & Time_Image((MapIn.Element(C).Value.H)));
		MapIn.Next(C);
	end loop;
	end Print_Actives;

	procedure Print_Unactives (M : in MapOut.Map) is
		C: MapOut.Cursor := MapOut.First(M);
	begin
		T_IO.Put_Line ("     Inactive Clients:");
		while MapOut.Has_Element(C) loop
			T_IO.Put_Line(ASU.To_String(MapOut.Element(C).Key) & " " &
			Time_Image((MapOut.Element(C).Value)));
			MapOut.Next(C);
		end loop;
	end Print_Unactives;


	procedure Send_To_All (M : in MapIn.Map;
						   Nick: in out ASU.Unbounded_String;
						   Broadcast: in out ASU.Unbounded_String;
						   From_Buffer: access LLU.Buffer_Type) is
		C: MapIn.Cursor := MapIn.First(M);
	begin
	while MapIn.Has_Element(C) loop
		if MapIn.Element(C).Key /= Nick then
			if ASU.To_String(Broadcast) = " joins the chat" or
			   ASU.To_String(Broadcast) = " banned for being idle to long" or
			   ASU.To_String(Broadcast) = " leaves the chat" then
				Broadcast := Nick & Broadcast;
				CM.Message_Type'Output(From_Buffer,CM.Server);
				ASU.Unbounded_String'Output(From_Buffer, ASU.To_Unbounded_String("server"));
				ASU.Unbounded_String'Output(From_Buffer, Broadcast);
				LLU.Send(MapIn.Element(C).Value.EP, From_Buffer);
			else
				CM.Message_Type'Output(From_Buffer,CM.Server);
				ASU.Unbounded_String'Output(From_Buffer, Nick);
				ASU.Unbounded_String'Output(From_Buffer, Broadcast);
				LLU.Send(MapIn.Element(C).Value.EP, From_Buffer);
			end if;
		end if;
		MapIn.Next(C);
	end loop;
	end Send_To_All;

	function The_Oldest(M : in MapIn.Map) return ASU.Unbounded_String is
		C: MapIn.Cursor := MapIn.First(M);
		H:Date.Time;
		Nick:ASU.Unbounded_String;
	begin
		H:=Date.Clock;
		while MapIn.Has_Element(C) loop
			if MapIn.Element(C).Value.H < H then
				H:=MapIn.Element(C).Value.H;
				Nick:=MapIn.Element(C).Key;
			end if;
			MapIn.Next(C);
		end loop;
		return Nick;
	end The_Oldest;

	procedure Server_Handler (From: in LLU.End_Point_Type;
                             To:in LLU.End_Point_Type;
                             From_Buffer: access LLU.Buffer_Type) is

		Message:CM.Message_Type;
		Client_EP_Receive:LLU.End_Point_Type;
		Client_EP_Handler:LLU.End_Point_Type;
		Nick:ASU.Unbounded_String;
		Nick_Inactivo:ASU.Unbounded_String;
		Connection_Data_Aux: Connection_Data;
		Esta:Boolean;
		Success:Boolean;
		Broadcast:ASU.Unbounded_String:= ASU.To_Unbounded_String(" joins the chat");
		H:Date.Time;
	begin
	H:=Date.Clock;
	Message:=CM.Message_Type'Input(From_Buffer);

	case Message is
		when CM.Init=>
			Client_EP_Receive := LLU.End_Point_Type'Input (From_Buffer);
			Client_EP_Handler := LLU.End_Point_Type'Input (From_Buffer);
			Nick:=ASU.Unbounded_String'Input (From_Buffer);
			MapIn.Get(Online_Clients,Nick,Connection_Data_Aux,Esta);
			if not Esta then
				begin
					T_IO.Put_Line(CM.Message_Type'Image(Message)& " recived from " & ASU.To_String(Nick) & ": ACCEPTED");
					MapIn.Put(Online_Clients,Nick,(Client_EP_Handler,H));
					LLU.Reset(From_Buffer.all);
					CM.Message_Type'Output(From_Buffer,CM.Welcome);
					Boolean'Output(From_Buffer,True);
					LLU.Send(Client_EP_Receive, From_Buffer);
					LLU.Reset(From_Buffer.all);
					Send_To_All(Online_Clients,Nick,Broadcast,From_Buffer);
				exception
					when MapIn.Full_Map =>
						Nick_Inactivo := The_Oldest(Online_Clients);
						-- Guardo la ip para luego mandar el mesaje de baneo
						MapIn.Get(Online_Clients,Nick_Inactivo,Connection_Data_Aux,Esta);
						-- lo borro de la lista de activos
						MapIn.Delete(Online_Clients,Nick_Inactivo,Success);
						-- lo meto en la de antiguos
						MapOut.Put(Outline_Clients,Nick_Inactivo,Date.Clock);
						-- meto al que intenta entrar en la de activos
						MapIn.Put(Online_Clients,Nick,(Client_EP_Handler,H));
						--- envio el mensaje de baneo a todos
						LLU.Reset(From_Buffer.all);
						Broadcast:=ASU.To_Unbounded_String(" banned for being idle to long");
						Send_To_All(Online_Clients,Nick_Inactivo,Broadcast,From_Buffer);
						LLU.Send (Connection_Data_Aux.Ep, From_Buffer);
						-- envio el welcome al que intentaba entrar
						MapIn.Get(Online_Clients,Nick,Connection_Data_Aux,Esta);
						LLU.Reset(From_Buffer.all);
						CM.Message_Type'Output(From_Buffer,CM.Welcome);
						Boolean'Output(From_Buffer,True);
						LLU.Send(Client_EP_Receive, From_Buffer);
						--informo de que ha entrado en el chat
						Broadcast:=ASU.To_Unbounded_String(" joins the chat");
						LLU.Reset(From_Buffer.all);
						Send_To_All(Online_Clients,Nick,Broadcast,From_Buffer);
				end;
			else
				T_IO.Put_Line(CM.Message_Type'Image(Message)& " recived from " & ASU.To_String(Nick) & ": IGNORED, nick alredy used");
				LLU.Reset(From_Buffer.all);
				CM.Message_Type'Output(From_Buffer,CM.Welcome);
				Boolean'Output(From_Buffer,False);
				LLU.Send (Client_EP_Receive, From_Buffer);
			end if;
		when CM.Writer=>
			Client_EP_Handler := LLU.End_Point_Type'Input (From_Buffer);
			Nick:=ASU.Unbounded_String'Input (From_Buffer);
			Broadcast:=ASU.Unbounded_String'Input (From_Buffer);
			MapIn.Get(Online_Clients,Nick,Connection_Data_Aux,Esta);
			if Esta and then Connection_Data_Aux.EP = Client_EP_Handler then
				MapIn.Put(Online_Clients,Nick,(Client_EP_Handler,H));
				T_IO.Put_Line(CM.Message_Type'Image(Message)& " recived from " & ASU.To_String(Nick) & ": " & ASU.To_String(Broadcast));
				LLU.Reset(From_Buffer.all);
				Send_To_All(Online_Clients,Nick,Broadcast,From_Buffer);
			else
				T_IO.Put_Line(CM.Message_Type'Image(Message)& " recived from unknown client. IGNORED");
			end if;
		when CM.Logout=>
			Client_EP_Handler := LLU.End_Point_Type'Input (From_Buffer);
			Nick:=ASU.Unbounded_String'Input (From_Buffer);
			MapIn.Get(Online_Clients,Nick,Connection_Data_Aux,Esta);
			if Esta and then Connection_Data_Aux.Ep = Client_EP_Handler then
				T_IO.Put_Line(CM.Message_Type'Image(Message)& " recived from " & ASU.To_String(Nick));
				MapIn.Delete(Online_Clients,Nick,Success);
				MapOut.Put(Outline_Clients,Nick,Connection_Data_Aux.H);
				LLU.Reset(From_Buffer.all);
				Broadcast:=ASU.To_Unbounded_String(" leaves the chat");
				Send_To_All(Online_Clients,Nick,Broadcast,From_Buffer);
			else
				T_IO.Put_Line(CM.Message_Type'Image(Message)& " recived from unknown client. IGNORED");
			end if;
		when others =>
			T_IO.Put_Line("Type of message not found");
	end case;

	end Server_Handler;

end Handler;
