with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;
with Chat_Messages; 
with Handlers;
with Maps_G;
with Ada.Calendar;
with Gnat.Calendar.Time_IO;
with Protected_Ops;

package body Handlers is

	type Datos_C is record
		EP: LLU.End_Point_Type;
		Time: Ada.Calendar.Time;
	end record;
	
	Datos: Datos_C;
	
   package ATIO renames Ada.Text_IO;
   package CM renames Chat_Messages;
   package PO renames Protected_Ops;
   	
   package Maps1 is new Maps_G (Key_Type   => ASU.Unbounded_String,
                               Value_Type => Datos_C,
		                       		Max => Natural'Value(Ada.Command_Line.Argument(2)),
		                       		"="  => ASU."=");
	package Maps2 is new Maps_G (Key_Type   => ASU.Unbounded_String,
					Value_Type => Ada.Calendar.Time,
					Max => 150,
					"="   => ASU."=");
	package ACA renames Ada.Calendar;
   	
   use type CM.Message_Type;
   use type LLU.End_Point_Type;
   use type ASU.Unbounded_String;
	use type ACA.Time;
	

	Dir_IP: ASU.Unbounded_String;
   Client_EP: LLU.End_Point_Type;
   Client_EP_Receive: LLU.End_Point_Type;
   --Client_EP_Handler: LLU.End_Point_Type;
   Buffer: aliased LLU.Buffer_Type(1024);
   Mess: CM.Message_Type;
   Nick: ASU.Unbounded_String;
   Nickname: ASU.Unbounded_String;
   Nick_Older: ASU.Unbounded_String;
   Comentario: ASU.Unbounded_String;
   Acogido: Boolean;
   Maquina: ASU.Unbounded_String;
   Quit: ASU.Unbounded_String := ASU.To_Unbounded_String(".quit");
   Texto: ASU.Unbounded_String;
   Success: Boolean;
   Found: Boolean;
   	
   	Active_Clients: Maps1.Map;	--coleccion clientes activos
   	No_Active_Clients: Maps2.Map;	--coleccion clientes inactivos
   	
   Seq_N: CM.Seq_N_T := CM.Seq_N_T'First; 
	EP_H_Acker: LLU.End_Point_Type; --el que asiente, q envia en ack (end point del server)
	Seq_N_Received: CM.Seq_N_T;
   
   
  -- procedure Delete_Pending_Msgs (Seq_N: in CM.Seq_N_T) is	--borrar mensaje ack
   --begin
   --	Maps1.Get (Active_Clients, Nick, Datos, Success);
   
   
   
  -- end Delete_Pending_Mss;  
    	---------------------------------------------------------
   function Time_Image (T: ACA.Time) return String is
   begin
   	return Gnat.Calendar.Time_IO.Image(T, "%d-%b-%y %T.%i");
   end Time_Image;
   	
   	Hora_Message_Init: ACA.Time;
   	Hora_Message_Writer: ACA.Time;
   	Hora_Message_Logout: ACA.Time;

--====================================================================================  
   procedure Trocear_IP (EP: in LLU.End_Point_Type; L_IP: out ASU.Unbounded_String) is
   	Direction_IP : ASU.Unbounded_String;
   	Longitud_Total: Integer;
   	Long_uno: Integer;
   	Long_Dir: ASU.Unbounded_String;
   	Long_Port: ASU.Unbounded_String; 
   	L1: Integer;
   	Ldir_IP: ASU.Unbounded_String;
   	Lport: ASU.Unbounded_String;
   	
   begin
  		Direction_IP := ASU.To_Unbounded_String(LLU.Image (EP)); --uso client_ep_handler
		Longitud_Total := ASU.Length(Direction_IP);--numero
		Long_uno := ASU.Index(Direction_IP, ",");--numero
		Long_Dir := ASU.Head(Direction_IP, Long_uno-1);--frase hasta ,
		Long_Port := ASU.Tail(Direction_IP, Longitud_Total - Long_uno);	
		L1 := ASU.Index(Long_Dir, ":");--numero
		Lport := ASU.Tail(Long_Port, 4);		--PORT::: Lport
		Ldir_IP := ASU.Tail(Long_Dir, Long_uno - (L1+1));	--Dir IP asu
		L_IP := ASU.To_Unbounded_String(ASU.To_String(Ldir_IP) & ":" & ASU.To_String(Lport));
   
   end Trocear_IP;
