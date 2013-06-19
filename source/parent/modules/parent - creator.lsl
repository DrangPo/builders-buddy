// LSL script generated: parent.modules.parent - creator.lslp Tue Jun 18 20:15:04 Eastern Daylight Time 2013

string ALL_MODULES = "all";
integer BB_API = -11235813;
string MANAGER = "manager";
string TYPE_CHILD = "C";
string TYPE_PARENT = "P";
integer TRACE = 0;
integer DEBUG = 1;
integer INFO = 2;
integer WARNING = 3;
integer ERROR = 4;
integer DEBUG_LEVEL = TRACE;
string msg_command;
list msg_details;
string msg_module;
list values = [];
list vars = [];
string MENU_TYPE_ADMIN = "A";
string MENU_TYPE_EVERYONE = "E";
string MENU_TYPE_NONE = "X";
string VAR_MOD_EVENTS = "mod_events";
string VAR_MOD_MENU_DESC = "mod_menu_desc";
string VAR_MOD_MENU_TYPE = "mod_menu_type";
string VAR_MOD_NAME = "mod_name";
string VAR_MOD_TYPE = "mod_type";
string module = "";

//==============================================================================
// DO NOT EDIT ANYTHING BELOW THIS LINE!!!
//==============================================================================

//==============================================================================
//Creator Variables
//==============================================================================
string menu_action = "";
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
//Storage Functions
//==============================================================================

////////////////////
string get(string name,string default_value){
    integer iFound = llListFindList(vars,[name]);
    if ((iFound != (-1))) return llList2String(values,iFound);
    return default_value;
}

