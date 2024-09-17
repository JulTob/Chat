-- This package is generic, allowing the user to define the types of
-- keys (Key_Type) and values (Value_Type) as well as a custom equality
-- function for comparing keys.
-- The default maximum size of the map is 150.

generic
	type Key_Type is private;
	type Value_Type is private;
	with function "=" (K1, K2: Key_Type) return Boolean;
	Max: in Natural := 150;

package Maps_G is

	-- The actual map (likely a pointer to a list of Cells).
   type Map is limited private;

   -- Retrieves the value associated with the given key.
   -- Raises an exception if the key does not exist.
   procedure Get (M       : Map;
                  Key     : in  Key_Type;
                  Value   : out Value_Type;
                  Success : out Boolean);

   Full_Map : exception;

   	-- Inserts or updates the value for the given key.
   	procedure Put (M     : in out Map;
                  Key   : Key_Type;
                  Value : Value_Type);

	-- Removes the key-value pair from the map if it exists.
	-- Does nothing if the key is not found.
   	procedure Delete (M      : in out Map;
                     Key     : in  Key_Type;
                     Success : out Boolean);

	procedure Remove (M : in out Map; Key : in Key_Type);

   	function Map_Length (M : Map) return Natural;

   --
   -- Cursor Interface for iterating over Map elements
   --
   type Cursor is limited private;
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

	-- A single entry (node) in the linked list of the map.
   	type Cell;

	-- A pointer to a Cell (node).
   	type Cell_Access is access Cell;

   type Cell is record
      Key   : Key_Type;
      Value : Value_Type;
      Next  : Cell_Access;
   end record;


   type Map is record
      P_First : Cell_Access;
      Length  : Natural := 0;
   end record;

   type Cursor is record
      M         : Map;
      Element_A : Cell_Access;
   end record;

end Maps_G;
