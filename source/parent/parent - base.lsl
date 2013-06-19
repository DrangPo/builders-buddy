// LSL script generated: parent.parent - base.lslp Tue Jun 18 20:15:04 Eastern Daylight Time 2013
//==============================================================================
// Builders' Buddy 3.0 (Parent Script - Base)
// by Newfie Pendragon, 2006-2013
//==============================================================================
// This script is copyrighted material, and has a few (minor) restrictions.
// For complete details, including a revision history, please see
//  http://wiki.secondlife.com/wiki/Builders_Buddy
//
// The License for this script has changed relative to prior versions; please
//  check the website noted above for details.
//==============================================================================


string ALL_CHILDREN = "all";
string ALL_MODULES = "all";
string BASE = "base";
integer BB_API = -11235813;
string BB_VERSION = "3.0";
string MANAGER = "manager";
list values = [];
list vars = [];
integer TRACE = 0;
integer DEBUG = 1;
integer INFO = 2;
integer WARNING = 3;
integer ERROR = 4;
integer DEBUG_LEVEL = TRACE;
string msg_command;
list msg_details;
string msg_module;
string VAR_BASE_ID = "base_id";
string VAR_BEACON_DELAY = "beacon_delay";
string VAR_BULK_BUILD = "bulk_build";
string VAR_CHANNEL = "channel";
string VAR_CLEAN_BEFORE_REZ = "clean_before_rez";
string VAR_DIE_ON_CLEAN = "die_on_clean";
string VAR_RANDOMIZE_CHANNEL = "randomize_channel";
string VAR_REZ_TIMEOUT = "rez_timeout";
string VAR_TIMER_DELAY = "timer_delay";
string VAR_USE_BEACON = "use_beacon";
integer base_channel;
integer base_handle;
integer child_channel;
integer child_handle;
string listen_base;
integer listen_channel;

//==============================================================================
//Base variables
//==============================================================================
integer beacon_timeout = 0;
integer is_rezzing = FALSE;
vector last_pos;
rotation last_rot;
integer rez_index = 0;
string rez_match = "";
string rez_name = "";
string rez_prefix = "";
string rez_postfix = "";
integer rez_single = FALSE;
integer rez_timeout = 0;
key rez_user = NULL_KEY;//==============================================================================
// CONFIGURABLE SETTINGS
//==============================================================================
// VAR_BASE_ID:
//   Used to identify this base object to child objects.  Child objects will
//   only respond to base objects that match the name set in their child script.
//==============================================================================
// VAR_BEACON_DELAY:
//   How often, in seconds, to announce to the region that this base object
//   exists.
//==============================================================================
// VAR_BULK_BUILD:
//   Rez all prims before attempting to move into position.  Must be set to "Y"
//   or "N".
//==============================================================================
// VAR_CHANNEL
//   General-use channel to listen on.  Newly-created child objects will attempt
//   to find the base object on this channel.  If changing this value, make
//   sure it is a negative number.
//==============================================================================
// VAR_CLEAN_BEFORE_REZ:
//   If set to "Y", will automatically issue a clean command before rezzing new
//   child objects.  Must be set to "Y" or "N".
//==============================================================================
// VAR_DIE_ON_CLEAN:
//   If set to "Y", will make the base object also delete when choosing "clean"
//   from the menu.  Must be set to "Y" or "N".
//==============================================================================
// VAR_RANDOMIZE_CHANNEL:
//   Calculate a random channel number to use when communicating with child
//   objects.  The channel number is randomized when the base object is rezzed
//   or whenever the Base script is reset. Set to one of:
//     "Y" - Randomize channel
//     "N" - Use main channel as defined in VAR_CHANNEL
//==============================================================================
// VAR_REZ_TIMEOUT:
//   How long to wait, in seconds, before assuming rezzing of a child object
//   failed.  If child object has not locked on by this time, the Base object
//   will attempt to rez it again.
//==============================================================================
// VAR_TIMER_DELAY:
//   Amount of time, in floating seconds, between ticks of the timer.  Lower
//   numbers will make things more responsive, but causes higher region lag.
//==============================================================================
initialize(){
    set(VAR_BASE_ID,"bb3_base");
    set(VAR_BEACON_DELAY,"30");
    set(VAR_BULK_BUILD,"Y");
    set(VAR_CHANNEL,"-192567");
    set(VAR_CLEAN_BEFORE_REZ,"Y");
    set(VAR_DIE_ON_CLEAN,"N");
    set(VAR_RANDOMIZE_CHANNEL,"Y");
    set(VAR_REZ_TIMEOUT,"10");
    set(VAR_TIMER_DELAY,"0.25");
}

