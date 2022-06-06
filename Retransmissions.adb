with Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Ada.Text_IO;

package body Retransmissions is 

	function Are_Pending_Msgs_Keys_Equals (K1, K2: Are_Pending_Msgs_Key_Type) return Boolean is
	begin
		return K1.Sender_EP = K2.Sender_EP and 
			K1.Receiver_EP = K2.Receiver_EP and 
			K1.Seq_N = K2.Seq_N;
			
	end Are_Pending_Msgs_Keys_Equals;
	
	function Is_Retransmissions_Times_Element_Bigger (E1, E2: Retransmissions_Times_Element_Type) return Boolean is
	begin
		return E1.Time > E2.Time;
	
	end Is_Retransmissions_Times_Element_Bigger;
	
	
end Retransmissions;
