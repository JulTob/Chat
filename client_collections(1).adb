with Ada.Text_IO;
package body Client_Collections is

   procedure Add_Client (Collection: in out Collection_Type;
                         EP: in LLU.End_Point_Type;
                         Nick: in ASU.Unbounded_String;
                         Unique: in Boolean) is
      Aux: Cell_A:=Collection.P_First;
   begin -- Add_Client
      if Aux=null then   --Empty, create new cell.
         Aux:= new Cell;
         Aux.Client_EP := EP;
         Aux.Nick := Nick;
         Aux.Next := Collection.P_First;  --Place First
         Collection.P_First := Aux;
         
      elsif Aux.Nick=Nick then
         Unique:= False;
      else
         Add_Client(Collection,EP,Nick,Unique);
         Collection.Total := Collection.Next.Total + 1;
      end if;
end Add_Client;

   procedure Delete_Client (Collection: in out Collection_Type;
             Nick: in ASU.Unbounded_String) is
   begin -- Delete_Client
      null;
   end Delete_Client;

   function Search_Client (
            Collection: in Collection_Type;
            EP: in LLU.End_Point_Type )
   return ASU.Unbounded_String is

   begin -- Search_Client
      null;
   end Search_Client;

   procedure Send_To_All (Collection: in Collection_Type;
             P_Buffer: access LLU.Buffer_Type) is

   begin -- Send_To_All
      null;
   end Send_To_All;

   function Collection_Image (Collection: in Collection_Type)
   return String is

   begin -- Collection_Image
      null;
   end Collection_Image;

end Client_Collections;