//==============================================================================
//Storage Functions
//==============================================================================

////////////////////
string get(string name,string default_value){
    integer iFound = llListFindList(vars,[name]);
    if ((iFound != (-1))) return llList2String(values,iFound);
    return default_value;
}

////////////////////
integer is_yes(string var,string default_value){
    return (llToUpper(get(var,default_value)) == "Y");
}

////////////////////
set(string name,string value){
    (name = llToLower(name));
    integer iFound = llListFindList(vars,[name]);
    if ((iFound != (-1))) {
        (values = llListReplaceList(values,[value],iFound,iFound));
    }
    else  {
        (vars += name);
        (values += value);
    }
}
////////////////////
debug(integer level,string text){
    if ((level >= DEBUG_LEVEL)) llOwnerSay(((((("[" + llGetScriptName()) + "]") + get_level_text(level)) + " ") + text));
}

////////////////////
debugl(integer level,list lines){
    debug(level,llDumpList2String(lines,"\n\t"));
}

string get_level_text(integer level){
    if ((level == TRACE)) return "[trace]";
    if ((level == DEBUG)) return "[debug]";
    if ((level == INFO)) return "[info]";
    if ((level == WARNING)) return "[warning]";
    if ((level == ERROR)) return "[error]";
    return "";
}

//==============================================================================
//Communication functions
//==============================================================================

// message: <source>|<target>|<command>
// id: <details...>
////////////////////
integer parse(list targets,integer number,string message,string id){
    if ((number != BB_API)) return FALSE;
    list parts = llParseStringKeepNulls(((string)id),["|"],[]);
    if ((llGetListLength(parts) != 3)) return FALSE;
    integer num_targets = llGetListLength(targets);
    integer i;
    string target = llList2String(parts,1);
    for ((i = 0); (i < num_targets); (i++)) {
        if ((llList2String(targets,i) == target)) {
            (msg_module = llList2String(parts,0));
            (msg_command = llList2String(parts,2));
            (msg_details = llParseStringKeepNulls(message,["|"],[]));
            debugl(TRACE,["common.comm.parse():",msg_module,msg_command,message]);
            return TRUE;
        }
    }
    return FALSE;
}

////////////////////
send(string source,string dest,string command,list details){
    debugl(TRACE,["common.common.send():",("dest: " + dest),("command: " + command),("details: " + llDumpList2String(details,"|"))]);
    llMessageLinked(LINK_THIS,BB_API,llDumpList2String(details,"|"),llDumpList2String([source,dest,command],"|"));
}

//==============================================================================
//Group Rezzer Core Functions
//==============================================================================

////////////////////
list get_group_names(string text,string prefix,string postfix){
    integer end = 0;
    integer start = 1;
    if ((llGetSubString(text,0,0) == prefix)) {
        (end = llSubStringIndex(text,postfix));
        if ((end == (-1))) return [];
    }
    else  {
        return [];
    }
    list groups = llParseStringKeepNulls(llGetSubString(text,start,(end - 1)),[","],[]);
    return groups;
}

////////////////////
integer is_group_match(string prefix,string group,string postfix,string name){
    list group_names = get_group_names(name,prefix,postfix);
    debug(DEBUG,("Groups: " + llDumpList2String(group_names,", ")));
    integer i;
    integer group_count = llGetListLength(group_names);
    for ((i = 0); (i < group_count); (i++)) {
        if ((group == llList2String(group_names,i))) return TRUE;
    }
    return FALSE;
}

//==============================================================================
//Base core functions
//==============================================================================

////////////////////
string generate_base_id(){
    string seed = (((string)llGetKey()) + ((string)llGetUnixTime()));
    return llMD5String(seed,100);
}

