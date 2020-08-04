--
--array a listas
--

with Ada.Text_IO;
with Ada.Unchecked_Deallocation;
with Ada.Strings.Unbounded;

package body Hash_Maps_G is


	procedure Free is new Ada.Unchecked_Deallocation (Cell, Cell_A);
--=================================================================================
	procedure Get (M: in out Map; Key: in  Key_Type; Value: out Value_Type; Success: out Boolean) is
		k: Hash_Range := Hash(Key);
		P_Aux : Cell_A := M.P_Array(k);
	begin
									
    		Success := False;
 		
		while not Success and P_Aux /= null loop
			if P_Aux.Key = Key then
				Value := P_Aux.Value;
				Success := True;
			else 
          	P_Aux := P_Aux.Next;            		  	
        	end if;
		end loop;
	
	end Get;   
--=================================================================================
   	procedure Put (M: in out Map; Key: Key_Type; Value: Value_Type) is
   	k: Hash_Range := Hash(Key);
		P_Aux : Cell_A := M.P_Array(k);
		Found : Boolean;      
	begin
		Found := False;
    				
    -- Si ya existe Key, cambiamos su Value
    while not Found and P_Aux /= null loop
    
      	if P_Aux.Key = Key then		
        		P_Aux.Value := Value;
          	Found := True;
        	else 
          	P_Aux := P_Aux.Next;            		  	
        	end if;   		
		end loop;
      			
    -- Si no hemos encontrado Key añadimos al principio
    	if P_Aux = null and Found = False then
      		if M.Length < Max then
      			P_Aux := new Cell'(Key, Value, null);
      			M.Length := M.Length + 1;
      			Found :=  True;
      			
      		else 
      			raise Full_Map;
      		end if;
      end if;
     
    -- Si el array está vacío nada más entrar
    if M.P_Array(k) = null then
    	--if M.Length < Max then
    		M.P_Array(k) := new Cell;
    		M.P_Array(k).Key := Key;
    		M.P_Array(k).Value := Value;
    		M.P_Array(k).Next := null;
    		M.Length := M.Length + 1;
    end if;

	end Put;
--=================================================================================
   procedure Delete (M      : in out Map;
                     Key     : in  Key_Type;
                     Success : out Boolean) is
		k: Hash_Range := Hash(Key);
		P_Aux : Cell_A := M.P_Array(k);
		P_Aux2: Cell_A;
	begin		

		Success := False;
		while P_Aux /= null and Success = False loop
			if P_Aux.Key = Key then
				P_Aux2.Next := P_Aux.Next;
				
				if M.P_Array(k) = P_Aux then 
					M.P_Array(k) := M.P_Array(k).Next;
				end if;
				Free(P_Aux);
				Success := True;
      		M.Length := M.Length - 1;
      	else 
      		P_Aux2 := P_Aux;
				P_Aux := P_Aux.Next;
            Success := False;
     		end if;     			
		end loop;
	
	end Delete;
--=================================================================================
   function Map_Length (M : Map) return Natural is
   begin
   	return M.Length;
   
   end Map_Length;
--=================================================================================
   function First (M: Map) return Cursor is
   	P_Aux3: Cursor;
   begin
   	P_Aux3.M := M;
   	P_Aux3.P_Element := M.P_Array;
   	
   	for i in Hash_Range loop
   		if M.P_Array(i) /= null then
            P_Aux3.Position := i;
         end if;
      end loop;
      
      return P_Aux3;
   
   
--   	if M.Length = 0 then
--   		E := False;
--   	else 
--   		E := True;
--   		if M.P_Array(k).Next = null then
--   			k := 1;
--   		else 
--   			loop
--   				k := k + 1;
--   			exit when M.P_Array(k).Next = null;
--  			end loop;
--   		end if;
   			
--   	end if;
   	
--   	return (M => M, Element_A => k, Exist => E);
   
   end First;
--=================================================================================
   procedure Next (C: in out Cursor) is
   	k: Hash_Range;
   begin
   	if C.P_Element.Next /= null or C.Position = Hash_Range'Last then
         	C.P_Element := C.P_Element.Next;
      elsif C.Position <= Hash_Range'Last then
         	while C.P_Element /= null or C.Position = Hash_Range'Last loop
         		C.Position := C.Position + 1;
         		C.P_Element := C.P_Element(C.Position);
         	end loop;
     	end if;
   
   end Next;
--=================================================================================
   function Has_Element (C: Cursor) return Boolean is
    
   begin
   		if C.P_Element.Next /= null then
         		return True;
         else 
         		return False;
         end if;
      
   end Has_Element;
--=================================================================================
    function Element (C: Cursor) return Element_Type is
   begin
   	if C.P_Element /= null then
         	return (Key   => C.P_Element.Key,
                 	Value => C.P_Element.Value);        
      else
        	raise No_Element;	
      end if;
   
   end Element;
   	
   	
end Hash_Maps_G;