--====================================================================================
   procedure Print_Map_A (Active_Clients : in Maps1.Map) is
      	C: Maps1.Cursor := Maps1.First(Active_Clients);	 
   	Nick: ASU.Unbounded_String;
   	Client_EP_ASU: LLU.End_point_Type;
   	L_IP: ASU.Unbounded_STring;
   begin
   		
      while Maps1.Has_Element(C)  loop
      	Client_EP_ASU := Maps1.Element(C).Value.EP;
      	Nick := Maps1.Element(C).Key;

      	Client_EP_ASU := Client_EP_Handler;
      	Trocear_IP(Client_EP_ASU, L_IP);  
         	
         ATIO.Put_Line(ASU.To_String(Nick) & " " & ASU.To_String(L_IP) & ": " & Time_Image(Maps1.Element(C).Value.Time));
         	
         Maps1.Next(C);
      end loop;
      		
   end Print_Map_A;
--====================================================================================
   procedure Print_Map_N (No_Active_Clients : in Maps2.Map) is 
   	C: Maps2.Cursor := Maps2.First(No_Active_Clients);   		
   	Nick: ASU.Unbounded_String;
   begin
   		
      while Maps2.Has_Element(C)  loop	
         Nick := Maps2.Element(C).Key;
         ATIO.Put_Line(ASU.To_String(Nick) & ": " & Time_Image(Maps2.Element(C).Value));
         Maps2.Next(C);	
      end loop;
      		
   end Print_Map_N;
--====================================================================================
   procedure Print_Map (A : in ASU.Unbounded_String) is
   begin
   	if ASU.To_String(A) = "l" then
   		Print_Map_A(Active_Clients);
   	elsif ASU.To_String(A) = "o" then
   		Print_Map_N(No_Active_Clients);
   	end if;
   	
   end Print_Map;
--====================================================================================   
   procedure Send_To_All (Active_Clients: in Maps1.Map; --enviar a todos menos al que lo ha mandado
   					Nick: in ASU.Unbounded_String;
   					P_Buffer: access LLU.Buffer_Type) is 
   	C: Maps1.Cursor := Maps1.First(Active_Clients); 
   	Client_EP_A: LLU.End_Point_Type;  --HANDLER 		
   begin
   	while Maps1.Has_Element(C) loop 	--has element =false= lista vacia
   	   	
   		if ASU.To_String(Nick) /= ASU.To_String(Maps1.Element(C).Key) then
   			Client_EP_A := Maps1.Element(C).Value.EP;
   			LLU.Send(Client_EP_A, P_Buffer);	

   		end if;
   		Maps1.Next(C);	
   	end loop;
   
   end Send_To_All;   		
--====================================================================================  
   procedure Comparar_IP_Sinenvio (Active_Clients: in Maps1.Map; 
   				EP: in LLU.End_Point_Type;
   				P_Buffer: access LLU.Buffer_Type;
   				Found: out Boolean) is
	C: Maps1.Cursor := Maps1.First(Active_Clients); 	
   begin
   	Found := False;
   	while Maps1.Has_Element(C) loop	
   		if EP = Maps1.Element(C).Value.EP then
 			Found := True;
   		end if;
   		Maps1.Next(C);		
   	end loop;
   end Comparar_IP_Sinenvio; 		
   
--====================================================================================   
   procedure Enviar (Active_Clients: in Maps1.Map; 
   				P_Buffer: access LLU.Buffer_Type) is 
	C: Maps1.Cursor := Maps1.First(Active_Clients); 
   begin
   	while Maps1.Has_Element(C) loop
   		LLU.Send(Maps1.Element(C).Value.EP, P_Buffer);
   		Maps1.Next(C);
   	end loop;
   
   end Enviar;
--====================================================================================     
   procedure Older_Client (Time_In: in out ACA.Time;
				Name: out ASU.Unbounded_String) is
       C: Maps1.Cursor := Maps1.First(Active_Clients); 
                  				
   begin
       while Maps1.Has_Element(C) loop
       
       	if Time_In > Maps1.Element(C).Value.Time then
             		Time_In := Maps1.Element(C).Value.Time;
                  	Name := Maps1.Element(C).Key;
                  	
              end if;
       	Maps1.Next(C);
                  						
       end loop;
                  				
   end Older_Client;
