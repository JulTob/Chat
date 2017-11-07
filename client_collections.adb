with Ada.Text_IO;
with Ada.Unchecked_Deallocation;

package body Client_Collections is

   package T_IO renames Ada.Text_IO;
   use type ASU.Unbounded_String;

   Use type LLU.End_Point_Type;

   procedure Free is new Ada.Unchecked_Deallocation(Cell, Cell_A);

   --Add Node
   Procedure New_Node (First_Pointer: in out Cell_A;
            EP: in LLU.End_Point_Type;
            Nick : in ASU.Unbounded_String) is
      Aux_Pointer: Cell_A;
   begin	--New_Node
      Aux_Pointer:= New Cell;
      Aux_Pointer.Next:=First_Pointer;
      Aux_Pointer.Nick:=Nick;
      Aux_Pointer.Client_EP:=EP;
      First_Pointer:=Aux_Pointer;
   end New_Node;

   function Is_Client (
            Nick: in ASU.Unbounded_String;
            Cell_Access: in Cell_A
   ) return Boolean is
      Aux_Pointer: Cell_A:= Cell_Access;
      Is_It_In: Boolean := False;
   begin -- Check_Client
      if Aux_Pointer=null then
         return False;
      elsif Aux_Pointer.Nick=Nick then
         return True;
      else
         Is_It_In:=Is_Client(Nick, Aux_Pointer.Next);
      end if;
      return Is_It_In;
   end Is_Client;

   procedure Add_Client (
             Collection: in out Collection_Type;
             EP: in LLU.End_Point_Type;
             Nick: in ASU.Unbounded_String;
             Unique: in Boolean ) is

   begin -- Add_Client
      if not Is_Client(Nick,Collection.P_First) then
         New_Node(Collection.P_First,EP,Nick);
         Collection.Total:=Collection.Total+1;
      else
         if Unique then
            raise Client_Collection_Error;
         else
            New_Node(Collection.P_First,EP,ASU.To_Unbounded_String("reader"));
            Collection.Total := Collection.Total + 1;
         end if;
      end if;
   end Add_Client;

   procedure Liberate_Cell (
             Nick: in ASU.Unbounded_String;
             Cell_Access: in out Cell_A ) is
      Aux_Pointer: Cell_A:=Cell_Access;
   begin -- Liberate_Cell
      if not (Cell_Access=null) then
      if Nick=Cell_Access.Nick then
         Cell_Access:=Cell_Access.Next;
         Free(Aux_Pointer);
      else
         Liberate_Cell(Nick,Cell_Access.Next);
      end if;
      end if;
   end Liberate_Cell;

   procedure Delete_Client (
             Collection: in out Collection_Type;
             Nick: in ASU.Unbounded_String ) is

   begin -- Delete_Client
      if Is_Client(Nick,Collection.P_First) then
         Liberate_Cell(Nick,Collection.P_First);
         Collection.Total:=Collection.Total-1;
      else
         raise Client_Collection_Error;
      end if;
   end Delete_Client;

   procedure Send_To_All (Collection: in Collection_Type;
                          P_Buffer: access LLU.Buffer_Type) is
      Cell_Access: Cell_A:= Collection.P_First;
   begin
      while not (Cell_Access=null) loop
         LLU.Send(Cell_Access.Client_EP, P_Buffer);
         Cell_Access:=Cell_Access.Next;
      end loop;
   end Send_To_All;

   function Search_Client (
            Collection: in Collection_Type;
            EP: in LLU.End_Point_Type
   ) return ASU.Unbounded_String is
      Cell_Access: Cell_A:= Collection.P_First;
   begin -- Search_Client
      while not (Cell_Access=null) loop
         if LLU.Image(EP)=LLU.Image(Cell_Access.Client_EP) then
            return Cell_Access.Nick;
         end if;
         Cell_Access:=Cell_Access.Next;
      end loop;
      raise Client_Collection_Error;
   end Search_Client;

   function Cell_Image (
            Cell_Access: in Cell_A
   ) return String is
      End_Point_Image:ASU.Unbounded_String;
      Aux_Index: Integer;
      IP: ASU.Unbounded_String;
      Port: ASU.Unbounded_String;
   begin -- Cell_Image
      End_Point_Image:= ASU.To_Unbounded_String( LLU.Image( Cell_Access.Client_EP)); --LOWER_LAYER.INET.UDP.UNI.ADDRESS IP: 193.147.49.72, Port:  1025
      Aux_Index:=ASU.Index(End_Point_Image,":");
      End_Point_Image:=ASU.Tail (End_Point_Image,  ASU.Length(End_Point_Image)-Aux_Index);-- 193.147.49.72, Port:  1025
		Aux_Index := ASU.Index(End_Point_Image, " ");
		End_Point_Image := ASU.Tail (End_Point_Image, ASU.Length(End_Point_Image)-Aux_Index);--193.147.49.72, Port:  1025

		Aux_Index := ASU.Index(End_Point_Image, ",");

		IP := ASU.Head (End_Point_Image, Aux_Index-1);--193.147.49.72

		Aux_Index := ASU.Index(End_Point_Image, ":");
		Port := ASU.Tail (End_Point_Image, ASU.Length(End_Point_Image)-Aux_Index);--  1025
      Aux_Index:=ASU.Index(Port, " ",Going => Ada.Strings.Backward);
      Port:=ASU.Tail (Port, ASU.Length(Port)-Aux_Index);--1025

		return ASU.To_String(IP & ":" &  Port & " " & Cell_Access.Nick);
   end Cell_Image;

   function Collection_Image (
            Collection: in Collection_Type
   ) return String is
      Out_Text: ASU.Unbounded_String:=ASU.To_Unbounded_String("");
      Cell_Access: Cell_A:= Collection.P_First;
   begin -- Collection_Image
      while not(Cell_Access=null) loop
         Out_Text:= Out_Text & ASCII.LF & ASU.To_Unbounded_String( Cell_Image( Cell_Access));
         Cell_Access:=Cell_Access.Next;
      end loop;
      return ASU.To_String(Out_Text);
   end Collection_Image;

   function Total (
            Collection: in Collection_Type
   ) return Natural is
   begin -- Total
      return Collection.Total;
   end Total;

end Client_Collections;