////////////////////
integer parse_listen(integer channel,string name,key id,string message){
    debugl(TRACE,["base.core.parse_listen()",("channel: " + ((string)channel)),("name: " + name),("id: " + ((string)id)),("message: " + message)]);
    (listen_channel = channel);
    list parts = llParseStringKeepNulls(message,["|"],[]);
    if ((llGetListLength(parts) < 2)) return FALSE;
    string target_base = llList2String(parts,0);
    if (((target_base != BASE) && (target_base != ((string)llGetKey())))) return FALSE;
    (listen_base = target_base);
    (msg_command = llList2String(parts,1));
    (msg_details = []);
    if ((llGetListLength(parts) > 2)) (msg_details = llList2List(parts,2,(-1)));
    return TRUE;
}

////////////////////
request_event(string event_name,list details){
    send_manager("request_event",([event_name] + details));
}

////////////////////
send_child(string child,string command,list details){
    integer channel;
    if ((child_channel != 0)) {
        (channel = child_channel);
    }
    else  {
        (channel = base_channel);
    }
    if ((channel == 0)) {
        debug(ERROR,"Cannot send message on channel 0");
        return;
    }
    debug(TRACE,((("Sending message to " + child) + " on channel ") + ((string)channel)));
    send_child_channel(child,channel,command,details);
}

////////////////////
send_child_channel(string child,integer channel,string command,list details){
    string text = llDumpList2String(([get(VAR_BASE_ID,""),child,command] + details),"|");
    if ((child == ALL_CHILDREN)) {
        llRegionSay(channel,text);
    }
    else  {
        llRegionSayTo(((key)child),channel,text);
    }
}

////////////////////
send_manager(string command,list details){
    send(BASE,MANAGER,command,details);
}


//==============================================================================
// Base Functions
//==============================================================================

////////////////////
announce_config(string child,integer channel){
    send_child_channel(child,channel,"base_prim",[child_channel,llGetPos(),llGetRot()]);
}

////////////////////
clean_all(key user){
    clean_some(user,"","");
    if (is_yes(VAR_DIE_ON_CLEAN,"N")) {
        request_event("die_on_clean",[user]);
    }
}

////////////////////
clean_some(key user,string type,string match){
    send_child(ALL_CHILDREN,"clean",[type,match]);
}

////////////////////
do_event(string event_name,key event_user,integer event_permitted,list event_details){
    if ((!event_permitted)) return;
    if ((event_name == "die_on_clean")) {
        llDie();
        return;
    }
    if ((event_name == "build")) {
        debug(DEBUG,"Rezzing all objects");
        rez_all(event_user);
        return;
    }
    if ((event_name == "clean")) {
        clean_all(event_user);
        return;
    }
}

////////////////////
move(integer single){
    move_child(ALL_CHILDREN,child_channel,single);
    return;
}

////////////////////
move_child(key id,integer channel,integer single){
    string command = "move";
    if (single) (command = "movesingle");
    (last_pos = llGetPos());
    (last_rot = llGetRot());
    send_child_channel(id,channel,command,[last_pos,last_rot]);
    return;
}

////////////////////
rez_all(key user){
    if (is_yes(VAR_CLEAN_BEFORE_REZ,"N")) clean_all(user);
    rez_some(user,FALSE,"","","");
}

////////////////////
rez_done(){
    move(rez_single);
    send(BASE,ALL_MODULES,"rez_done",[]);
    (rez_timeout = 0);
    (rez_index = 0);
    (is_rezzing = FALSE);
}

