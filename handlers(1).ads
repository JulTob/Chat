with Lower_Layer_UDP;

package Handlers is
   package LLU renames Lower_Layer_UDP;

   -- Handler para utilizar como parámetro en LLU.Bind en el servidor
   -- Muestra en pantalla la cadena de texto recibida y responde enviando
   --   la cadena "¡Bienvenido!"
   -- Este procedimiento NO debe llamarse explícitamente
   procedure Server_Handler (From    : in     LLU.End_Point_Type;
                             To      : in     LLU.End_Point_Type;
                             P_Buffer: access LLU.Buffer_Type);


   -- Handler para utilizar como parámetro en LLU.Bind en el cliente
   -- Muestra en pantalla la cadena de texto recibida
   -- Este procedimiento NO debe llamarse explícitamente
   procedure Client_Handler (From    : in     LLU.End_Point_Type;
                             To      : in     LLU.End_Point_Type;
                             P_Buffer: access LLU.Buffer_Type);


end Handlers;
