
with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Exceptions;

with Lower_Layer_UDP;

package Chat_Control is

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
      EP  : LLU.End_Point_Type;
   end record;

   type Message_Type is (Init, Writer, Server, Logout, Collection_Request,  Collection_Data, Ban, Shutdown);

   --From Nick, get IP
   function AssignIP(Nick: UString) return UString;

   procedure Conect ( Server: in out Server_Type; Client: in out Client_Type);

   procedure SetServer (Server: in out Server_Type);

   procedure Lounch_Client_Mode (Nick: UString);


end Chat_Control;
