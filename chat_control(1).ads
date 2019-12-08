with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Lower_Layer_UDP;

package Chat_Control is
   package T_IO renames Ada.Text_IO;
   --Chat Messages  --No queda fuera de contexto
   type Message_Type is (Init, Welcome, Writer, Server, Logout);
   package LLU renames Lower_Layer_UDP;
   --Comodity for the use of strings:
   package ASU renames Ada.Strings.Unbounded;
   subtype UString is Ada.Strings.Unbounded.Unbounded_String;
   --Server
   type Server_Type is record
      Machine: UString;
      EP     : LLU.End_Point_Type;
   end record;
   --Client
   type Client_Type is record
      Nick: Ustring;
      Handly: LLU.End_Point_Type;
      EP  : LLU.End_Point_Type;
   end record;
   --From Nick, get IP
   function AssignIP(Nick: UString) return UString;
   procedure Read (Buffer: in out LLU.Buffer_Type;
                  Client: in out Client_Type);
   procedure Write ( Buffer: in out LLU.Buffer_Type;
                    Client: in out Client_Type;
                    Server: in out Server_Type);
end Chat_Control;