////////////////////
list get_list(string varName,list default_list){
    integer iFound = llListFindList(vars,[varName]);
    if ((iFound != (-1))) {
        return llParseStringKeepNulls(llList2String(values,iFound),["|"],[""]);
    }
    return default_list;
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
set_list(string name,list values){
    set(name,llDumpList2String(values,"|"));
}

//==============================================================================
// Utility Functions
//==============================================================================

////////////////////
string get_short_name(string longName){
    (longName = llSHA1String(longName));
    string shortName;
    integer ptr = 0;
    integer strLength = llStringLength(longName);
    string char;
    for ((ptr = 0); (ptr < strLength); (ptr += 2)) {
        integer ord = ((integer)("0x" + llGetSubString(longName,ptr,(ptr + 1))));
        if ((ord <= 0)) {
            (char = "");
        }
        else  if ((ord < 128)) {
            (char = llUnescapeURL(get_url_code(ord)));
        }
        else  if ((ord < 2048)) {
            (char = llUnescapeURL((get_url_code((((ord >> 6) & 31) | 192)) + get_url_code(((ord & 63) | 128)))));
        }
        else  if ((ord < 65536)) {
            (char = llUnescapeURL(((get_url_code((((ord >> 12) & 15) | 224)) + get_url_code((((ord >> 6) & 63) | 128))) + get_url_code(((ord & 63) | 128)))));
        }
        else  {
            (char = llUnescapeURL((((get_url_code((((ord >> 18) & 15) | 240)) + get_url_code((((ord >> 12) & 63) | 128))) + get_url_code((((ord >> 6) & 63) | 128))) + get_url_code(((ord & 63) | 128)))));
        }
        (shortName += char);
    }
    return shortName;
}

////////////////////
string get_url_code(integer b){
    string hexd = "0123456789ABCDEF";
    return (("%" + llGetSubString(hexd,(b >> 4),(b >> 4))) + llGetSubString(hexd,(b & 15),(b & 15)));
}

//==============================================================================
//Manager Core Functions
//==============================================================================

////////////////////
check_name(){
    (module = get_short_name(llGetScriptName()));
    (module = llDumpList2String(llParseStringKeepNulls(module,["|"],[]),""));
    debugl(TRACE,["mod_check_name():",((((("Module: " + llGetScriptName()) + ", short name: ") + module) + ", length: ") + ((string)llStringLength(module)))]);
}

////////////////////
integer handle_message(){
    debugl(TRACE,(["module.core.handle_message()",msg_module,msg_command] + msg_details));
    if ((msg_module == MANAGER)) {
        if ((msg_command == "reset")) {
            llResetScript();
            return TRUE;
        }
        if ((msg_command == "register")) {
            debug(DEBUG,"Registration received");
            return TRUE;
        }
    }
    return FALSE;
}

////////////////////
register(string module_type,string menu_type,list events,string label,string desc){
    (menu_type = llToUpper(menu_type));
    if ((((menu_type != MENU_TYPE_ADMIN) && (menu_type != MENU_TYPE_EVERYONE)) && (menu_type != MENU_TYPE_NONE))) {
        llOwnerSay("mod_register: Invalid menu type specified, please check script.");
        return;
    }
    if (((module_type != TYPE_PARENT) && (module_type != TYPE_CHILD))) {
        llOwnerSay("mod_register: Invalid module type specified, please check script.");
        return;
    }
    list details = [llGetScriptName(),module_type,menu_type,llDumpList2String(events,","),label,desc];
    send_manager("register",details);
}

////////////////////
register_quick(){
    string modType = get(VAR_MOD_TYPE,TYPE_CHILD);
    string modName = get(VAR_MOD_NAME,"SET_MOD_NAME");
    string menuDesc = get(VAR_MOD_MENU_DESC,"(No description)");
    string menuType = get(VAR_MOD_MENU_TYPE,MENU_TYPE_NONE);
    list modEvents = get_list(VAR_MOD_EVENTS,[]);
    register(modType,menuType,modEvents,modName,menuDesc);
}

////////////////////
send_manager(string command,list details){
    send(module,MANAGER,command,details);
}


////////////////////
mod_changed(integer change){
    if ((change & CHANGED_INVENTORY)) check_name();
}

////////////////////
mod_state_entry(){
    debug(DEBUG,"====================");
    debug(DEBUG,"   SCRIPT STARTED   ");
    debug(DEBUG,"====================");
    check_name();
    register_quick();
}

//==============================================================================
// CONFIGURABLE SETTINGS
//==============================================================================
// VAR_MOD_TYPE:
//   Indicates if this module should link to the parent or component scripts.  
//   Set to one of:
//     TYPE_PARENT - Module intended for use in the parent prim
//     TYPE_CHILD - Module intended for use in the child prims;
//==============================================================================
// VAR_MOD_MENU_TYPE:
//   The type of button to be added to the menu.  Set to one of:
//   MENU_TYPE_ADMIN - Button is seen only by administrators/creators
//   MENU_TYPE_EVERYONE - Button is seen by everyone
//   MENU_TYPE_NONE - No button will be shown.     
//==============================================================================
// VAR_MOD_NAME:
//   The name of the module.  If menu_type is set to MOD_MENU_TYPE_ADMIN
//   or MOD_MENU_TYPE_EVERYONE, this will be used as the label on the button.    
//==============================================================================
// VAR_MOD_MENU_DESC:
//   Description of the module. Will be included in the text of the menu when
//   the module's button is display.    
//==============================================================================
// VAR_MOD_EVENTS:
//   Events that this module wishes to review and possibly cancel.  These can
//   only be events that are explicitly available as cancellable in the base or
//   component script.  This should be set as a list using setList();
//==============================================================================
initialize(){
    set(VAR_MOD_TYPE,TYPE_PARENT);
    set(VAR_MOD_NAME,"Creator");
    set(VAR_MOD_MENU_TYPE,MENU_TYPE_ADMIN);
    set(VAR_MOD_MENU_DESC,"Creator-specific commands");
    set_list(VAR_MOD_EVENTS,["record","forget"]);
}

//==============================================================================
//Creator Functions
//==============================================================================

////////////////////
got_menu_reply(){
    debugl(TRACE,["parent_creator.got_menu_reply()",("msg_command: " + msg_command),("msg_details: " + llDumpList2String(msg_details,"|"))]);
    if ((msg_command == "Record")) {
        llOwnerSay("Recording positions...");
        send_manager("record",[llGetPos(),llGetRot(),FALSE]);
        return;
    }
    if ((msg_command == "SimRecord")) {
        send_manager("record",[ZERO_VECTOR,ZERO_ROTATION,TRUE]);
        return;
    }
    if ((msg_command == "Clear")) {
        llOwnerSay("Forgetting positions...");
        send_manager("clear",[]);
        return;
    }
    if ((msg_command == "Sell")) {
        if ((menu_action == "sell")) {
            unregister();
            llOwnerSay("Creator script has been removed.");
            llRemoveInventory(llGetScriptName());
        }
        else  {
            show_sell_menu(((key)llList2String(msg_details,1)));
        }
        return;
    }
    if ((msg_command == "Cancel")) {
        (menu_action = "");
    }
    if ((msg_command == "Identify")) {
        send_manager("send_child",["identify"]);
        return;
    }
    if ((msg_command == "BACK")) {
        string user_key = ((key)llList2Key(msg_details,1));
        send_manager("top_menu",[user_key]);
    }
}

//==============================================================================
// BUILDER'S BUDDY MODULE CODE - DO NOT REMOVE
// This is called when the module has received any standard event.
//==============================================================================
got_message(){
    debugl(TRACE,["creator.got_message()",("msg_command: " + msg_command),("msg_details: " + llDumpList2String(msg_details,"|"))]);
    if ((msg_command == "reset")) {
        llResetScript();
        return;
    }
    if ((msg_command == "request_menu")) {
        string name = llList2String(msg_details,0);
        key user = ((key)llList2String(msg_details,1));
        integer is_full_rights = llList2Integer(msg_details,2);
        show_menu(user,is_full_rights);
        return;
    }
    if ((msg_command == "menu_reply")) {
        (msg_command = llList2String(msg_details,0));
        (msg_details = llList2List(msg_details,1,(-1)));
        got_menu_reply();
        return;
    }
    return;
}

//==============================================================================
//BUILDER'S BUDDY MODULE CODE - DO NOT REMOVE
// This is called when the module has received a cancellable request.  This
// must return TRUE to cancel the event, or FALSE to allow it to continue.
// Unless your module has a specific need to stop the event from happening, this
// should normally return FALSE.
//
//Only cancellable events listed in mod_events will be seen here.
//==============================================================================
integer got_request(){
    debugl(TRACE,["creator.got_request()",("msg_command: " + msg_command),("msg_details: " + llDumpList2String(msg_details,"|"))]);
    return FALSE;
}

//==============================================================================
//BUILDER'S BUDDY MODULE CODE - DO NOT REMOVE
//==============================================================================
parse_message(){
    debugl(TRACE,["creator.mod_parse_message()",("msg_command: " + msg_command),("msg_details: " + llDumpList2String(msg_details,"|"))]);
    if ((msg_command == "request_event")) {
        (msg_command = llList2String(msg_details,0));
        (msg_details = llList2List(msg_details,1,(-1)));
        integer cancelled = got_request();
        send_manager("request_ack",[msg_command,cancelled]);
    }
    else  {
        got_message();
    }
}


////////////////////
show_menu(key user,integer is_full_rights){
    debug(DEBUG,"Showing menu");
    string text = "";
    list buttons = [];
    (menu_action = "");
    (buttons += ["Record","SimRecord","Clear","Sell","Identify"]);
    (text += (((("Record: Record the position of all parts" + "\nSimRecord: Record region-exact position of parts") + "\nClear: Forgets the position of all parts") + "\nSell: Mark object as ready to sell, allow no more changes") + "\nIdentify: Ask child objects to announce themselves"));
    send_manager("menu",(([user,text] + buttons) + ["BACK"]));
}

////////////////////
show_sell_menu(key user){
    debug(DEBUG,"Showing Sell menu");
    string text = "";
    list buttons = [];
    (menu_action = "sell");
    (buttons += ["Sell","Cancel"]);
    (text += (("WARNING: Pressing \"Sell\" will mark this object for sale, lock existing settings and delete the Creator commands from the menu." + "\n\nTHIS CANNOT BE UNDONE!") + "\n\nAre you sure you want to sell this item?"));
    send_manager("menu",([user,text] + buttons));
}

////////////////////
unregister(){
    send_manager("unregister",[]);
}


////////////////////
////////////////////
////////////////////
default {

	state_entry() {
        initialize();
        mod_state_entry();
    }

	
	changed(integer change) {
        mod_changed(change);
    }

	
	link_message(integer sender_num,integer number,string message,key id) {
        if (parse([module,ALL_MODULES],number,message,id)) {
            if (handle_message()) return;
            parse_message();
        }
    }
}
