with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Unchecked_Deallocation;
with Ada.IO_Exceptions;
with Lower_Layer_UDP;
with Ada.Calendar;
with Gnat.Calendar;
with Gnat.Calendar.Time_IO;

generic
   
	type Key_Type is private;
	type Value_Type is private;
	with function "=" (K1, K2: Key_Type) return Boolean;
	Max: in Natural := 150;	

package Maps_G is

	type Map is limited private;

	procedure Get (M       : Map;
                  Key     : in  Key_Type;
                  Value   : out Value_Type;
                  Success : out Boolean);

	Full_Map : exception;
	procedure Put (M     : in out Map;
                  Key   : Key_Type;
                  Value : Value_Type);

	procedure Delete(M     : in out Map;
					Key   : in Key_Type;
					Success : out Boolean);

	type Cursor is limited private;

	function Map_Length(M:Map) return Natural; 

	function First (M: Map) return Cursor;

	procedure Next (C: in out Cursor);

  	function Has_Element (C: Cursor) return Boolean;

	type Element_Type is record
		Key:   Key_Type;
		Value: Value_Type;
	 end record;

	No_Element: exception;
   -- Raises No_Element if Has_Element(C) = False;

   function Element (C: Cursor) return Element_Type;


private
	type Cell is record
		Key: Key_Type;
		Value : Value_Type;
		Full : Boolean := False;
	end record;
	--El mas uno es una celda iniciada para que el array siempre tenga un campo a false para que así deje de iterar en los bucles, representa la "nada"
	type Cell_Array is array (1..Max + 1) of Cell;

	type Cell_Array_A is access Cell_Array;

	type Map is record
		P_Array: Cell_Array_A := new Cell_Array;
		Length : Natural := 0;
	end record;

	type Cursor is record
		M: Map;
		Posicion: Natural;
	end record;

end Maps_G;









