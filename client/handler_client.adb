with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Chat_Messages;
with Ada.Calendar;
with Gnat.Calendar;
with Gnat.Calendar.Time_IO;

package body Handler_Client is

	package CM renames Chat_Messages;

	use type ASU.Unbounded_String;
	use type CM.Message_Type;

	procedure Client_Handler (From: in LLU.End_Point_Type;
                             To:in LLU.End_Point_Type;
                             P_Buffer: access LLU.Buffer_Type) is
	Etiqueta:CM.Message_Type;
	Nick:ASU.Unbounded_String;
	Comentario:ASU.Unbounded_String;
	begin
	ATI.Put(ASCII.LF);
	Etiqueta:=CM.Message_Type'Input(P_Buffer);
	Nick:=ASU.Unbounded_String'Input (P_Buffer);
	Comentario:=ASU.Unbounded_String'Input (P_Buffer);
	ATI.Put_Line(ASU.To_String(Nick)& ": " & ASU.To_String(Comentario));
	ATI.Put(">> ");	
	end Client_Handler;


end Handler_Client;
