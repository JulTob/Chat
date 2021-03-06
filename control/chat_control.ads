with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Exceptions;

with Lower_Layer_UDP;
with Chat_Messages;  
  --  Le veo más sentido a hacer el tipo aquí, pero al ser un requisito de diseño...

package Chat_Control is

 	 package CM renames Chat_Messages;

	 --	type Message_Type is (Init, Writer, Server);  --No queda fuera de contexto

	 package LLU renames Lower_Layer_UDP;

	 -- Comodity for the use of strings:
   package ASU renames Ada.Strings.Unbounded;
   subtype UString is Ada.Strings.Unbounded.Unbounded_String;

   -- Server
   type Server_Type is record
      Machine: UString;
      EP     : LLU.End_Point_Type;
   		end record;

   -- Client
   type Client_Type is record
      Nick: Ustring;
      EP  : LLU.End_Point_Type;
   		end record;

   -- From Nick, get IP
   function AssignIP(Nick: UString) return UString;

   procedure Listen(
	 			Client: in out Client_Type;
        Server: in out Server_Type);


end Chat_Control;
