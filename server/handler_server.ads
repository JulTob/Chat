with Lower_Layer_UDP;
with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Maps_G;
with Ada.Calendar;
with Gnat.Calendar;
with Gnat.Calendar.Time_IO;
with Ada.Command_Line;

package Handler_Server is
	package LLU renames Lower_Layer_UDP;
	package ATI renames Ada.Text_IO;
	package ASU renames Ada.Strings.Unbounded;
	package ACL renames Ada.Command_Line;

	type Client_Value is record 
   		EP:LLU.End_Point_Type;
		H:Ada.Calendar.Time;
	end record;
	
	package Map1 is new Maps_G (Key_Type   => ASU.Unbounded_String,
                               Value_Type => Client_Value,
                               "="        => ASU."=",
								Max => Integer'Value(ACL.Argument(2)));
	Clientes_En_Linea:Map1.Map;

	package Map2 is new Maps_G(Key_Type=>ASU.Unbounded_String,
								     Value_Type=>Ada.Calendar.Time,
								     "="        => ASU."=");
	Clientes_Antiguos:Map2.Map;

	procedure Server_Handler (From    : in     LLU.End_Point_Type;
                             To      : in     LLU.End_Point_Type;
                             P_Buffer: access LLU.Buffer_Type);

	procedure Print_Map_Activos (M : in Map1.Map);

	procedure Print_Map_Antiguos (M : in Map2.Map);

end Handler_Server;