////////////////////
rez_object(integer is_rerez){
    debugl(DEBUG,["parent_base.rez_object()",("is_rerez: " + ((string)is_rerez)),("user: " + ((string)rez_user)),("rez_single: " + ((string)rez_single)),("rez_prefix: " + rez_prefix),("rez_match: " + rez_match),("rez_postfix: " + rez_postfix),("rez_name: " + rez_name)]);
    if ((!rez_single)) {
        (rez_name = "");
        integer retry = TRUE;
        while (retry) {
            if ((rez_match != "")) {
                string test = llGetInventoryName(INVENTORY_OBJECT,rez_index);
                debug(DEBUG,("Test object: " + test));
                if (is_group_match(rez_prefix,rez_match,rez_postfix,test)) {
                    debug(DEBUG,"Matched group name");
                    (rez_name = test);
                    (retry = FALSE);
                }
                else  {
                    (--rez_index);
                    if ((rez_index < 0)) (retry = FALSE);
                }
            }
            else  {
                (rez_name = llGetInventoryName(INVENTORY_OBJECT,rez_index));
                (retry = FALSE);
            }
        }
    }
    if ((rez_name != "")) {
        debug(DEBUG,((("Rezzing " + rez_name) + ", retry: ") + ((string)is_rerez)));
        send_manager("rezzing",[rez_name,is_rerez]);
        llRezObject(rez_name,llGetPos(),ZERO_VECTOR,llGetRot(),((integer)get(VAR_CHANNEL,"-1")));
        (rez_timeout = (llGetUnixTime() + ((integer)get(VAR_REZ_TIMEOUT,"5"))));
        (is_rezzing = TRUE);
    }
    else  {
        rez_done();
    }
}

////////////////////
rez_some(key user,integer single,string prefix,string name,string postfix){
    debugl(DEBUG,["parent_base.rez_some()",("single: " + ((string)single)),("prefix: " + prefix),("name: " + name),("postfix: " + postfix)]);
    (rez_user = user);
    (rez_single = single);
    (rez_prefix = "");
    (rez_match = "");
    (rez_postfix = "");
    (rez_name = "");
    if ((!is_yes(VAR_BULK_BUILD,"N"))) {
        start_listening_child();
    }
    if (single) {
        (rez_name = name);
        (rez_index = 0);
    }
    else  {
        (rez_prefix = prefix);
        (rez_match = name);
        (rez_postfix = postfix);
        (rez_index = (llGetInventoryNumber(INVENTORY_OBJECT) - 1));
    }
    rez_object(FALSE);
}

////////////////////
set_channel(){
    (base_channel = ((integer)get(VAR_CHANNEL,"-1000001")));
    debug(DEBUG,("Using configured channel " + ((string)child_channel)));
    (child_channel = 0);
    if (is_yes(VAR_RANDOMIZE_CHANNEL,"N")) {
        integer INT_MAX = 2147483647;
        (child_channel = (llFloor(llFrand(INT_MAX)) * (-1)));
        debug(DEBUG,("Using randomized channel " + ((string)child_channel)));
    }
}

////////////////////
start_listening_child(){
    if ((base_handle == 0)) {
        (base_handle = llListen(base_channel,"",NULL_KEY,""));
    }
    if ((child_handle == 0)) {
        (child_handle = llListen(child_channel,"",NULL_KEY,""));
    }
    send(BASE,ALL_MODULES,"listening_child",[base_channel,child_channel]);
}

////////////////////
stop_listening_child(){
    if ((base_handle != 0)) llListenRemove(base_handle);
    if ((child_handle != 0)) llListenRemove(child_handle);
    (base_handle = 0);
    (child_handle = 0);
    send(BASE,ALL_MODULES,"not_listening_child",[]);
    return;
}

