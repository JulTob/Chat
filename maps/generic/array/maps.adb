with Ada.Text_IO;

-- This package provides a generic map implementation
-- with support for network interactions via Lower_Layer_UDP.
-- It handles key-value pairs using unbounded strings and provides
-- input/output capabilities for map operations.

package body Maps_G is

	package LLU renames Lower_Layer_UDP;
	package ATI renames Ada.Text_IO;
	package ASU renames Ada.Strings.Unbounded;

	procedure Get (M       : Map;
                   Key     : in  Key_Type;
                   Value   : out Value_Type;
                   Success : out Boolean) is
	begin
		Success:= False;
		for I in 1..M.Length loop
			if M.P_Array(I).Full and then Key = M.P_Array(I).Key then
				Value := M.P_Array(I).Value;
				Success:= True;
			end if;
		end loop;
	end Get;

	procedure Put (M     : in out Map;
                  Key   : Key_Type;
                  Value : Value_Type)is
	Existe:Boolean:=False;
	begin
		for I in 1..M.Length loop
			if M.P_Array(I).Key=Key  then
				M.P_Array(I).Value:=Value;
				M.P_Array(I).Full:=True;
				Existe:=True;
			end if;
		end loop;
		if not Existe then
			if M.Length < Max then
				M.Length:=M.Length+1;
				M.P_Array(M.Length).Key:=Key;
				M.P_Array(M.Length).Value:=Value;
				M.P_Array(M.Length).Full:=True;
			else
				raise Full_Map;
			end if;
		end if;
	end Put;

	procedure Delete(M     : in out Map;
					Key   : in Key_Type;
					Success : out Boolean) is
	begin
		for I in 1..M.Length loop
			if M.P_Array(I).Key=Key then
				M.P_Array(I):=M.P_Array(M.Length);
				M.P_Array(M.Length).Full:=False;
				M.Length:= M.Length -1;
				Success:= True;
			else
				Success:= False;
			end if;
		end loop;
	end Delete;

	function Map_Length (M: Map) return Natural is
	begin
		return M.Length;
	end Map_Length;

	function First (M: Map) return Cursor is
	begin
		 return (M => M, Posicion =>1);
	end First;

	procedure Next (C: in out Cursor) is
	begin
		if C.Posicion <= Max then
			C.Posicion:=C.Posicion +1;
		end if;
	end Next;

	function Element (C: Cursor) return Element_Type is
	begin
		if C.M.P_Array(C.Posicion).Full then
			return (Key   => C.M.P_Array(C.Posicion).Key,
                    Value => C.M.P_Array(C.Posicion).Value);
			else
         		raise No_Element;
     	 end if;
	end Element;

	function Has_Element (C: Cursor) return Boolean is
	begin
		if C.M.P_Array(C.Posicion).Full then
			return True;
		else
			return False;
		end if;
	end Has_Element;


end Maps_G;
