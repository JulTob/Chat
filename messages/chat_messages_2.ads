with Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Ada.Text_IO;

package Chat_Messages is
   package ASU renames Ada.Strings.Unbounded;
   package LLU renames Lower_Layer_UDP;
   package ATIO renames Ada.Text_IO;
   
	type Message_Type is (Init, Welcome, Writer, Server, Logout, Ack); 
	type Seq_N_T is mod Integer'Last;
	Seq_N: Seq_N_T;
   
end Chat_Messages;
   
   
   
