with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Calendar;
with Gnat.Calendar;
with Gnat.Calendar.Time_IO;
with Ada.Command_Line;
with Lower_Layer_UDP;
with Maps_G;
with Chat_Control;

package Handler is
	package LLU  renames Lower_Layer_UDP;
	package T_IO renames Ada.Text_IO;
	package ASU  renames Ada.Strings.Unbounded;
	package ComL renames Ada.Command_Line;
	package Date renames Ada.Calendar;
	package CM 	 renames Chat_Control;

	type Connection_Data is record
   	EP:LLU.End_Point_Type;
		H:Date.Time;
	end record;

	procedure Client_Handler (From: in LLU.End_Point_Type;
                             To:in LLU.End_Point_Type;
                             From_Buffer: access LLU.Buffer_Type);

	package MapIn is new Maps_G (
		Key_Type   => ASU.Unbounded_String,
		Value_Type => Connection_Data,
		"="        => ASU."=",
		Max 		  => Integer'Value(ComL.Argument(2)));
	Online_Clients:MapIn.Map;

	package MapOut is new Maps_G(
		Key_Type		=> ASU.Unbounded_String,
		Value_Type	=> Date.Time,
		"="			=> ASU."=");
	Outline_Clients:MapOut.Map;

	procedure Server_Handler (
		From : in LLU.End_Point_Type;
		To   : in LLU.End_Point_Type;
		From_Buffer: access LLU.Buffer_Type);

	procedure Print_Actives   (M : in MapIn.Map);
	procedure Print_Unactives (M : in MapOut.Map);

end Handler;