--==================================================================================================================================================
   procedure Server_Handler (From: in LLU.End_Point_Type; 
   									To: in LLU.End_Point_Type; 
   									P_Buffer: access LLU.Buffer_Type) is
   	
   begin
     		Mess := CM.Message_Type'Input (P_Buffer);
		-------------------------------------------------------------------------------------------------  
		if Mess = CM.Init then
			Client_EP_Receive := LLU.End_Point_Type'Input (P_Buffer);
			Client_EP_Handler := LLU.End_Point_Type'Input (P_Buffer);	
			Nick := ASU.Unbounded_String'Input (P_Buffer);
			LLU.Reset(P_Buffer.all);
			begin
				
			Hora_Message_Init := ACA.Clock;
			Datos.EP := Client_EP_Handler;
			Datos.Time := Hora_Message_Init;	

			Maps1.Get (Active_Clients, Nick, Datos, Success);
   		if not Success then	
     			ATIO.Put_Line ("INIT received from " & ASU.To_String(Nick) & ": ACCEPTED");
     				
     			Maps1.Put (Active_Clients, Nick, Datos);	
     				
     			-----------CONSTRUIR MENSAJE WELCOME------------(aceptado/rechazado)
				Acogido := True; 
				CM.Message_Type'Output(Buffer'Access, CM.Welcome);
      		Boolean'Output(Buffer'Access, Acogido);      			
				LLU.Send(Client_EP_Receive, Buffer'Access);
				LLU.Reset(Buffer);   
     			-----------------------------------------------
			
				------CONSTRUIR MENSAJE SERVER---------------
				CM.Message_Type'Output(P_Buffer, CM.Server);
				LLU.End_Point_Type'Output (P_Buffer, Client_EP);
     			Integer'Output (P_Buffer, Seq_N);
				Nickname := ASU.To_Unbounded_String("server");
				ASU.Unbounded_String'Output(P_Buffer, Nickname);
				Comentario := ASU.To_Unbounded_String(ASU.To_String(Nick) & " joins the chat");
				ASU.Unbounded_String'Output(P_Buffer, Comentario); 				
				Send_To_All(Active_Clients, Nick, P_Buffer);	--enviar a todos menos al q lo ha mandado				
				LLU.Reset(P_Buffer.all);
         	-----------------------------------------------
         				
   		else	
     			ATIO.Put_Line ("INIT received from " & ASU.To_String(Nick) & ": IGNORED. Nick already used");
      				
      		-----------CONSTRUIR MENSAJE WELCOME------------(aceptado/rechazado)
				Acogido := False; 
				CM.Message_Type'Output(Buffer'Access, Mess);
      		Boolean'Output(Buffer'Access, Acogido);     			
				LLU.Send(Client_EP_Receive, Buffer'Access);
				LLU.Reset(Buffer);
				-----------------------------------------------
				
   		end if;
								
			exception
            when Maps1.Full_Map =>
            	Nick_Older := Nick;
               --1.buscar el cliente mas antiguo
               Older_Client(Hora_Message_Init, Nick_Older); 
                  				
               Maps1.Get (Active_Clients, Nick_Older, Datos, Success);
                  			
               if Success then
                  				
                  ------CONSTRUIR MENSAJE SERVER----
     					CM.Message_Type'Output(P_Buffer, Mess);
     					LLU.End_Point_Type'Output (P_Buffer, Client_EP);
     					Integer'Output (P_Buffer, Seq_N);
     					Nickname := ASU.To_Unbounded_String("server");
      				ASU.Unbounded_String'Output(P_Buffer, Nickname);
      				Comentario := ASU.To_Unbounded_String(ASU.To_String(Nick_Older) & " banned for being idle too long");
 			     		ASU.Unbounded_String'Output(P_Buffer, Comentario); 
 			     				  
						Enviar(Active_Clients, P_Buffer);
							
						LLU.Reset(P_Buffer.all);
                  -----------------------------------------------
                  					
                  ------CONSTRUIR MENSAJE SERVER----------------
						CM.Message_Type'Output(P_Buffer, CM.Server);
						LLU.End_Point_Type'Output (P_Buffer, Client_EP);
     					Integer'Output (P_Buffer, Seq_N);
						Nickname := ASU.To_Unbounded_String("server");
						ASU.Unbounded_String'Output(P_Buffer, Nickname);
						Comentario := ASU.To_Unbounded_String(ASU.To_String(Nick) & " joins the chat");
						ASU.Unbounded_String'Output(P_Buffer, Comentario); 				
						Send_To_All(Active_Clients, Nick, P_Buffer);	--enviar a todos menos al q lo ha mandado				
						LLU.Reset(P_Buffer.all);
         			-----------------------------------------------
         						
         			-----------CONSTRUIR MENSAJE WELCOME------------(aceptado/rechazado)
						Acogido := True; 
						CM.Message_Type'Output(Buffer'Access, CM.Welcome);
      				Boolean'Output(Buffer'Access, Acogido);    			
						LLU.Send(Client_EP_Receive, Buffer'Access);
						LLU.Reset(Buffer);   
     					-----------------------------------------------
                end if;
               --2.añadir cliente a los inactivos                  				
               Maps2.Put(No_Active_Clients, Nick_Older, Hora_Message_Init);
                  					
               --3.borrar d elo clientes activos a ese cliente antiguo
               Maps1.Delete(Active_Clients, Nick_Older, Success);
                  					
               --4.añadir nuevo cliente
               Maps1.Put(Active_Clients, Nick, Datos);
                  				
         end;
			-------------------------------------------------------------------------------------------------      
		elsif Mess = CM.Writer then 
			Client_EP := LLU.End_Point_Type'Input (P_Buffer);
			Seq_N := Integer'Input (P_Buffer);
			Nick := ASU.Unbounded_String'Input (P_Buffer);
			Comentario := ASU.Unbounded_String'Input (P_Buffer);
			LLU.Reset(P_Buffer.all);
			
			--esta? Get
			--if Success = True then 
			--	if Ultimo+1=Seq_N then 
			------CONSTRUIR MENSAJE ACK--------
			CM.Message_Type'Output(P_Buffer, CM.Ack);
			--EP_H_ACKe
			Integer'Output (P_Buffer, Seq_N);
			--LLU.Send(Client_EP_Receive, Buffer'Access);
			LLU.Reset(Buffer);
			-----------------------------------
			
			Hora_Message_Writer := ACA.Clock;
			Datos.EP := Client_EP_Handler;
			Datos.Time := Hora_Message_Writer;	
			
			Maps1.Get (Active_Clients, Nick, Datos, Success);
         if Success then
         	if Datos.EP = Client_EP then 
                  		
            	ATIO.Put_Line("WRITER received from " & ASU.To_String(Nick) & ": " & ASU.To_String(Comentario));
					Maps1.Put(Active_Clients, Nick, Datos);
					
               ------CONSTRUIR MENSAJE SERVER----
     				CM.Message_Type'Output(P_Buffer, Mess);
     				LLU.End_Point_Type'Output (P_Buffer, Client_EP);
     				Integer'Output (P_Buffer, Seq_N);
      			ASU.Unbounded_String'Output(P_Buffer, Nick);
      			Comentario := ASU.To_Unbounded_String(ASU.To_String(Comentario));
 			     	ASU.Unbounded_String'Output(P_Buffer, Comentario);  			     				  
					Send_To_All(Active_Clients, Nick, P_Buffer);							
					LLU.Reset(P_Buffer.all);
					-----------------------------------------------
					
				end if;
			else 
				ATIO.Put_Line("WRITER received from unknown client. IGNORED ");
         end if;
							
			-------------------------------------------------------------------------------------------------  
      elsif Mess = CM.Logout then
			Client_EP := LLU.End_Point_Type'Input (P_Buffer);
			Seq_N := CM.Seq_N_T'Input (P_Buffer);
			Nick := ASU.Unbounded_String'Input (P_Buffer);
			LLU.Reset(P_Buffer.all);
			
			------CONSTRUIR MENSAJE ACK--------
			CM.Message_Type'Output(P_Buffer, CM.Ack);
			--EP_H_ACKe
			CM.Seq_N_T'Output (P_Buffer, Seq_N);
			--LLU.Send(Client_EP_Receive, Buffer'Access);
			LLU.Reset(Buffer);
			-----------------------------------
			
			Hora_Message_Logout := ACA.Clock;

			Maps2.Put(No_Active_Clients, Nick, Hora_Message_Logout);

			Maps1.Get (Active_Clients, Nick, Datos, Success);
   		if Success then
				ATIO.Put_Line("LOGOUT received from " & ASU.To_String(Nick));
				
      		------CONSTRUIR MENSAJE SERVER----
     			CM.Message_Type'Output(P_Buffer, Mess);
     			LLU.End_Point_Type'Output (P_Buffer, Client_EP);
     			CM.Seq_N_T'Output (P_Buffer, Seq_N);
     			Nickname := ASU.To_Unbounded_String("server");
      		ASU.Unbounded_String'Output(P_Buffer, Nickname);
      		Texto := ASU.To_Unbounded_String(ASU.To_String(Nick) & " leaves the chat");
 			   ASU.Unbounded_String'Output(P_Buffer, Texto); 
 			     	  
   			Comparar_IP_Sinenvio (Active_Clients, Client_EP_Handler, P_Buffer, Found);
   			if Found = True then -- = True
					
   				Maps1.Delete(Active_Clients, Nick, Success);
   				if Success then  					
   					Send_To_All(Active_Clients, Nick, P_Buffer);
   				end if;					
   			end if;
				
   		else
      		ATIO.Put_Line("LOGOUT received from unknown client. IGNORED ");
   		end if;
   			
      end if;
      	
   end Server_Handler;

--==================================================================================================================================================
   procedure Client_Handler (From    : in     LLU.End_Point_Type;
                             To      : in     LLU.End_Point_Type;
                             P_Buffer: access LLU.Buffer_Type) is
     	Nickname: ASU.Unbounded_String;
		Comentario: ASU.Unbounded_String;
		
   begin
		LLU.Reset(P_Buffer.all);
   	Mess := CM.Message_Type'Input(P_Buffer);
	--manda mensaje Ack asintiendolo

--mess /= server
	--if Mess /= CM.Server then
	--if ASU.To_String(Nickname) /= "server" then
		--ATIO.Put_Line (ASU.To_String(Nickname) & ": " & ASU.To_String(Comentario)); 
		   
--mess = server					
   if Mess = CM.Server then
      -- ATIO.Put_Line ("server: " & ASU.To_String(Comentario));  
       Maps1.Get (Active_Clients, Nick, Datos, Success);
   	if Success then
   		Server_EP_Handler := LLU.End_Point_Type'Input (P_Buffer);
   		Seq_N_Received := CM.Seq_N_T'Input (P_Buffer);
   		Nickname := ASU.Unbounded_String'Input(P_Buffer);
   		Comentario := ASU.Unbounded_String'Input(P_Buffer);
			LLU.Reset(P_Buffer.all);
			
			if Seq_N_Received <= Seq_N then 
				------CONSTRUIR MENSAJE ACK--------
				CM.Message_Type'Output(P_Buffer, CM.Ack);
				LLU.End_Point_Type'Output (P_Buffer, EP_H_ACKer);
				CM.Seq_N_T'Output (P_Buffer, Seq_N);
				LLU.Send(Client_EP_Receive, Buffer'Access);
				LLU.Reset(Buffer);
				-----------------------------------
			
				if Seq_N = Seq_N_Received then
					--ATIO.Put_Line ("server: " & ASU.To_String(Comentario));  
					ATIO.Put_Line (ASU.To_String(Nickname) & ": " & ASU.To_String(Comentario)); 
					Seq_N := Seq_N + 1;
				
				end if;
			end if;
		end if;
	--mess = ack
	elsif Mess = CM.Ack then				
		EP_H_ACKer := LLU.End_Point_Type'Input (P_Buffer);
		Seq_N := CM.Seq_N_T'Input (P_Buffer);
			
		PO.P.Timer_Procedure(Mess); --??????????????????????
	end if;  					
   
	--procedure Timed_Retransmission is
		--Current_Time: ART.Time;
		--First_Time_Stablished: Boolean;
		--First_Time: ART.Time;
		--Finish: Boolean;
		--Element: Retransmissions.Retransmission_Times_Element_Type;
		--Value: Retransmissions.Pending_Msgs_Value_Type;
		--Success: Boolean;
		--Retransmission_Time: ART.Time;
	--begin
		--Current_Time := ART.Clock; --hora actual (ada.real time) hasta esta hgora retransmito tod a partir de ahi no 

--		First_Time_Stablished := False;--primera vez establecida

--		Finish := False;
	--	while not Finish loop--q no haya terminado de retransmitir
		--	begin
			--	Element := Retransmissions.RTP.Get_First(Retransmission_Times);--get first almaceno las horas de retransmision,
				---- saca el 1er elemento
				--if Element.Time < Current_Time then--retransmito
					--Retransmissions.RTP.Delete_First(Retransmission_Times);--borras el elemento de la lista     --RTP= Retransmission times packets
					--Retransmissions.PMP.Get(Pending_Msgs, Element.Pending_Msgs_Key, Value, Success);
					--if Success then
						--if Value.Retransmission_Attempts < Max_Retransmission_Attempts then--intentos de retransmision (vuelvo a reenviar el mensaje)
							--case Value.Header_Msg is --cabecera del mensaje 
								--when CM.Writer =>--construyo el writer y lo envio, ponerlo dependiendo de nuestros nmbres y tal
									--CM.Send_Writer(Element.Pending_Msgs_Key.Receiver_EP, --a quien va dirigido
										--Element.Pending_Msgs_Key.Sender_EP, --a quien se lo envia 
										--Element.Pending_Msgs_Key.Seq_N,
										--Value.Nick,
										--Value.Comment);
								--when CM.Logout =>
									--CM.Send_Logout(Element.Pending_Msgs_Key.Receiver_EP,
										--Element.Pending_Msgs_Key.Sender_EP,
										--Element.Pending_Msgs_Key.Seq_N,
										--Value.Nick);
								--when others =>
									--null;
							--end case;
							--Value.Retransmission_Attempts := Value.Retransmission_Attempts + 1;--num de retransmisiones mas 1 
							--Retransmissions.PMP.Put(Pending_Msgs, Element.Pending_Msgs_Key, Value);--ya exite la clave, actualiza el valor
							--Retransmission_Time := ART.Clock + ART.To_Time_Span(Retransmission_Period);
							--if not First_Time_Stablished then--sino he establecido la 1a hora, la establezco
								--First_Time := Retransmission_Time;
							--end if;--construyo un nuebvo elemento para añadirlo en la tabla de retransmissions time
							--Element := Retransmissions.Build_Retransmissions_Times_Element(Retransmission_Time, Element.Pending_Msgs_Key);
							--Retransmissions.RTP.Add(Retransmission_Times, Element);
						--else--si alcanzo el num max de intentos lo borro
							--Retransmissions.PMP.Delete(Pending_Msgs, Element.Pending_Msgs_Key, Success); --PMP=Maps2
						--end if;
					--end if;
				--else--si he alcanzado un tiempo superior al q me he despertado, se vuelve a dormir
						--Finish := True;
				--end if;
			--exception--si la lista esta vacia
				--when Retransmissions.RTP.Empty_List =>
					--Finish := True;
			--end;
		--end loop;
		--if Retransmissions.PMP.Map_Length(Pending_Msgs) /= 0 then--si hay mensajes pendientes de asentir, programo de nuevo al chico q se despierta
			--PO.Program_Timer_Procedure(Timed_Retransmission'Access, First_Time);
		--end if;
	--end Timed_Retransmission;
	
	procedure Manage_Retransmissions is
		Current_Time: ART.Time;
		Key: Retransmissions.Pending_Msgs_Key_Type;
		Value: Retransmissions.Pending_Msgs_Value_Type;
		Element: Retransmissions.Retransmission_Times_Element_Type;
		
	begin
		Key.Sender_EP := Client_EP_Handler;
		Key.Receiver_EP := Server_EP_Handler;
		Key.Seq_N := Comentario;
		
		Value.Header_Msg := Mess;
		Value.Nick := Nickname;
		Value.Comment := Comentario;
		Value.Retransmissions_Attempts := 1;
		--Maps1.Put (Active_Clients, Nickname, Value);
		
		Current_Time := ART.Clock + ART.To_Time_Span (Retransmission_Period);
		
		Element.Time := Current_Time;
		Element.Pending_Msg_Key := Nickname;
		
		--añadir elemento a retransmissions times
		Maps1.Put (Active_Clients, Element, Value);
		
		--subprograma que despierte
	
	end Manage_Retransmissions;
	
   end Client_Handler;

end Handlers;

