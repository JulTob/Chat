with Lower_Layer_UDP;
with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Maps_G;
with Ada.Calendar;
with Gnat.Calendar;
with Gnat.Calendar.Time_IO;
with Ada.Command_Line;

package Handler_Client is
	package LLU renames Lower_Layer_UDP;
	package ATI renames Ada.Text_IO;
	package ASU renames Ada.Strings.Unbounded;

	procedure Client_Handler (From: in LLU.End_Point_Type;
                             To:in LLU.End_Point_Type;
                             P_Buffer: access LLU.Buffer_Type);

end Handler_Client;
