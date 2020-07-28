with Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Ada.Text_IO;

package Retransmissions is

	package CM renames Chat_Messages;
	
	use type LLU.End_Point_Type;
	use type CM.Seq_N_T;
	
	Type Pending_Msgs_Key_Type is record
		Sender_EP: LLU.End_Point_Type;
		Receiver_EP: LLU.End_Point_Type;
		Seq_N: CM.Seq_N_T;
	end record;
	
	Type Pending_Msgs_Value_Type is record
		Header_Msg: CM.Message_Type;
		Nick: ASU.Unbounded_String;
		Comment: ASU.Unbounded_String;
		Retransmissions_Attempts: Natural;	
	end record;

	Type Retransmissions_Times_Element_Type is record
		Time: ART.Time;
		Pending_Msgs_Key: Pending_Msgs_Key_Type;
	end record;
	
	package Pending_Msgs_Package is new Lists_Maps_G (Key_Type => Pending_Msgs_Key_Type,
																		Value_Type => Pending_Msgs_Value_Type,
																		=> Are_Pending_Msgs_Keys_Equals);
	package PMP renames Pending_Msgs_Package; 
	
	package Retransmissions_Times_Package is new Ordered_Lists_G (Element_Type => Retransmissions_Times_Element_Type,
																		=> Is_Retransmissions_Times_Element_Bigger);
	package RTP renames Retransmissions_Times_Package; 
	
	function Are_Pending_Msgs_Keys_Equals (K1, K2: Are_Pending_Msgs_Key_Type) return Boolean;
	
	function Is_Retransmissions_Times_Element_Bigger (E1, E2: Retransmissions_Times_Element_Type) return Boolean;
	
	
end Retransmissions;