////////////////////
////////////////////
////////////////////
default {

	////////////////////
	state_entry() {
        initialize();
        set_channel();
        if ((get(VAR_BASE_ID,"") == "")) {
            string baseID = generate_base_id();
            set(VAR_BASE_ID,baseID);
        }
        send_manager("base_reset",[]);
        if (is_yes(VAR_USE_BEACON,"N")) {
            (beacon_timeout = 1);
        }
        (last_pos = llGetPos());
        (last_rot = llGetRot());
        llSetTimerEvent(((float)get(VAR_TIMER_DELAY,"0.5")));
        start_listening_child();
        announce_config(ALL_CHILDREN,base_channel);
        llOwnerSay((("Builder's Buddy " + BB_VERSION) + " by Newfie Pendragon - ready!"));
        llOwnerSay(("Memory free: " + ((string)llGetFreeMemory())));
    }


	////////////////////
    link_message(integer sender,integer number,string message,key id) {
        debugl(TRACE,["base.link_message()",("message: " + message),("id: " + ((string)id))]);
        if ((!parse([BASE],number,message,id))) return;
        debugl(TRACE,["base.link_message()",("msg_module: " + msg_module)]);
        if ((msg_module != MANAGER)) return;
        if ((msg_command == "do_event")) {
            string event_name = llList2String(msg_details,0);
            key event_user = ((key)llList2String(msg_details,1));
            integer permitted = llList2Integer(msg_details,2);
            list event_detail = llList2List(msg_details,3,(-1));
            do_event(event_name,event_user,permitted,event_detail);
            return;
        }
        if ((msg_command == "send_child")) {
            string child_command = llList2String(msg_details,0);
            list child_details = llList2List(msg_details,1,(-1));
            send_child(ALL_CHILDREN,child_command,child_details);
            return;
        }
        if ((msg_command == "mod_say")) {
            send_child(ALL_CHILDREN,"mod_say",msg_details);
            return;
        }
        if ((msg_command == "rez")) {
            if ((llGetListLength(msg_details) == 1)) {
                rez_all(llList2Key(msg_details,0));
            }
            else  if ((llGetListLength(msg_details) == 2)) {
                rez_some(llList2Key(msg_details,0),TRUE,"",llList2String(msg_details,1),"");
            }
            else  if ((llGetListLength(msg_details) == 4)) {
                rez_some(llList2Key(msg_details,0),FALSE,llList2String(msg_details,1),llList2String(msg_details,2),llList2String(msg_details,3));
            }
            return;
        }
        if ((msg_command == "clean")) {
            key user = ((key)llList2String(msg_details,0));
            if ((llGetListLength(msg_details) == 1)) {
                clean_all(user);
            }
            else  {
                clean_some(user,llList2String(msg_details,1),llList2String(msg_details,2));
            }
            return;
        }
        if ((msg_command == "move_base")) {
            move(FALSE);
            return;
        }
        if ((msg_command == "reset")) {
            llResetScript();
            return;
        }
        if ((msg_command == "record")) {
            send_child(ALL_CHILDREN,"record",msg_details);
            return;
        }
        if ((msg_command == "clear")) {
            send_child(ALL_CHILDREN,"clear",[]);
            return;
        }
        if ((msg_command == "manager_ready")) {
            llOwnerSay(("Manager module active, memory: " + llList2String(msg_details,0)));
            return;
        }
    }


    //////////    
    listen(integer channel,string name,key id,string message) {
        if (parse_listen(channel,name,id,message)) {
            debug(DEBUG,"Message for base");
            if ((msg_command == "ready_to_pos")) {
                debug(DEBUG,"Child object looking for parent, responding...");
                announce_config(ALL_CHILDREN,channel);
            }
        }
    }


    //////////
    object_rez(key id) {
        debugl(DEBUG,["Object rezzed",("id: " + ((string)id)),("name: " + rez_name)]);
        send(BASE,ALL_MODULES,"rezzed",[id,rez_name]);
        if (is_yes(VAR_BULK_BUILD,"N")) {
            (--rez_index);
            if ((rez_index >= 0)) {
                rez_object(FALSE);
            }
            else  {
                move(FALSE);
                move_child(ALL_CHILDREN,base_channel,FALSE);
                send(BASE,ALL_MODULES,"rez_done",[]);
                (rez_timeout = 0);
                (is_rezzing = FALSE);
                (rez_single = FALSE);
                (rez_name = "");
            }
        }
    }

	
	////////////////////
	on_rez(integer start_param) {
        set_channel();
        if ((child_handle != 0)) {
            stop_listening_child();
            start_listening_child();
        }
    }

		
	////////////////////
	timer() {
        integer the_time = llGetUnixTime();
        if ((beacon_timeout != 0)) {
            if ((the_time >= beacon_timeout)) {
                (beacon_timeout = (the_time + ((integer)get(VAR_BEACON_DELAY,"30.0"))));
                send_child(ALL_CHILDREN,"ping",[]);
            }
        }
        if ((rez_timeout != 0)) {
            if ((the_time >= rez_timeout)) {
                rez_object(TRUE);
            }
        }
        if ((llGetTime() > ((float)get(VAR_TIMER_DELAY,"0.5")))) {
            if (((last_pos != llGetPos()) || (last_rot != llGetRot()))) {
                move(FALSE);
                llResetTime();
            }
        }
    }
}
