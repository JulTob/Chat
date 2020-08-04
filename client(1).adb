--  {{Ada/Sourceforge|client_1.adb}}

--  <A HREF="http://www.adaic.org/standards/95lrm/html/RM-C-7-1.html">C.7.1 Ada Task Identification</A>
with Ada.Task_Identification;
--  <A HREF="http://www.adaic.org/standards/95lrm/html/RM-11-4-1.html">11.4.1 The Package Exceptions</A>
with Ada.Exceptions;

with CORBA.ORB;
with CORBA.Object;

with Test.Echo;
with Test.Meta_Echo;
with Test.Meta_Echo.Helper;

with PolyORB.Log;
with PolyORB.Setup.Client;
with PolyORB.CORBA_P.Naming_Tools;

--
--  The following packages are only initialized but not used otherwise.
--
pragma Warnings (Off, PolyORB.Setup.Client);

--
--  initialize packages
--
pragma Elaborate_All (PolyORB.Setup.Client);

procedure Client
is

--------------------------------------------------------------------------------

   package ORB   renames CORBA.ORB;
   package MEcho renames Test.Meta_Echo;
   package Echo  renames Test.Echo;

--------------------------------------------------------------------------------

   --
   --  Initialize logging from confiuration file.
   --
   package Log   is new  PolyORB.Log.Facility_Log ("client");

--------------------------------------------------------------------------------

   --
   --  Log Message when Level is at least equal to the user-requested
   --  level for Facility.
   --
   procedure Put_Line (
      Message : in Standard.String;
      Level   : in PolyORB.Log.Log_Level := PolyORB.Log.Notice)
   renames
      Log.Output;

--------------------------------------------------------------------------------

   function Get_Meta_Echo
   return
      MEcho.Ref;

   procedure Run_Test (
      Meta_Echo : MEcho.Ref);

--------------------------------------------------------------------------------

   function Get_Meta_Echo
   return
      MEcho.Ref
   is
      package Naming   renames PolyORB.CORBA_P.Naming_Tools;

      Obj_Ref : CORBA.Object.Ref := Naming.Locate (
         IOR_Or_Name => CORBA.To_Standard_String (MEcho.Name_Service_Id),
         Sep         => '/');

      Retval  : MEcho.Ref  := MEcho.Helper.To_Ref (Obj_Ref);
   begin
      return Retval;
   end Get_Meta_Echo;

--------------------------------------------------------------------------------

   procedure Run_Test (
      Meta_Echo : MEcho.Ref)
   is
      package TaskID renames Ada.Task_Identification;

      Sent_Msg    : CORBA.String;
      Rcvd_Msg    : CORBA.String;
      Echo_Object : Echo.Ref;
   begin
      --  Create echo object
      Put_Line ("create echo object");

      Echo_Object := Test.Meta_Echo.New_Echo (Meta_Echo);

      if Test.Echo.Is_Nil (Echo_Object) then
         Put_Line ("cannot invoke on a nil reference", PolyORB.Log.Error);
      else
         --  Sending message
         Put_Line ("send message");

         Sent_Msg := CORBA.To_CORBA_String (
                        "Hello Task '" &
                        TaskID.Image (TaskID.Current_Task) &
                        "'!");
         Rcvd_Msg := Test.Echo.Echo_String (Echo_Object, Sent_Msg);

         --  Printing result
         Put_Line ("I said : " & CORBA.To_Standard_String (Sent_Msg));
         Put_Line ("The object answered : " & CORBA.To_Standard_String (Rcvd_Msg));
      end if;
   end Run_Test;

--------------------------------------------------------------------------------

begin
   Try :
   declare
      ORB_Id        : ORB.ORBid    := ORB.To_CORBA_String ("ORB");
      ORB_Argumente : ORB.Arg_List := ORB.Command_Line_Arguments;
   begin
      ORB.Init (
         ORB_Indentifier => ORB_Id,
         Argv            => ORB_Argumente);

      Run_Client :
      declare
         Meta_Echo : MEcho.Ref := Get_Meta_Echo;
      begin
         if Test.Meta_Echo.Is_Nil (Meta_Echo) then
            Put_Line ("cannot invoke on a nil meta reference", PolyORB.Log.Error);
         else
            Run_Test (Meta_Echo);
            Run_Test (Meta_Echo);
            Run_Test (Meta_Echo);
         end if;
      end Run_Client;
   end Try;

exception
   when An_Exception : CORBA.Transient =>
      declare
         Member : CORBA.System_Exception_Members;
      begin
         CORBA.Get_Members (
            From => An_Exception,
            To   => Member);
         Put_Line (
            Ada.Exceptions.Exception_Information (An_Exception),
            PolyORB.Log.Error);
         Put_Line (
            "received exception transient, minor" &
            CORBA.Unsigned_Long'Image (Member.Minor) &
            ", completion status: " &
            CORBA.Completion_Status'Image (Member.Completed),
            PolyORB.Log.Error);
      end;
   when An_Exception : others =>
      Put_Line (
            Ada.Exceptions.Exception_Information (An_Exception),
            PolyORB.Log.Error);
end Client;

--------------------------------------------------------------------------------
--  $Log: client.adb,v $
--  Revision 2.2  2005/09/15 17:34:47  krischik
--  paranoia checkin
--
--------------------------------------------------------------------------------
--  vim: textwidth=0 nowrap                             :
--  vim: tabstop=8 shiftwidth=3 softtabstop=3 expandtab :
--  vim: filetype=ada encoding=latin1 fileformat=unix   :
